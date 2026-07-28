import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../point/models/point_models.dart';
import 'emoticon_image.dart';
import 'emoticon_product_repository.dart';
import 'emoticon_token.dart';

class EmoticonPickerSheet extends StatelessWidget {
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

  // 🌟 '사용' 상태(isVisible == true)인 이모티콘 팩만, 사용자가 지정한 순서(displayOrder)대로 가져옵니다.
  // (emoticon_tab.dart의 사용/미사용 전환·드래그 순서 변경 결과가 그대로 반영됩니다.)
  Stream<List<String>> _watchVisibleProductIds() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users_emoticon')
        .where('isVisible', isEqualTo: true)
        .orderBy('displayOrder', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
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

              // 🌟 visibleIds 순서(=displayOrder)를 그대로 유지해서 탭 순서에 반영합니다.
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

              return DefaultTabController(
                length: products.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      labelColor: Colors.black,
                      indicatorColor: const Color(0xFFFF8A3D),
                      tabs: products.map((p) => Tab(text: p.name)).toList(),
                    ),
                    Expanded(
                      child: TabBarView(children: products.map(_buildPackGrid).toList()),
                    ),
                  ],
                ),
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
          onTap: () => onSelect(
            EmoticonToken(product.id, item.itemId).toText(),
            item.imageUrl,
          ),
          child: EmoticonImage(imageUrl: item.imageUrl, size: 48),
        );
      },
    );
  }
}
