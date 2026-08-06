import 'package:flutter/material.dart';
import 'package:yamyam_road/services/auth_service.dart';
import 'package:yamyam_road/services/point_service.dart';
import 'models/point_model.dart';
import 'models/in_house_ad_model.dart';
import 'widgets/point_status_card.dart';
import 'widgets/ad_tab_bar.dart';
import 'widgets/admob_tab_view.dart';
import 'widgets/in_house_tab_view.dart';
import 'services/ad_station_service.dart';

class AdStationPage extends StatefulWidget {
  const AdStationPage({super.key});

  @override
  State<AdStationPage> createState() => _AdStationPageState();
}

class _AdStationPageState extends State<AdStationPage> {
  final PointService _pointService = PointService();
  final AdStationService _adStationService = AdStationService();

  @override
  void initState() {
    super.initState();
    _adStationService.initAdMob(
      onUpdate: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _adStationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = AuthService.currentUser?.uid;

    // 브랜드 포근한 베이지 & 브라운 컬러
    const Color creamBgColor = Color(0xFFFAF7F2); // 포근한 크림 베이지
    const Color deepChocolate = Color(0xFF4A3225); // 메인 딥 브라운
    const Color softBorderColor = Color(0xFFE5DDD5); // 은은한 베이지 구분선
    const Color cocoaBrown = Color(0xFF8C7A6B); // 보조 브라운 텍스트
    const Color caramelAccent = Color(0xFFC88A4B); // 카라멜 브라운 로딩 강조

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: creamBgColor,
        appBar: AppBar(
          title: const Text(
            '무료 포인트 충전소',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: deepChocolate,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: deepChocolate),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: creamBgColor,
          foregroundColor: deepChocolate,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Divider(
              color: softBorderColor,
              height: 1.0,
              thickness: 1.0,
            ),
          ),
        ),
        body: uid == null
            ? const Center(
          child: Text(
            '로그인이 필요한 서비스입니다.',
            style: TextStyle(fontSize: 16, color: cocoaBrown),
          ),
        )
            : StreamBuilder<PointModel>(
          stream: _pointService.getPointStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: caramelAccent,
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '데이터를 불러오는데 실패했습니다: ${snapshot.error}',
                  style: const TextStyle(color: cocoaBrown),
                ),
              );
            }

            final pointModel = snapshot.data ?? PointModel.initial();

            return SafeArea(
              child: Column(
                children: [
                  PointStatusCard(points: pointModel.points),
                  const AdTabBar(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        AdmobTabView(
                          isAdLoading:
                          _adStationService.adMobManager.isAdLoading,
                          pointModel: pointModel,
                          onWatchAdMobAd: (adId, rewardPoints) =>
                              _adStationService.handleAdMobAd(
                                context: context,
                                uid: uid,
                                adId: adId,
                                rewardPoints: rewardPoints,
                                pointModel: pointModel,
                              ),
                        ),
                        InHouseTabView(
                          pointModel: pointModel,
                          onPlayInHouseAd: (ad) =>
                              _adStationService.handleInHouseAd(
                                context: context,
                                uid: uid,
                                ad: ad,
                                pointModel: pointModel,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}