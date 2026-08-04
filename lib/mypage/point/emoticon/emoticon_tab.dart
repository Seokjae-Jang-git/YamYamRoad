import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../common/user_data.dart'; // 프로젝트 경로에 맞게 수정해 주세요.

class EmoticonTab extends StatefulWidget {
  const EmoticonTab({Key? key}) : super(key: key);

  @override
  State<EmoticonTab> createState() => _EmoticonTabState();
}

class _EmoticonTabState extends State<EmoticonTab> {
  // 🌟 얌얌로드 공식 컬러 팔레트
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  String _selectedSubTab = '사용'; // '사용' 또는 '미사용'

  @override
  Widget build(BuildContext context) {
    final String uid = UserData.uid ?? '';
    if (uid.isEmpty) {
      return const Center(child: Text('로그인 정보가 없습니다.', style: TextStyle(color: deepChocolate)));
    }

    return Container(
      color: creamyIvory, // 🌟 전체 배경색 적용
      child: Column(
        children: [
          _buildSubTabBar(),
          Expanded(
            child: _selectedSubTab == '사용'
                ? ActiveEmoticonList(uid: uid)
                : InactiveEmoticonList(uid: uid),
          ),
        ],
      ),
    );
  }

  // 🌟 상단 서브 탭 (알약 형태의 토글 버튼 스타일로 리디자인)
  Widget _buildSubTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: creamyIvory,
        border: Border(bottom: BorderSide(color: deepChocolate.withOpacity(0.08), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSubTabButton('사용'),
          const SizedBox(width: 16),
          _buildSubTabButton('미사용'),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String title) {
    final bool isSelected = _selectedSubTab == title;
    return InkWell(
      onTap: () => setState(() => _selectedSubTab = title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? deepChocolate : Colors.white,
          border: Border.all(color: isSelected ? deepChocolate : deepChocolate.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(20), // 🌟 둥근 알약 형태
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : subTextColor,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. [사용] 탭 리스트 (드래그 순서 변경 가능)
// -----------------------------------------------------------------------------
class ActiveEmoticonList extends StatefulWidget {
  final String uid;
  const ActiveEmoticonList({Key? key, required this.uid}) : super(key: key);

  @override
  State<ActiveEmoticonList> createState() => _ActiveEmoticonListState();
}

class _ActiveEmoticonListState extends State<ActiveEmoticonList> {
  // 🌟 컬러 변수 추가
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('users_emoticon')
          .where('isVisible', isEqualTo: true)
          .orderBy('displayOrder', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('에러 발생: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: deepChocolate));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('사용 중인 이모티콘이 없습니다.', style: TextStyle(color: subTextColor)));
        }

        return ReorderableListView.builder(
          buildDefaultDragHandles: false, // 카드 전체가 드래그되는 것을 막음
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          onReorder: (oldIndex, newIndex) => _onReorder(docs, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final doc = docs[index];

            return EmoticonCardWidget(
              key: ValueKey(doc.id),
              uid: widget.uid,
              docId: doc.id,
              index: index,
              isAcitveTab: true,
            );
          },
        );
      },
    );
  }

  // 드래그 앤 드롭으로 순서 변경 시 DB displayOrder 일괄 업데이트
  Future<void> _onReorder(List<QueryDocumentSnapshot> docs, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final item = docs.removeAt(oldIndex);
    docs.insert(newIndex, item);

    final WriteBatch batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < docs.length; i++) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('users_emoticon')
          .doc(docs[i].id);

      batch.update(docRef, {
        'displayOrder': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}

// -----------------------------------------------------------------------------
// 2. [미사용] 탭 리스트
// -----------------------------------------------------------------------------
class InactiveEmoticonList extends StatelessWidget {
  final String uid;
  const InactiveEmoticonList({Key? key, required this.uid}) : super(key: key);

  // 🌟 컬러 변수 추가
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('users_emoticon')
          .where('isVisible', isEqualTo: false)
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('에러 발생: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: deepChocolate));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('미사용 처리된 이모티콘이 없습니다.', style: TextStyle(color: subTextColor)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final docId = docs[index].id;
            return EmoticonCardWidget(
              key: ValueKey(docId),
              uid: uid,
              docId: docId,
              isAcitveTab: false,
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 3. 개별 이모티콘 카드 위젯
// -----------------------------------------------------------------------------
class EmoticonCardWidget extends StatelessWidget {
  final String uid;
  final String docId;
  final int index;
  final bool isAcitveTab;

  const EmoticonCardWidget({
    Key? key,
    required this.uid,
    required this.docId,
    this.index = 0,
    required this.isAcitveTab,
  }) : super(key: key);

  // 🌟 컬러 변수 추가
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('emoticon').doc(docId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: deepChocolate.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              height: 70,
              child: Center(child: CircularProgressIndicator(color: deepChocolate, strokeWidth: 2)),
            ),
          );
        }

        String name = '알 수 없는 이모티콘';
        String imageUrl = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          name = data['name'] ?? '알 수 없는 이모티콘';
          imageUrl = data['imageUrl'] ?? data['thumbnailUrl'] ?? '';
        }

        Widget buildThumbnail(String path) {
          if (path.isEmpty) return Icon(Icons.face, color: deepChocolate.withOpacity(0.3));

          if (path.startsWith('assets/') && path.toLowerCase().endsWith('.svg')) {
            return SvgPicture.asset(path, fit: BoxFit.cover);
          } else if (path.startsWith('assets/')) {
            return Image.asset(
              path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: deepChocolate.withOpacity(0.3)),
            );
          } else {
            return Image.network(
              path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: deepChocolate.withOpacity(0.3)),
            );
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // 🌟 둥근 모서리
            border: Border.all(color: deepChocolate.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: deepChocolate.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4), // 🌟 부드러운 그림자 효과
              ),
            ],
          ),
          child: Row(
            children: [
              // 🖼️ 썸네일 영역
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: deepChocolate.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: buildThumbnail(imageUrl),
                ),
              ),
              const SizedBox(width: 16),

              // 📝 제목 및 상태 변경 버튼
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: deepChocolate),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // 🌟 둥근 알약(Pill) 형태의 버튼으로 디자인 변경
                    OutlinedButton(
                      onPressed: () {
                        if (isAcitveTab) {
                          _showToggleDialog(context, '이모티콘을 미사용 처리하시겠습니까?', false);
                        } else {
                          _showToggleDialog(context, '이모티콘을 사용 처리하시겠습니까?', true);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(60, 32),
                        side: BorderSide(color: isAcitveTab ? deepChocolate.withOpacity(0.3) : pointCoralRed),
                        backgroundColor: isAcitveTab ? Colors.white : pointCoralRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        foregroundColor: isAcitveTab ? deepChocolate : Colors.white,
                      ),
                      child: Text(
                        isAcitveTab ? '미사용' : '사용',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isAcitveTab ? deepChocolate : Colors.white
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 드래그 핸들 (순서 변경 마크)
              if (isAcitveTab)
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.transparent,
                    child: Icon(Icons.drag_indicator, color: deepChocolate.withOpacity(0.3)), // 🌟 아이콘을 조금 더 직관적인 핸들 형태로 변경
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 🌟 상태 변경 토글 팝업 (다이얼로그 디자인 통일)
  void _showToggleDialog(BuildContext context, String title, bool targetVisibility) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        content: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: deepChocolate)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🌟 모서리 둥글게
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: deepChocolate.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 🌟 둥근 버튼
                  ),
                  child: const Text('취소', style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('users_emoticon')
                          .doc(docId)
                          .update({
                        'isVisible': targetVisibility,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    } catch (e) {
                      debugPrint('DEBUG: DB 업데이트 실패 에러 -> $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pointCoralRed, // 🌟 코랄 레드로 포인트
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}