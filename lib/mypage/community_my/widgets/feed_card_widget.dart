import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../common/user_data.dart';
import '../repository/community_my_repository.dart';

class FeedCardWidget extends StatelessWidget {
  final Map<String, dynamic> feed;

  const FeedCardWidget({Key? key, required this.feed}) : super(key: key);

  // 🌟 이모티콘 텍스트 파싱 및 렌더링 함수
  Widget _buildParsedContent(String content) {
    final RegExp emojiRegex = RegExp(r'\[emoji:(.*?)\]');
    final Iterable<RegExpMatch> matches = emojiRegex.allMatches(content);

    if (matches.isEmpty) {
      return Text('• $content', style: const TextStyle(fontSize: 14, height: 1.4));
    }

    List<InlineSpan> spans = [];
    int currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: content.substring(currentIndex, match.start)));
      }

      final String rawEmojiPath = match.group(1) ?? '';

      String cleanPath = rawEmojiPath.replaceAll(':', '/');
      cleanPath = cleanPath.replaceAll('emo_character_test', 'character');
      cleanPath = cleanPath.replaceAll('emo_emoji_test', 'emoji');
      cleanPath = cleanPath.replaceAll('emo_penguin_test', 'penguin');
      cleanPath = cleanPath.replaceAll('emo_meme_test', 'meme');
      cleanPath = cleanPath.replaceAll('emo_cloud_test', 'cloud');

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: SvgPicture.asset(
              'assets/emoticons/$cleanPath',
              width: 22,
              height: 22,
            ),
          ),
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < content.length) {
      spans.add(TextSpan(text: content.substring(currentIndex)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black),
        children: [
          const TextSpan(text: '• '),
          ...spans,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> imageUrls = feed['imageUrls'] ?? [];
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
                  _buildBadgeList(authorUid),
                ],
              ),
              const SizedBox(height: 16),

              // 이모티콘 파싱 위젯 적용
              _buildParsedContent(feed['content'] ?? ''),

              const SizedBox(height: 16),

              // 🌟 수정된 부분: 이미지가 있을 때만 스와이프 영역 렌더링, 없으면 아예 아무것도 안 그림
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

  // 뱃지 목록 렌더링
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
        const int maxDisplayCount = 3;

        final List<Map<String, dynamic>> displayBadges = allBadges.take(maxDisplayCount).toList();
        final bool hasMore = totalCount > maxDisplayCount;
        final int extraCount = totalCount - maxDisplayCount;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ...displayBadges.asMap().entries.map((entry) {
              final int index = entry.key;
              final badgeData = entry.value;
              return _buildBadgeIconItem(context, badgeData, allBadges, initialIndex: index);
            }),
            if (hasMore) ...[
              const SizedBox(width: 2),
              _buildPlusMoreButton(context, allBadges, extraCount: extraCount, startIndex: maxDisplayCount),
            ],
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllUserBadges(String userId) async {
    final userBadgeSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users_badge')
        .get();

    if (userBadgeSnap.docs.isEmpty) return [];

    var selectedDocs = userBadgeSnap.docs
        .where((d) => d.data()['isSelected'] == true)
        .toList();

    selectedDocs.sort((a, b) {
      int orderA = a.data()['displayOrder'] ?? 99;
      int orderB = b.data()['displayOrder'] ?? 99;
      return orderA.compareTo(orderB);
    });

    var unselectedDocs = userBadgeSnap.docs
        .where((d) => d.data()['isSelected'] != true)
        .toList();

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
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '보유한 뱃지 (${currentPage + 1}/${allBadges.length})',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
                            color: currentPage == dotIndex ? Colors.black : Colors.grey.shade300,
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