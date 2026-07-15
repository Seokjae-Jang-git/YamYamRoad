import 'package:flutter/material.dart';

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
          _buildBottomCircleTab(context, 2, '얌얌로드', currentIndex == 2),
          _buildBottomCircleTab(context, 3, '포인트', currentIndex == 3),
          _buildBottomCircleTab(context, 4, '마이페이지', currentIndex == 4),
        ],
      ),
    );
  }

  Widget _buildBottomCircleTab(BuildContext context, int index, String label, bool isSelected) {
    final bool isRoadTab = label == '얌얌로드';

    return GestureDetector(
      onTap: () {
        // 🆕 [저결합 리팩토링 핵심]: 이제 바텀바가 특정 화면을 push 하지 않습니다.
        // 마이페이지(4번)를 포함한 모든 탭 터치 이벤트를 부모 컨테이너(상태 관리 영역)에 그대로 전달합니다.
        onTap(index);
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
                  ? Colors.blue[100]
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