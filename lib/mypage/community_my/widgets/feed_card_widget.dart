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

                  // 2. 닉네임 + 작성 시간 (Column)
                  // 🌟 [수정 포인트 1] Expanded 대신 Flexible을 사용하여 남는 공간을 다 차지하지 않고, 자기 내용물만큼만 자리 차지! (오버플로우 방지 기능은 유지)
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

                  const SizedBox(width: 8), // 닉네임과 뱃지 사이의 적당한 간격

                  // 3. 뱃지 아이콘 영역 (이제 닉네임 바로 옆에 붙습니다!)
                  _buildBadgeList(authorUid),
                ],
              ),
              const SizedBox(height: 16),
              Text('• ${feed['content'] ?? ''}', style: const TextStyle(fontSize: 14, height: 1.4)),
              const SizedBox(height: 16),

              // 이미지 스와이프 렌더링 영역
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

  // 대표 뱃지 목록 렌더링 영역
  Widget _buildBadgeList(String userId) {
    if (userId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchSelectedBadges(userId),
      builder: (context, badgeSnapshot) {
        if (!badgeSnapshot.hasData || badgeSnapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<Map<String, dynamic>> badgeList = badgeSnapshot.data!;

        return Row(
          mainAxisSize: MainAxisSize.min, // 영역을 최소한으로 사용
          crossAxisAlignment: CrossAxisAlignment.center,
          children: badgeList
              .map((badgeData) => _buildBadgeItemWithBottomSheet(context, badgeData))
              .toList(),
        );
      },
    );
  }

  // Firestore에서 대표 뱃지의 상세 정보를 싹 가져오는 비동기 함수
  Future<List<Map<String, dynamic>>> _fetchSelectedBadges(String userId) async {
    final userBadgeSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_badge')
        .where('isSelected', isEqualTo: true)
        .limit(3)
        .get();

    if (userBadgeSnap.docs.isEmpty) return [];

    final badgeIds = userBadgeSnap.docs.map((d) => d.data()['badgeId'] as String).toList();

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
          'iconUrl': data['iconUrl'] ?? '',
        });
      }
    }

    return badgeDetails;
  }

  // 아이콘 탭 시 인터랙티브 바텀 시트를 띄워주는 위젯
  Widget _buildBadgeItemWithBottomSheet(BuildContext context, Map<String, dynamic> badgeData) {
    final String iconUrl = badgeData['iconUrl'];
    final String imageUrl = badgeData['imageUrl'];
    final String name = badgeData['name'];
    final String description = badgeData['description'];

    return GestureDetector(
      onTap: () {
        _showBadgeDetailBottomSheet(context, name, description, imageUrl);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 6.0),
        // 🌟 [수정 포인트 2] 크기를 36x36으로 고정시키는 SizedBox 적용!
        child: SizedBox(
          width: 36,
          height: 36,
          child: Image.network(
            iconUrl,
            fit: BoxFit.contain, // 영역 안에서 비율 깨지지 않게 꽉 채움
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  // 스르륵 올라오는 화려한 뱃지 상세 바텀 시트
  void _showBadgeDetailBottomSheet(
      BuildContext context,
      String name,
      String description,
      String imageUrl,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 120,
                height: 120,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.workspace_premium, size: 80, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}