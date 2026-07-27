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
  String _selectedSubTab = '사용'; // '사용' 또는 '미사용'

  @override
  Widget build(BuildContext context) {
    final String uid = UserData.uid ?? '';
    if (uid.isEmpty) {
      return const Center(child: Text('로그인 정보가 없습니다.'));
    }

    return Column(
      children: [
        _buildSubTabBar(),
        Expanded(
          child: _selectedSubTab == '사용'
              ? ActiveEmoticonList(uid: uid)
              : InactiveEmoticonList(uid: uid),
        ),
      ],
    );
  }

  // 상단 서브 탭 (사용 / 미사용)
  Widget _buildSubTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSubTabButton('사용'),
          const SizedBox(width: 40),
          _buildSubTabButton('미사용'),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String title) {
    final bool isSelected = _selectedSubTab == title;
    return InkWell(
      onTap: () => setState(() => _selectedSubTab = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          border: isSelected ? const Border(bottom: BorderSide(color: Colors.black, width: 2)) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey,
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
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('사용 중인 이모티콘이 없습니다.', style: TextStyle(color: Colors.grey)));
        }

        return ReorderableListView.builder(
          buildDefaultDragHandles: false, // 🌟 핵심 1: 카드 전체가 드래그되는 것을 막음 (버튼 터치 살리기)
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          onReorder: (oldIndex, newIndex) => _onReorder(docs, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final doc = docs[index];

            return EmoticonCardWidget(
              key: ValueKey(doc.id),
              uid: widget.uid,
              docId: doc.id,
              index: index, // 🌟 핵심 2: 순서 인덱스를 위젯으로 전달
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
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('미사용 처리된 이모티콘이 없습니다.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final docId = docs[index].id;
            return EmoticonCardWidget(
              key: ValueKey(docId),
              uid: uid,
              docId: docId, // 🌟 emoticonId -> docId 로 변경!
              isAcitveTab: false,
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 3. 개별 이모티콘 카드 위젯 (docId로 emoticon 컬렉션 바로 조회)
// -----------------------------------------------------------------------------
class EmoticonCardWidget extends StatelessWidget {
  final String uid;
  final String docId; // users_emoticon 문서 ID (= emoticon 컬렉션 문서 ID)
  final int index;
  final bool isAcitveTab;

  const EmoticonCardWidget({
    Key? key,
    required this.uid,
    required this.docId,
    this.index = 0,
    required this.isAcitveTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🌟 docId를 통해 최상위 emoticon 컬렉션을 바로 조회합니다.
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('emoticon').doc(docId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const SizedBox(
              height: 70,
              child: Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
            ),
          );
        }

        String name = '알 수 없는 이모티콘';
        String imageUrl = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          name = data['name'] ?? '알 수 없는 이모티콘';
          // imageUrl 또는 thumbnail/imageUrl 필드명 모두 대응
          imageUrl = data['imageUrl'] ?? data['thumbnailUrl'] ?? '';
        }

        // 🌟 이미지 렌더링 분기 처리 함수
        Widget buildThumbnail(String path) {
          if (path.isEmpty) return const Icon(Icons.face, color: Colors.grey);

          // 1. 로컬 SVG 에셋인 경우
          if (path.startsWith('assets/') && path.toLowerCase().endsWith('.svg')) {
            return SvgPicture.asset(
              path,
              fit: BoxFit.cover,
            );
          }
          // 2. 일반 로컬 이미지(png, jpg 등) 에셋인 경우
          else if (path.startsWith('assets/')) {
            return Image.asset(
              path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
            );
          }
          // 3. 웹 서버 이미지 URL인 경우
          else {
            return Image.network(
              path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
            );
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // 🖼️ 썸네일 영역에 함수 적용
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8), // 간격 살짝 조정

                    // 🌟 터치 이벤트를 절대 뺏기지 않는 플러터 기본 버튼으로 교체!
                    OutlinedButton(
                      onPressed: () {
                        print('DEBUG: 미사용/사용 버튼 확실히 클릭됨!'); // 로그 확인용
                        if (isAcitveTab) {
                          _showToggleDialog(context, '이모티콘을 미사용 처리하시겠습니까?', false);
                        } else {
                          _showToggleDialog(context, '이모티콘을 사용 처리하시겠습니까?', true);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(60, 32), // 버튼 크기 지정
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        foregroundColor: Colors.black, // 클릭 시 물결 효과 색상
                      ),
                      child: Text(
                        isAcitveTab ? '미사용' : '사용',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              // 🌟 핵심 3: 우측 아이콘을 잡았을 때만 드래그가 작동하도록 리스너로 감싸기
              if (isAcitveTab)
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(8), // 터치하기 쉽게 영역 확보
                    color: Colors.transparent, // 투명 배경을 주어 터치 영역 활성화
                    child: Icon(Icons.menu, color: Colors.grey.shade400),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 상태 변경 토글 팝업
  void _showToggleDialog(BuildContext context, String title, bool targetVisibility) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('취소', style: TextStyle(color: Colors.black)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    print('DEBUG: 미사용 처리 시도 -> uid: $uid, docId: $docId, targetVisibility: $targetVisibility');

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
                      print('DEBUG: DB 업데이트 성공!');
                    } catch (e) {
                      print('DEBUG: DB 업데이트 실패 에러 -> $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('확인', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}