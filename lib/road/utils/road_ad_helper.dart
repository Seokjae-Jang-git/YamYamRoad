import 'package:flutter/material.dart';
import '../models/road.dart';
import '../widgets/course_list_card.dart';
import '../widgets/ad_mob_banner_widget.dart';

class RoadAdHelper {
  /// 피드 리스트 중간에 AdMob 배너 위젯을 동적으로 조합하는 순수 함수
  static List<Widget> buildListWithAds({
    required List<Road> listToShow,
    required void Function(Road road) onCardPressed,
  }) {
    List<Widget> items = [];

    if (listToShow.isEmpty) {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 64.0),
          child: Center(
            child: Text(
              '해당 조건에 맞는 코스가 존재하지 않습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      );
      items.add(const AdMobBannerWidget());
      return items;
    }

    // 카드 수가 2개 이하인 경우 바로 밑에 노출
    if (listToShow.length <= 2) {
      for (var road in listToShow) {
        items.add(
          CourseListCard(
            road: road,
            onTap: () => onCardPressed(road),
          ),
        );
      }
      items.add(const AdMobBannerWidget());
    }
    // 카드 수가 3개 이상인 경우 3개 카드 마다 광고 배치
    else {
      for (int i = 0; i < listToShow.length; i++) {
        final road = listToShow[i];
        items.add(
          CourseListCard(
            road: road,
            onTap: () => onCardPressed(road),
          ),
        );

        if ((i + 1) % 3 == 0) {
          items.add(const AdMobBannerWidget());
        }
      }
    }

    return items;
  }
}