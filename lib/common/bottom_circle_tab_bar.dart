import 'package:flutter/material.dart';
import '../mypage/mypage_main.dart';

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
          _buildBottomCircleTab(context, 2, '커뮤니티\n(냠냠로드)', currentIndex == 2),
          _buildBottomCircleTab(context, 3, '포인트', currentIndex == 3),
          _buildBottomCircleTab(context, 4, '마이\n페이지', currentIndex == 4),
        ],
      ),
    );
  }

  Widget _buildBottomCircleTab(BuildContext context, int index, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (index == 4 && currentIndex != 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyPageMainScreen(),
            ),
          );
        } else {
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
              color: label.contains('커뮤니티')
                  ? Colors.blue[100]
                  : (isSelected ? Colors.blue[50] : Colors.white),
            ),
            alignment: Alignment.center,
            child: Text(
              label.contains('커뮤니티') ? '커뮤니티' : label.replaceAll('\n', ''),
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