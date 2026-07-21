import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/user_data.dart';
import '../repository/community_my_repository.dart'; // 🌟 바뀐 레포지토리 경로 바인딩

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
      future: isMyPost
          ? null
          : FirebaseFirestore.instance.collection('users').doc(authorUid).get(),
      builder: (context, userSnapshot) {
        String postNickname = isMyPost ? (UserData.nickname ?? '이름없음') : '유저';
        String? postProfilePath = isMyPost ? UserData.profileImagePath : null;
        bool isDefaultImg = isMyPost ? UserData.isDefaultProfileImage : true;

        if (!isMyPost && userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData && userSnapshot.data!.exists) {
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
                children: [
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(postNickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          _buildDiamondBadge('뱃지 1'),
                          const SizedBox(width: 4),
                          _buildDiamondBadge('뱃지 2'),
                          const SizedBox(width: 4),
                          _buildDiamondBadge('뱃지 3'),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // 🌟 변경된 헬퍼 함수 호출
                      Text(CommunityMyRepository.getTimeAgo(feed['createdAt']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
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

  Widget _buildDiamondBadge(String label) {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), color: Colors.white),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: -0.785398,
          child: Text(label, style: const TextStyle(fontSize: 8, color: Colors.black87)),
        ),
      ),
    );
  }
}