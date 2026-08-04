import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../common/user_data.dart'; // 경로에 맞게 수정해주세요.

class GifticonTab extends StatefulWidget {
  const GifticonTab({Key? key}) : super(key: key);

  @override
  State<GifticonTab> createState() => _GifticonTabState();
}

class _GifticonTabState extends State<GifticonTab> {
  // 🌟 얌얌로드 공식 컬러 팔레트
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  String _selectedFilter = '전체'; // 전체, 미사용, 사용완료
  String _selectedSort = '구매 최신순'; // 구매 최신순, 사용 최신순, 이름순

  @override
  Widget build(BuildContext context) {
    if (UserData.uid == null || UserData.uid!.isEmpty) {
      return const Center(child: Text('로그인이 필요합니다.', style: TextStyle(color: deepChocolate)));
    }

    return Container(
      color: creamyIvory, // 🌟 전체 배경색 적용
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterAndSortBar(),
          Expanded(
            child: _buildGifticonList(),
          ),
        ],
      ),
    );
  }

  // 🎛️ 필터 및 정렬 바 UI (알약 형태 칩 디자인 적용)
  Widget _buildFilterAndSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 상태 필터
          Row(
            children: ['전체', '미사용', '사용완료'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildPillButton(
                  text: filter,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedFilter = filter),
                ),
              );
            }).toList(),
          ),

          // 오른쪽: 정렬 버튼
          Row(
            children: [
              _buildDateSortDropdown(),
              const SizedBox(width: 8),
              _buildPillButton(
                text: '이름순',
                isSelected: _selectedSort == '이름순',
                onTap: () => setState(() => _selectedSort = '이름순'),
                isSort: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🌟 공통 알약(Pill) 버튼 헬퍼 위젯
  Widget _buildPillButton({required String text, required bool isSelected, required VoidCallback onTap, bool isSort = false}) {
    Color activeColor = isSort ? deepChocolate : pointCoralRed;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          border: Border.all(color: isSelected ? activeColor : deepChocolate.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : subTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 📅 최신순 드롭다운 메뉴 (구매 / 사용) 디자인 적용
  Widget _buildDateSortDropdown() {
    final isDateSort = _selectedSort.contains('최신순');

    return PopupMenuButton<String>(
      onSelected: (value) => setState(() => _selectedSort = value),
      offset: const Offset(0, 40),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(value: '구매 최신순', child: Text('구매 최신순', style: TextStyle(fontSize: 13, color: deepChocolate, fontWeight: _selectedSort == '구매 최신순' ? FontWeight.bold : FontWeight.normal))),
        PopupMenuItem(value: '사용 최신순', child: Text('사용 최신순', style: TextStyle(fontSize: 13, color: deepChocolate, fontWeight: _selectedSort == '사용 최신순' ? FontWeight.bold : FontWeight.normal))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDateSort ? deepChocolate : Colors.white,
          border: Border.all(color: isDateSort ? deepChocolate : deepChocolate.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              '최신순',
              style: TextStyle(
                fontSize: 12,
                color: isDateSort ? Colors.white : subTextColor,
                fontWeight: isDateSort ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: isDateSort ? Colors.white : subTextColor),
          ],
        ),
      ),
    );
  }

  // 📋 기프티콘 목록 리스트
  Widget _buildGifticonList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(UserData.uid)
          .collection('users_purchase')
          .where('purchaseType', isEqualTo: 'gifticon')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('에러 발생:\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: pointCoralRed)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: deepChocolate));
        }

        List<DocumentSnapshot> docs = snapshot.data?.docs ?? [];

        // 1. Client-side 필터링 (미사용 / 사용완료)
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bool isUsed = data['usedAt'] != null;

          if (_selectedFilter == '미사용' && isUsed) return false;
          if (_selectedFilter == '사용완료' && !isUsed) return false;
          return true;
        }).toList();

        // 2. Client-side 정렬 (구매일 / 사용일 기준)
        if (_selectedSort == '구매 최신순') {
          docs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            return (bTime?.seconds ?? 0).compareTo(aTime?.seconds ?? 0);
          });
        } else if (_selectedSort == '사용 최신순') {
          docs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['usedAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['usedAt'] as Timestamp?;
            return (bTime?.seconds ?? 0).compareTo(aTime?.seconds ?? 0);
          });
        }

        if (docs.isEmpty) {
          return const Center(child: Text('기프티콘 내역이 없습니다.', style: TextStyle(color: subTextColor)));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return GifticonItemCard(purchaseDoc: docs[index]);
          },
        );
      },
    );
  }
}

// 🎁 개별 기프티콘 카드 위젯 (카드 디자인 적용)
class GifticonItemCard extends StatelessWidget {
  final DocumentSnapshot purchaseDoc;

  const GifticonItemCard({Key? key, required this.purchaseDoc}) : super(key: key);

  // 🌟 색상 상수 재정의
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    return DateFormat('yyyy. MM. dd HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final purchaseData = purchaseDoc.data() as Map<String, dynamic>;
    final String itemId = purchaseData['itemId'] ?? '';
    final Timestamp? createdAt = purchaseData['createdAt'];
    final Timestamp? usedAt = purchaseData['usedAt'];
    final bool isUsed = usedAt != null;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('gifticon').doc(itemId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonCard(); // 로딩 중 UI
        }

        final gifticonData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final String brandName = gifticonData['brandName'] ?? '브랜드 정보 없음';
        final String name = gifticonData['name'] ?? '상품명 없음';
        final num requiredPoint = gifticonData['requiredPoint'] ?? 0;
        final String imageUrl = gifticonData['imageUrl'] ?? '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // 🌟 둥근 모서리 16
            border: Border.all(color: deepChocolate.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: deepChocolate.withOpacity(0.04), // 🌟 부드러운 그림자
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ 썸네일 영역
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: deepChocolate.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(12), // 🌟 이미지 모서리 12
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                )
                    : Icon(Icons.image_not_supported, color: deepChocolate.withOpacity(0.3)),
              ),
              const SizedBox(width: 16),

              // 📝 상세 정보 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            brandName,
                            style: const TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // 🌟 상태 뱃지 리디자인 (미사용은 코랄 레드, 사용완료는 옅은 색)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUsed ? Colors.grey.shade100 : Colors.white,
                            border: Border.all(color: isUsed ? Colors.transparent : pointCoralRed),
                            borderRadius: BorderRadius.circular(20), // 🌟 알약 형태 뱃지
                          ),
                          child: Text(
                            isUsed ? '사용완료' : '미사용',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUsed ? subTextColor : pointCoralRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start, // 여러 줄일 때 정렬 맞춤
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: deepChocolate, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${NumberFormat('#,###').format(requiredPoint)} P',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: pointCoralRed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('구매: ${_formatDate(createdAt)}', style: const TextStyle(fontSize: 12, color: subTextColor)),
                    const SizedBox(height: 2),
                    Text('사용: ${_formatDate(usedAt)}', style: const TextStyle(fontSize: 12, color: subTextColor)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 로딩 시 보여줄 스켈레톤 UI
  Widget _buildSkeletonCard() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: deepChocolate.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(16)
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: deepChocolate)),
    );
  }
}