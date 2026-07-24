import 'package:flutter/material.dart';
import '../../point/models/point_models.dart';
import 'emoticon_product_repository.dart';
import 'emoticon_service.dart';
import 'emoticon_token.dart';

class EmoticonPickerSheet extends StatelessWidget {
  final String uid;
  final ValueChanged<String> onSelect;

  const EmoticonPickerSheet({Key? key, required this.uid, required this.onSelect}) : super(key: key);

  static Future<void> show(BuildContext context, {required String uid, required ValueChanged<String> onSelect}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EmoticonPickerSheet(uid: uid, onSelect: onSelect),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: StreamBuilder<List<String>>(
        stream: EmoticonService.watchPurchasedProductIds(uid),
        builder: (context, purchaseSnapshot) {
          if (purchaseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final ownedIds = purchaseSnapshot.data ?? [];
          if (ownedIds.isEmpty) {
            return const Center(
              child: Text(
                '보유한 이모티콘이 없어요.\n포인트 탭에서 구매해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return FutureBuilder<Map<String, EmoticonProduct>>(
            future: EmoticonProductRepository.fetchProducts(ownedIds),
            builder: (context, productSnapshot) {
              if (!productSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }

              final products = ownedIds
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
          onTap: () => onSelect(EmoticonToken(product.id, item.itemId).toText()),
          child: Image.network(
            item.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
          ),
        );
      },
    );
  }
}