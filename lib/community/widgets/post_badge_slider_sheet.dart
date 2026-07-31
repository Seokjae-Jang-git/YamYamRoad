import 'package:flutter/material.dart';

void showBadgeSliderBottomSheet(
    BuildContext context,
    List<Map<String, dynamic>> allBadges, {
      int initialIndex = 0,
    }) {
  const Color creamyIvory = Color(0xFFFFFDF9);
  const Color deepChocolate = Color(0xFF4A3225);
  const Color pointCoralRed = Color(0xFFFF6B57);
  const Color subTextColor = Color(0xFF7A6B63);

  showModalBottomSheet(
    context: context,
    backgroundColor: creamyIvory,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      int currentPage = initialIndex;
      final PageController pageController = PageController(initialPage: initialIndex);

      return StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: deepChocolate.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '보유한 뱃지 (${currentPage + 1}/${allBadges.length})',
                  style: const TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: 190,
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: allBadges.length,
                    onPageChanged: (index) {
                      setBottomSheetState(() {
                        currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final badge = allBadges[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.network(
                              badge['imageUrl'],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.workspace_premium, size: 70, color: pointCoralRed),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            badge['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: deepChocolate,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            badge['description'] ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: subTextColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (allBadges.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(allBadges.length, (dotIndex) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: currentPage == dotIndex ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: currentPage == dotIndex ? pointCoralRed : deepChocolate.withOpacity(0.15),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepChocolate,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );
}