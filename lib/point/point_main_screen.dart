import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../AI/ai_recommendation_page.dart';
import '../providers/user_location_provider.dart';
import 'logic/point_purchase_service.dart';
import 'logic/point_repository.dart';
import 'logic/point_usage_calculator.dart';
import 'logic/portone_point_payment_api_client.dart';
import 'models/point_models.dart';
import 'views/point_charge_view.dart';
import 'views/point_emoticon_view.dart';
import 'views/point_gifticon_view.dart';
import 'widgets/gifticon_detail_screen.dart';
import 'widgets/point_balance_widgets.dart';
import 'widgets/point_emoticon_widgets.dart';
import 'widgets/point_shop_dialogs.dart';
import 'widgets/point_shop_tab_bar.dart';
import 'widgets/portone_payment_screen.dart';
import '../stamp/widgets/stamp_dev_place_entry_page.dart';

typedef PointPackagePurchaseHandler =
    Future<void> Function(PointPackage pointPackage);

class PointMainScreen extends StatefulWidget {
  const PointMainScreen({
    super.key,
    required this.userId,
    this.repository,
    this.purchaseService,
    this.pointPaymentApiClient,
    this.initialTab = PointShopTab.emoticon,
    this.onPointPackagePurchase,
  });

  final String userId;
  final PointShopRepository? repository;
  final PointPurchaseService? purchaseService;
  final PortonePointPaymentApiClient? pointPaymentApiClient;
  final PointShopTab initialTab;
  final PointPackagePurchaseHandler? onPointPackagePurchase;

  @override
  State<PointMainScreen> createState() => _PointMainScreenState();
}

class _PointMainScreenState extends State<PointMainScreen> {
  late final PointShopRepository _repository;
  late final PointPurchaseService _purchaseService;
  PortonePointPaymentApiClient? _pointPaymentApiClient;
  StreamSubscription<PointBalance>? _pointBalanceSubscription;
  late PointShopTab _selectedTab;
  PointBalance? _pointBalance;
  bool _isPointBalanceLoading = true;
  bool _isPurchasing = false;

  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color cardBorder = Color(0xFFEFEBE4);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestorePointShopRepository();
    _purchaseService =
        widget.purchaseService ?? FirestorePointPurchaseService();
    _pointPaymentApiClient = widget.pointPaymentApiClient;
    _selectedTab = widget.initialTab;
    _pointBalanceSubscription = _repository
        .watchPointBalance(widget.userId)
        .listen(
          (balance) {
            if (!mounted) return;
            setState(() {
              _pointBalance = balance;
              _isPointBalanceLoading = false;
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _isPointBalanceLoading = false);
          },
        );
  }

  @override
  void dispose() {
    _pointBalanceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: creamyIvory,
        foregroundColor: deepChocolate,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Expanded(
              child: Text(
                _selectedTab.pageTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: deepChocolate,
                ),
              ),
            ),
            PointBalanceHeader(
              balance: _pointBalance,
              isLoading: _isPointBalanceLoading,
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: cardBorder),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: PointShopTabBar(
                  selectedTab: _selectedTab,
                  onSelected: (tab) => setState(() => _selectedTab = tab),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: switch (_selectedTab) {
                  PointShopTab.emoticon => PointEmoticonView(
                    repository: _repository,
                    onSelectEmoticon: _showEmoticonPackage,
                    onOpenAiRecommendationPage: _openAiRecommendationPage,
                    onOpenStampDevPage: _openStampDevPage,
                  ),
                  PointShopTab.gifticon => PointGifticonView(
                    repository: _repository,
                    onSelectGifticon: _openGifticonDetail,
                  ),
                  PointShopTab.charge => PointChargeView(
                    repository: _repository,
                    onPurchasePackage: _purchasePointPackage,
                  ),
                },
              ),
            ],
          ),
          if (_isPurchasing)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: CircularProgressIndicator(color: pointCoralRed),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showEmoticonPackage(EmoticonProduct emoticon) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: creamyIvory,
      builder: (context) => EmoticonPackageSheet(
        emoticon: emoticon,
        onPurchase: () => _purchaseEmoticon(emoticon),
      ),
    );
  }

  Future<void> _openStampDevPage() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const StampDevPlaceEntryPage()),
    );
  }

  Future<void> _openAiRecommendationPage() {
    final location = context.read<UserLocationProvider>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiRecommendationPage(
          userId: widget.userId,
          userLat: location.userLat,
          userLng: location.userLng,
        ),
      ),
    );
  }

  Future<void> _purchaseEmoticon(EmoticonProduct emoticon) async {
    final confirmed = await _confirmPointPurchase(
      itemName: emoticon.name,
      pricePoint: emoticon.pricePoint,
    );
    if (!mounted || !confirmed) return;

    await _runPointPurchase(
      itemName: emoticon.name,
      purchase: () => _purchaseService.purchaseEmoticon(
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
    if (!mounted || !confirmed) return;

    await _runPointPurchase(
      itemName: gifticon.name,
      purchase: () => _purchaseService.purchaseGifticon(
        userId: widget.userId,
        gifticonId: gifticon.id,
      ),
    );
  }

  Future<void> _openGifticonDetail(GifticonProduct gifticon) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GifticonDetailScreen(
          gifticon: gifticon,
          onPurchase: () => _purchaseGifticon(gifticon),
        ),
      ),
    );
  }

  Future<void> _purchasePointPackage(PointPackage pointPackage) async {
    final balance = _pointBalance;
    if (balance == null) {
      PointShopDialogs.showMessage(context, '보유 포인트를 불러온 뒤 다시 시도해 주세요.');
      return;
    }
    final confirmed = await PointShopDialogs.confirmPointCharge(
      context: context,
      pointPackage: pointPackage,
      balance: balance,
    );
    if (!mounted || !confirmed) return;

    final callback = widget.onPointPackagePurchase;
    try {
      if (callback != null) {
        await callback(pointPackage);
        return;
      }

      setState(() => _isPurchasing = true);
      final pointPaymentApiClient = _pointPaymentApiClient ??=
          PortonePointPaymentApiClient();
      final preparation = await pointPaymentApiClient.preparePayment(
        userId: widget.userId,
        pointPackageId: pointPackage.id,
      );
      if (!mounted) return;

      setState(() => _isPurchasing = false);
      final checkoutResult = await Navigator.of(context)
          .push<PortoneCheckoutResult>(
            MaterialPageRoute<PortoneCheckoutResult>(
              builder: (context) => PortonePaymentScreen(
                userId: widget.userId,
                preparation: preparation,
              ),
            ),
          );
      if (!mounted || checkoutResult == null) return;

      if (!checkoutResult.isSuccess) {
        PointShopDialogs.showMessage(
          context,
          checkoutResult.errorMessage ?? '결제가 취소되었습니다.',
        );
        return;
      }

      setState(() => _isPurchasing = true);
      final result = await pointPaymentApiClient.completePayment(
        userId: widget.userId,
        paymentId: checkoutResult.paymentId,
      );
      if (!mounted) return;

      _applyPointPurchaseResult(result);
      await PointShopDialogs.showPointChargeSuccessDialog(
        context: context,
        pointAmount: pointPackage.pointAmount,
        result: result,
      );
    } catch (error) {
      if (mounted) {
        PointShopDialogs.showMessage(
          context,
          error is PointPurchaseException
              ? error.message
              : '포인트 결제를 처리하지 못했습니다.',
        );
      }
    } finally {
      if (mounted && _isPurchasing) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<bool> _confirmPointPurchase({
    required String itemName,
    required int pricePoint,
  }) async {
    final balance = _pointBalance;
    if (balance == null) {
      PointShopDialogs.showMessage(context, '보유 포인트를 불러온 뒤 다시 시도해 주세요.');
      return false;
    }

    late final PointUsageCalculation usage;
    try {
      usage = const PointUsageCalculator().calculate(
        freePointBalance: balance.freePoint,
        paidPointBalance: balance.paidPoint,
        pricePoint: pricePoint,
      );
    } on PointPurchaseException catch (error) {
      PointShopDialogs.showMessage(context, error.message);
      return false;
    }

    return PointShopDialogs.confirmPurchase(
      context: context,
      itemName: itemName,
      balance: balance,
      usage: usage,
    );
  }

  Future<void> _runPointPurchase({
    required String itemName,
    required Future<PointPurchaseResult> Function() purchase,
  }) async {
    if (!mounted) return;
    setState(() => _isPurchasing = true);
    try {
      final result = await purchase();
      if (!mounted) return;
      _applyPointPurchaseResult(result);
      await PointShopDialogs.showSuccessDialog(
        context: context,
        itemName: itemName,
        result: result,
      );
    } on PointPurchaseException catch (error) {
      if (mounted) PointShopDialogs.showMessage(context, error.message);
    } catch (_) {
      if (mounted) {
        PointShopDialogs.showMessage(context, '구매 처리 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _applyPointPurchaseResult(PointPurchaseResult result) {
    setState(() {
      _pointBalance = PointBalance(
        freePoint: result.remainingFreePoint,
        paidPoint: result.remainingPaidPoint,
      );
      _isPointBalanceLoading = false;
    });
  }
}
