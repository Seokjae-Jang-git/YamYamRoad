import 'package:flutter/material.dart';

/// 포인트 상점 탭 구분 열거형
enum PointShopTab {
  emoticon('이모티콘', '이모티콘'),
  gifticon('기프티콘', '기프티콘'),
  charge('포인트 충전', '포인트 충전');

  const PointShopTab(this.tabLabel, this.pageTitle);

  final String tabLabel;
  final String pageTitle;
}

/// 포인트 상점 상단 토글 탭바 위젯
class PointShopTabBar extends StatelessWidget {
  const PointShopTabBar({
    super.key,
    required this.selectedTab,
    required this.onSelected,
  });

  final PointShopTab selectedTab;
  final ValueChanged<PointShopTab> onSelected;

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subBrown = Color(0xFF7A6B63);
  static const Color cardBorder = Color(0xFFEFEBE4);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: PointShopTab.values
            .map((tab) {
              final isSelected = selectedTab == tab;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(tab),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: isSelected
                        ? const Duration(milliseconds: 90)
                        : Duration.zero,
                    curve: Curves.easeOut,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x0D4A3225),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      tab.tabLabel,
                      style: TextStyle(
                        color: isSelected ? deepChocolate : subBrown,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: -0.2,
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
