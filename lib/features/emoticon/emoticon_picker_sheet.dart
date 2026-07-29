import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../point/models/point_models.dart';
import 'emoticon_image.dart';
import 'emoticon_product_repository.dart';
import 'emoticon_token.dart';

class EmoticonPickerSheet extends StatefulWidget {
  final String uid;
  final void Function(String token, String imageUrl) onSelect;

  const EmoticonPickerSheet({Key? key, required this.uid, required this.onSelect}) : super(key: key);

  static Future<void> show(
      BuildContext context, {
        required String uid,
        required void Function(String token, String imageUrl) onSelect,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EmoticonPickerSheet(uid: uid, onSelect: onSelect),
    );
  }

  @override
  State<EmoticonPickerSheet> createState() => _EmoticonPickerSheetState();
}

class _EmoticonPickerSheetState extends State<EmoticonPickerSheet> {
  // 🌟 인덱스가 아니라 productId로 선택 상태를 추적합니다.
  // 드래그로 순서가 바뀌어도 "선택된 팩"은 그대로 유지하기 위해서입니다.
  String? _selectedProductId;

  // 🌟 '사용' 상태(isVisible == true)인 이모티콘 팩만, 사용자가 지정한 순서(displayOrder)대로 가져옵니다.
  Stream<List<String>> _watchVisibleProductIds() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('users_emoticon')
        .where('isVisible', isEqualTo: true)
        .orderBy('displayOrder', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // 🌟 마이페이지(EmoticonTab)와 동일한 방식으로 displayOrder를 일괄 업데이트합니다.
  Future<void> _onReorder(List<EmoticonProduct> products, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final reordered = List<EmoticonProduct>.from(products);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < reordered.length; i++) {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('users_emoticon')
          .doc(reordered[i].id);
      batch.update(ref, {
        'displayOrder': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    // Firestore 스트림이 새 순서로 다시 내려오면서 자동으로 화면이 갱신됩니다.
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: StreamBuilder<List<String>>(
        stream: _watchVisibleProductIds(),
        builder: (context, visibleSnapshot) {
          if (visibleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final visibleIds = visibleSnapshot.data ?? [];
          if (visibleIds.isEmpty) {
            return const Center(
              child: Text(
                '사용 중인 이모티콘이 없어요.\n포인트 탭에서 이모티콘을 사용 처리해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return FutureBuilder<Map<String, EmoticonProduct>>(
            future: EmoticonProductRepository.fetchProducts(visibleIds),
            builder: (context, productSnapshot) {
              if (!productSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }

              // 🌟 visibleIds 순서(=displayOrder)를 그대로 유지
              final products = visibleIds
                  .map((id) => productSnapshot.data![id])
                  .whereType<EmoticonProduct>()
                  .where((p) => p.items.isNotEmpty)
                  .toList();

              if (products.isEmpty) {
                return const Center(
                  child: Text('이모티콘 정보를 불러오지 못했어요.', style: TextStyle(color: Colors.grey)),
                );
              }

              // 선택된 productId가 아직 없거나, 목록에서 사라졌으면 첫 번째로 지정
              if (_selectedProductId == null || !products.any((p) => p.id == _selectedProductId)) {
                _selectedProductId = products.first.id;
              }

              final selectedIndex = products.indexWhere((p) => p.id == _selectedProductId);
              final selectedProduct = products[selectedIndex < 0 ? 0 : selectedIndex];

              return Column(
                children: [
                  // 🌟 가로 드래그로 순서 변경 가능한 탭 스트립
                  SizedBox(
                    height: 44,
                    child: ReorderableListView.builder(
                      scrollDirection: Axis.horizontal,
                      buildDefaultDragHandles: false,
                      itemCount: products.length,
                      onReorder: (oldIndex, newIndex) => _onReorder(products, oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        final p = products[index];
                        final isSelected = p.id == _selectedProductId;

                        return ReorderableDragStartListener(
                          key: ValueKey(p.id),
                          index: index,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedProductId = p.id),
                            child: Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isSelected ? const Color(0xFFFF8A3D) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildPackGrid(selectedProduct)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPackGrid(EmoticonProduct product) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: product.items.length,
      itemBuilder: (context, index) {
        final item = product.items[index];
        return GestureDetector(
          onTap: () => widget.onSelect(
            EmoticonToken(product.id, item.itemId).toText(),
            item.imageUrl,
          ),
          child: EmoticonImage(imageUrl: item.imageUrl, size: 48),
        );
      },
    );
  }
}