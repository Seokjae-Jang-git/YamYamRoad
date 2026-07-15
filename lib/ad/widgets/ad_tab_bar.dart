import 'package:flutter/material.dart';

class AdTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AdTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.blue[600],
          borderRadius: BorderRadius.circular(22),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: const [
          Tab(text: '구글 애드몹 (Phase 1)'),
          Tab(text: '자체 제휴 (Phase 2)'),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(46);
}