import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../repository/stamp_repository.dart';

class StampBoardModal extends StatelessWidget {
  final Map<String, dynamic> roadData;

  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  const StampBoardModal({
    super.key,
    required this.roadData,
  });

  static void show(BuildContext context, Map<String, dynamic> roadData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: creamyIvory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StampBoardModal(roadData: roadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> placeIds = roadData['roadPlace'] ?? [];

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        StampRepository.getMyStampsMap(),
        StampRepository.getPlaceNames(placeIds),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator(color: deepChocolate)),
          );
        }

        final results = snapshot.data ?? [{}, {}];
        final myStampsMap = results[0] as Map<String, Map<String, dynamic>>;
        final placeNamesMap = results[1] as Map<String, String>;

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    roadData['title'] ?? '스탬프 판',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: deepChocolate,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: deepChocolate),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: deepChocolate.withOpacity(0.12)),
              const SizedBox(height: 10),

              if (placeIds.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      '등록된 매장이 없습니다.',
                      style: TextStyle(color: subTextColor),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: placeIds.length,
                    itemBuilder: (context, index) {
                      final String placeId = placeIds[index].toString();
                      final bool isStamped = myStampsMap.containsKey(placeId);
                      final String storeName = placeNamesMap[placeId] ?? '매장 ${index + 1}';

                      final stampData = myStampsMap[placeId] ?? {};
                      if (stampData['placeName'] == null || stampData['placeName'].toString().isEmpty) {
                        stampData['placeName'] = storeName;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: deepChocolate.withOpacity(0.12)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(4),
                        child: isStamped
                            ? _buildRedStampUI(stampData, storeName)
                            : Text(
                          storeName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: deepChocolate,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRedStampUI(Map<String, dynamic>? stampData, String storeName) {
    String dateStr = '';
    if (stampData != null && stampData['issuedAt'] != null) {
      final DateTime dt = (stampData['issuedAt'] as Timestamp).toDate();
      dateStr = DateFormat('yy.MM.dd').format(dt);
    }

    final String displayName = stampData?['placeName'] ?? storeName;

    return Transform.rotate(
      angle: -0.12,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: pointCoralRed, width: 2.0),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: pointCoralRed,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: const TextStyle(color: pointCoralRed, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }
}