import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import 'google_play_billing_service.dart';
import 'point_models.dart';
import 'point_purchase_service.dart';
import 'point_repository.dart';

typedef PointPackagePurchaseHandler =
    Future<void> Function(PointPackage pointPackage);

enum PointShopTab {
  emoticon('이모티콘', '이모티콘 구매'),
  gifticon('기프티콘', '기프티콘 구매'),
  charge('포인트 충전', '포인트 충전');

  const PointShopTab(this.tabLabel, this.pageTitle);

  final String tabLabel;
  final String pageTitle;
}

class PointMainScreen extends StatefulWidget {
  const PointMainScreen({
    super.key,
    required this.userId,
    this.repository,
    this.purchaseService,
    this.billingService,
    this.initialTab = PointShopTab.emoticon,
    this.onPointPackagePurchase,
  });

  final String userId;
  final PointShopRepository? repository;
  final PointPurchaseService? purchaseService;
  final GooglePlayBillingService? billingService;
  final PointShopTab initialTab;
  final PointPackagePurchaseHandler? onPointPackagePurchase;

  @override
  State<PointMainScreen> createState() => _PointMainScreenState();
}

class _PointMainScreenState extends State<PointMainScreen> {
  late final PointShopRepository _repository;
  late final PointPurchaseService _purchaseService;
  late final GooglePlayBillingService _billingService;
  late final StreamSubscription<GooglePlayPurchaseEvent>
  _billingEventSubscription;
  late PointShopTab _selectedTab;
  bool _isPurchasing = false;
  bool _isBillingCatalogLoading = false;
  Set<String> _requestedProductIds = const {};
  Map<String, ProductDetails> _googleProducts = const {};
  String _billingNotice = 'Google Play 상품 정보를 확인하고 있습니다.';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestorePointShopRepository();
    _purchaseService =
        widget.purchaseService ?? FirestorePointPurchaseService();
    _billingService = widget.billingService ?? GooglePlayBillingService();
    _billingEventSubscription = _billingService.events.listen(
      _handleGooglePlayPurchaseEvent,
    );
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _billingEventSubscription.cancel();
    if (widget.billingService == null) {
      _billingService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _selectedTab.pageTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E5E5)),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _PointShopTabBar(
                  selectedTab: _selectedTab,
                  onSelected: (tab) => setState(() => _selectedTab = tab),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildSelectedPage()),
            ],
          ),
          if (_isPurchasing)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedPage() {
    return switch (_selectedTab) {
      PointShopTab.emoticon => _buildEmoticonPage(),
      PointShopTab.gifticon => _buildGifticonPage(),
      PointShopTab.charge => _buildPointChargePage(),
    };
  }

  Widget _buildEmoticonPage() {
    return StreamBuilder<List<EmoticonProduct>>(
      stream: _repository.watchEmoticons(),
      builder: (context, snapshot) {
        return _AsyncContent<List<EmoticonProduct>>(
          snapshot: snapshot,
          emptyMessage: '판매 중인 이모티콘이 없습니다.',
          builder: (emoticons) {
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: emoticons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, index) {
                final emoticon = emoticons[index];
                return _EmoticonThumbnail(
                  emoticon: emoticon,
                  onTap: () => _showEmoticonPackage(emoticon),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGifticonPage() {
    return StreamBuilder<List<GifticonProduct>>(
      stream: _repository.watchGifticons(),
      builder: (context, snapshot) {
        return _AsyncContent<List<GifticonProduct>>(
          snapshot: snapshot,
          emptyMessage: '판매 중인 기프티콘이 없습니다.',
          builder: (gifticons) {
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: gifticons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 0.74,
              ),
              itemBuilder: (context, index) {
                final gifticon = gifticons[index];
                return _GifticonCard(
                  gifticon: gifticon,
                  onTap: gifticon.isSoldOut
                      ? null
                      : () => _purchaseGifticon(gifticon),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPointChargePage() {
    return StreamBuilder<List<PointPackage>>(
      stream: _repository.watchPointPackages(),
      builder: (context, snapshot) {
        return _AsyncContent<List<PointPackage>>(
          snapshot: snapshot,
          emptyMessage: '구매 가능한 포인트 상품이 없습니다.',
          builder: (packages) {
            _requestGooglePlayProducts(packages);
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: packages.length + 3,
              separatorBuilder: (_, index) {
                final isSectionBoundary =
                    index == 0 || index == packages.length;
                return SizedBox(height: isSectionBoundary ? 20 : 8);
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _PointShopBanner(
                    billingNotice: _billingNotice,
                    isLoading: _isBillingCatalogLoading,
                  );
                }

                if (index == packages.length + 1) {
                  return const _PointUsageGuide();
                }

                if (index == packages.length + 2) {
                  return const _PointTermsNotice();
                }

                final pointPackage = packages[index - 1];
                final googleProduct = _googleProducts[pointPackage.id];
                return _PointPackageTile(
                  pointPackage: pointPackage,
                  displayPrice:
                      googleProduct?.price ??
                      '${_formatNumber(pointPackage.priceCash)}원',
                  onTap:
                      googleProduct == null &&
                          widget.onPointPackagePurchase == null
                      ? null
                      : () => _purchasePointPackage(pointPackage),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showEmoticonPackage(EmoticonProduct emoticon) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => _EmoticonPackageSheet(
        emoticon: emoticon,
        onPurchase: () => _purchaseEmoticon(emoticon),
      ),
    );
  }

  Future<void> _purchaseEmoticon(EmoticonProduct emoticon) async {
    final confirmed = await _confirmPointPurchase(
      itemName: emoticon.name,
      pricePoint: emoticon.pricePoint,
    );
    if (!confirmed) return;

    await _runPointPurchase(
      () => _purchaseService.purchaseEmoticon(
        userId: widget.userId,
        emoticonId: emoticon.id,
      ),
    );
  }

  Future<void> _purchaseGifticon(GifticonProduct gifticon) async {
    final confirmed = await _confirmPointPurchase(
      itemName: gifticon.name,
      pricePoint: gifticon.requiredPoint,
    );
    if (!confirmed) return;

    await _runPointPurchase(
      () => _purchaseService.purchaseGifticon(
        userId: widget.userId,
        gifticonId: gifticon.id,
      ),
    );
  }

  Future<void> _purchasePointPackage(PointPackage pointPackage) async {
    final callback = widget.onPointPackagePurchase;
    try {
      if (callback != null) {
        await callback(pointPackage);
      } else {
        await _billingService.buyConsumable(pointPackage.id);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          error is StateError ? error.message : 'Google Play 결제를 시작하지 못했습니다.',
        );
      }
    }
  }

  void _requestGooglePlayProducts(List<PointPackage> packages) {
    final productIds = packages.map((item) => item.id).toSet();
    if (_sameStringSet(_requestedProductIds, productIds)) return;
    _requestedProductIds = productIds;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadGooglePlayProducts(productIds);
    });
  }

  Future<void> _loadGooglePlayProducts(Set<String> productIds) async {
    setState(() {
      _isBillingCatalogLoading = true;
      _billingNotice = 'Google Play 상품 정보를 확인하고 있습니다.';
    });

    final catalog = await _billingService.loadProducts(productIds);
    if (!mounted) return;

    setState(() {
      _isBillingCatalogLoading = false;
      _googleProducts = catalog.products;
      if (catalog.errorMessage != null) {
        _billingNotice = catalog.errorMessage!;
      } else if (catalog.notFoundProductIds.isNotEmpty) {
        _billingNotice =
            'Play Console에서 찾지 못한 상품: '
            '${catalog.notFoundProductIds.join(', ')}';
      } else {
        _billingNotice = 'Google Play 테스트 결제를 사용할 수 있습니다.';
      }
    });
  }

  void _handleGooglePlayPurchaseEvent(GooglePlayPurchaseEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case GooglePlayPurchaseEventType.pending:
        setState(() => _isPurchasing = true);
        break;
      case GooglePlayPurchaseEventType.received:
        setState(() => _isPurchasing = false);
        _showMessage('${event.message} 포인트 지급은 아직 실행하지 않습니다.');
        break;
      case GooglePlayPurchaseEventType.canceled:
      case GooglePlayPurchaseEventType.error:
        setState(() => _isPurchasing = false);
        _showMessage(event.message);
        break;
    }
  }

  Future<bool> _confirmPointPurchase({
    required String itemName,
    required int pricePoint,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구매 확인'),
        content: Text('$itemName을(를) ${_formatNumber(pricePoint)} P로 구매할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('구매'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _runPointPurchase(
    Future<PointPurchaseResult> Function() purchase,
  ) async {
    setState(() => _isPurchasing = true);
    try {
      final result = await purchase();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('구매 완료'),
          content: Text(
            '무료 ${_formatNumber(result.usedFreePoint)} P, '
            '유료 ${_formatNumber(result.usedPaidPoint)} P를 사용했습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } on PointPurchaseException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('구매 처리 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

class _PointShopTabBar extends StatelessWidget {
  const _PointShopTabBar({required this.selectedTab, required this.onSelected});

  final PointShopTab selectedTab;
  final ValueChanged<PointShopTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Row(
        children: PointShopTab.values
            .map((tab) {
              final isSelected = selectedTab == tab;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(tab),
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      tab.tabLabel,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF2468D8)
                            : const Color(0xFF666666),
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _EmoticonThumbnail extends StatelessWidget {
  const _EmoticonThumbnail({required this.emoticon, required this.onTap});

  final EmoticonProduct emoticon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDADADA)),
        ),
        child: Column(
          children: [
            Expanded(
              child: _ProductImage(
                imageUrl: emoticon.imageUrl,
                icon: Icons.emoji_emotions_outlined,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emoticon.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmoticonPackageSheet extends StatelessWidget {
  const _EmoticonPackageSheet({
    required this.emoticon,
    required this.onPurchase,
  });

  final EmoticonProduct emoticon;
  final Future<void> Function() onPurchase;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emoticon.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '구성 이모티콘 ${emoticon.items.length}개',
                          style: const TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_formatNumber(emoticon.pricePoint)} P',
                    style: const TextStyle(
                      color: Color(0xFF2468D8),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E5E5)),
            Expanded(
              child: emoticon.items.isEmpty
                  ? const _PageMessage(
                      icon: Icons.emoji_emotions_outlined,
                      message: '등록된 구성 이모티콘이 없습니다.',
                    )
                  : GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: emoticon.items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemBuilder: (context, index) {
                        return _ProductImage(
                          imageUrl: emoticon.items[index].imageUrl,
                          icon: Icons.emoji_emotions_outlined,
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: emoticon.items.isEmpty ? null : onPurchase,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4D8DFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('패키지 구매하기'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GifticonCard extends StatelessWidget {
  const _GifticonCard({required this.gifticon, required this.onTap});

  final GifticonProduct gifticon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDADADA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ProductImage(
                imageUrl: gifticon.imageUrl,
                icon: Icons.card_giftcard_outlined,
              ),
            ),
            const SizedBox(height: 10),
            if (gifticon.brandName?.isNotEmpty == true)
              Text(
                gifticon.brandName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
              ),
            const SizedBox(height: 3),
            Text(
              gifticon.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              gifticon.isSoldOut
                  ? '품절'
                  : '${_formatNumber(gifticon.requiredPoint)} P',
              style: TextStyle(
                color: gifticon.isSoldOut
                    ? const Color(0xFFE05252)
                    : const Color(0xFF2468D8),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointShopBanner extends StatelessWidget {
  const _PointShopBanner({
    required this.billingNotice,
    required this.isLoading,
  });

  final String billingNotice;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD3E3FF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monetization_on_outlined,
            color: Color(0xFF4D8DFF),
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '얌얌 포인트 충전',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  billingNotice,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _PointPackageTile extends StatelessWidget {
  const _PointPackageTile({
    required this.pointPackage,
    required this.displayPrice,
    required this.onTap,
  });

  final PointPackage pointPackage;
  final String displayPrice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDADADA)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              const Icon(Icons.paid_outlined, color: Color(0xFF4D8DFF)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pointPackage.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                displayPrice,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF999999),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointUsageGuide extends StatelessWidget {
  const _PointUsageGuide();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '포인트 사용처',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _PointUsageCard(
          icon: Icons.emoji_emotions_outlined,
          title: '커뮤니티 이모티콘',
          description: '마음에 드는 이모티콘 패키지를 구매하고 커뮤니티에서 사용할 수 있어요.',
        ),
        const SizedBox(height: 10),
        _PointUsageCard(
          icon: Icons.card_giftcard_outlined,
          title: '기프티콘 교환',
          description: '보유 포인트를 카페와 디저트 브랜드의 기프티콘으로 교환할 수 있어요.',
        ),
      ],
    );
  }
}

class _PointUsageCard extends StatelessWidget {
  const _PointUsageCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF4D8DFF), size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointTermsNotice extends StatelessWidget {
  const _PointTermsNotice();

  static const _notices = [
    '충전된 유료 포인트는 회원 계정에 귀속되며 다른 회원에게 양도할 수 없습니다.',
    '상품 구매 시 무료 포인트가 먼저 사용되고 부족한 금액은 유료 포인트에서 차감됩니다.',
    '유료 포인트는 결제 확인이 완료된 후 지급되며 결제 도중 앱을 종료하면 지급이 지연될 수 있습니다.',
    '무료 포인트는 스탬프, 광고, 이벤트 등의 보상으로만 지급됩니다.',
    '이모티콘 지급 또는 기프티콘 발행이 완료된 구매 건은 환불이 제한될 수 있습니다.',
    '포인트 사용처와 이용 조건은 서비스 운영 정책에 따라 변경될 수 있습니다.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF666666)),
              SizedBox(width: 7),
              Text(
                '포인트 이용 안내',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._notices.map(
            (notice) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: SizedBox(
                      width: 3,
                      height: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF777777),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notice,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '※ 세부 환불 기준은 별도의 이용약관 및 환불 정책을 따릅니다.',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl, required this.icon});

  final String? imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 38, color: const Color(0xFFAAAAAA)),
    );
  }
}

class _AsyncContent<T extends List<Object>> extends StatelessWidget {
  const _AsyncContent({
    required this.snapshot,
    required this.emptyMessage,
    required this.builder,
  });

  final AsyncSnapshot<T> snapshot;
  final String emptyMessage;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return const _PageMessage(
        icon: Icons.error_outline,
        message: '상품 정보를 불러오지 못했습니다.',
      );
    }
    if (!snapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4D8DFF)),
      );
    }
    if (snapshot.data!.isEmpty) {
      return _PageMessage(
        icon: Icons.inventory_2_outlined,
        message: emptyMessage,
      );
    }
    return builder(snapshot.data as T);
  }
}

class _PageMessage extends StatelessWidget {
  const _PageMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xFFAAAAAA)),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Color(0xFF777777))),
        ],
      ),
    );
  }
}

String _formatNumber(int value) =>
    NumberFormat.decimalPattern('ko_KR').format(value);

bool _sameStringSet(Set<String> left, Set<String> right) {
  return left.length == right.length && left.containsAll(right);
}
