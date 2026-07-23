import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/user_data.dart';
import '../repository/community_my_repository.dart';

class FeedCardWidget extends StatelessWidget {
  final Map<String, dynamic> feed;

  const FeedCardWidget({Key? key, required this.feed}) : super(key: key);

  final String _dummyImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/yamyamroad.firebasestorage.app/o/post_img%2F%E1%84%8F%E1%85%A1%E1%84%9Play%E1%84%85%E1%85%A1%E1%84%84%E1%85%A6_01.png?alt=media&token=9d42af77-26f8-4eb4-be0b-b3451a897972';

  @override
  Widget build(BuildContext context) {
    List<dynamic> imageUrls = feed['imageUrls'] ?? [];
    String displayImage = imageUrls.isNotEmpty ? imageUrls[0] : _dummyImageUrl;

    final String authorUid = feed['userId'] ?? '';
    final bool isMyPost = authorUid == UserData.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(authorUid).get(),
      builder: (context, userSnapshot) {
        String postNickname = isMyPost ? (UserData.nickname ?? '이름없음') : '유저';
        String? postProfilePath = isMyPost ? UserData.profileImagePath : null;
        bool isDefaultImg = isMyPost ? UserData.isDefaultProfileImage : true;

        if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          postNickname = userData['nickname'] ?? userData['name'] ?? '이름없음';
          postProfilePath = userData['profileImageUrl'];
          isDefaultImg = postProfilePath == null || postProfilePath.trim().isEmpty;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 유저 정보 영역
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. 프로필 이미지
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFF5F5F5),
                    child: isDefaultImg || postProfilePath == null
                        ? const Icon(Icons.person_outline, size: 22, color: Colors.grey)
                        : ClipOval(
                      child: Image.network(
                        postProfilePath,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_outline, size: 22, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 2. 닉네임 + 작성 시간
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postNickname,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CommunityMyRepository.getTimeAgo(feed['createdAt']),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 🌟 3. 획득한 뱃지 아이콘 영역 (최대 3개 및 +N 지원)
                  _buildBadgeList(authorUid),
                ],
              ),
              const SizedBox(height: 16),
              Text('• ${feed['content'] ?? ''}', style: const TextStyle(fontSize: 14, height: 1.4)),
              const SizedBox(height: 16),

              // 이미지 스와이프 영역
              if (imageUrls.isNotEmpty) ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    int currentPage = 0;
                    return StatefulBuilder(
                      builder: (context, setPageState) {
                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 240,
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                              child: PageView.builder(
                                itemCount: imageUrls.length,
                                onPageChanged: (int page) => setPageState(() => currentPage = page),
                                itemBuilder: (context, imgIndex) {
                                  return Image.network(
                                    imageUrls[imgIndex],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => const Center(child: Text('이미지를 불러올 수 없습니다.', style: TextStyle(color: Colors.grey))),
                                  );
                                },
                              ),
                            ),
                            if (imageUrls.length > 1) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(imageUrls.length, (dotIndex) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: currentPage == dotIndex ? Colors.black87 : Colors.grey.shade300,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  child: Image.network(_dummyImageUrl, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Text('좋아요 ${feed['likeCount'] ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Text('댓글 ${feed['commentCount'] ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Text('스크랩 ${feed['scrapCount'] ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 🌟 뱃지 목록 렌더링 (뱃지 아이콘 3개 노출 + 초과분 +N 표시)
  Widget _buildBadgeList(String userId) {
    if (userId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllUserBadges(userId),
      builder: (context, badgeSnapshot) {
        if (!badgeSnapshot.hasData || badgeSnapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<Map<String, dynamic>> allBadges = badgeSnapshot.data!;
        final int totalCount = allBadges.length;

        // 💡 하드코딩 대신 최대 노출 개수를 변수로 관리!
        const int maxDisplayCount = 3;

        // 아이콘은 무조건 설정한 개수(3개)만큼 화면에 잘라서 보여줍니다.
        final List<Map<String, dynamic>> displayBadges = allBadges.take(maxDisplayCount).toList();

        // 전체 개수가 maxDisplayCount(3개)보다 많을 때만 +N 태그 생성
        final bool hasMore = totalCount > maxDisplayCount;
        final int extraCount = totalCount - maxDisplayCount; // 5 - 3 = 2 (+2)

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. 뱃지 아이콘 3개 렌더링
            ...displayBadges.asMap().entries.map((entry) {
              final int index = entry.key;
              final badgeData = entry.value;
              return _buildBadgeIconItem(context, badgeData, allBadges, initialIndex: index);
            }),

            // 2. 3개 초과 시 뒤에 +2 버튼 추가
            if (hasMore) ...[
              const SizedBox(width: 2),
              _buildPlusMoreButton(context, allBadges, extraCount: extraCount, startIndex: maxDisplayCount),
            ],
          ],
        );
      },
    );
  }

  // 🌟 대표 뱃지(isSelected: true)를 displayOrder 순(1->2->3)으로 우선 배치하고,
  // 나머지 획득한 뱃지들을 뒤에 이어서 붙여 전체 뱃지 목록을 생성합니다.
  Future<List<Map<String, dynamic>>> _fetchAllUserBadges(String userId) async {
    final userBadgeSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_badge')
        .get();

    if (userBadgeSnap.docs.isEmpty) return [];

    // 1. isSelected == true 인 대표 뱃지들을 추출 및 displayOrder 순 정렬
    var selectedDocs = userBadgeSnap.docs
        .where((d) => d.data()['isSelected'] == true)
        .toList();

    selectedDocs.sort((a, b) {
      int orderA = a.data()['displayOrder'] ?? 99;
      int orderB = b.data()['displayOrder'] ?? 99;
      return orderA.compareTo(orderB);
    });

    // 2. 대표 뱃지로 선택되지 않은 나머지 획득 뱃지들 추출
    var unselectedDocs = userBadgeSnap.docs
        .where((d) => d.data()['isSelected'] != true)
        .toList();

    // 3. 대표 뱃지 + 나머지 뱃지를 순서대로 합침 (총 N개)
    final allDocs = [...selectedDocs, ...unselectedDocs];
    final badgeIds = allDocs.map((d) => d.data()['badgeId'] as String).toList();

    final List<Map<String, dynamic>> badgeDetails = [];
    for (String bId in badgeIds) {
      final badgeDoc = await FirebaseFirestore.instance.collection('badge').doc(bId).get();
      if (badgeDoc.exists && badgeDoc.data()?['isActive'] == true) {
        final data = badgeDoc.data()!;
        badgeDetails.add({
          'id': bId,
          'name': data['name'] ?? '뱃지',
          'description': data['description'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'iconUrl': data['iconUrl'] ?? data['imageUrl'] ?? '',
        });
      }
    }

    return badgeDetails;
  }

  // 개별 뱃지 아이콘 위젯 (터치 시 해당 위치부터 시작하는 슬라이더 바텀시트 호출)
  Widget _buildBadgeIconItem(
      BuildContext context,
      Map<String, dynamic> badgeData,
      List<Map<String, dynamic>> allBadges, {
        required int initialIndex,
      }) {
    final String iconUrl = badgeData['iconUrl'];

    return GestureDetector(
      onTap: () {
        _showBadgeSliderBottomSheet(context, allBadges, initialIndex: initialIndex);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Image.network(
            iconUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  // 🌟 +N (예: +3) 더보기 버튼 위젯
  Widget _buildPlusMoreButton(
      BuildContext context,
      List<Map<String, dynamic>> allBadges, {
        required int extraCount,
        required int startIndex,
      }) {
    return GestureDetector(
      onTap: () {
        _showBadgeSliderBottomSheet(context, allBadges, initialIndex: startIndex);
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        child: Center(
          child: Text(
            '+$extraCount',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // 🌟 좌우 스와이프 가능한 슬라이드형 뱃지 전체보기 바텀 시트
  void _showBadgeSliderBottomSheet(
      BuildContext context,
      List<Map<String, dynamic>> allBadges, {
        int initialIndex = 0,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                  // 상단 드래그 손잡이
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 뱃지 개수 표시
                  Text(
                    '보유한 뱃지 (${currentPage + 1}/${allBadges.length})',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),

                  // 🌟 좌우 슬라이드 PageView 영역
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
                                const Icon(Icons.workspace_premium, size: 70, color: Colors.orange),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              badge['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              badge['description'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.3,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // 🌟 하단 인디케이터 Dot (뱃지가 2개 이상일 때)
                  if (allBadges.length > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(allBadges.length, (dotIndex) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: currentPage == dotIndex ? 16 : 6, // 현재 페이지 강조
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: currentPage == dotIndex ? Colors.black : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 닫기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
}