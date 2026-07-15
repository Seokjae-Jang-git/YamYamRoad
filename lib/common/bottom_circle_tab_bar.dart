import 'package:flutter/material.dart';
import '../mypage/mypage_main.dart'; // 마이페이지가 위치한 경로로 정상 수립 완료

class BottomCircleTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomCircleTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomCircleTab(context, 0, '홈', currentIndex == 0),
          _buildBottomCircleTab(context, 1, '얌얌북', currentIndex == 1),
          _buildBottomCircleTab(context, 2, '얌얌로드', currentIndex == 2), // 🆕 '커뮤니티(냠냠로드)'에서 깔끔하게 '얌얌로드'로 통합 완료!
          _buildBottomCircleTab(context, 3, '포인트', currentIndex == 3),
          _buildBottomCircleTab(context, 4, '마이페이지', currentIndex == 4), // 🆕 '마이페이지'로 줄바꿈 없이 정돈
        ],
      ),
    );
  }

  Widget _buildBottomCircleTab(BuildContext context, int index, String label, bool isSelected) {
    // 🆕 '얌얌로드' 탭일 경우 특별 강조 스타일링을 적용하기 위한 판별식
    final bool isRoadTab = label == '얌얌로드';

    return GestureDetector(
      onTap: () {
        if (index == 4) {
          // 🌟 4번(마이페이지) 클릭 시 홈 화면 상태를 바꾸지 않고 마이페이지를 화면 위에 새로 얹습니다.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyPageMainScreen(),
            ),
          );
        } else {
          // 0~3번 탭은 기존 홈 화면의 탭 교체 로직을 그대로 따릅니다.
          onTap(index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
                width: isSelected ? 2.0 : 1.0,
              ),
              color: isRoadTab
                  ? Colors.blue[100] // 얌얌로드 탭은 항상 산뜻한 하늘색 톤으로 기획서처럼 특별히 강조해 줍니다.
                  : (isSelected ? Colors.blue[50] : Colors.white),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue[900] : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}