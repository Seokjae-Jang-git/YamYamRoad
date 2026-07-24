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
  String _selectedFilter = '전체'; // 전체, 미사용, 사용완료
  String _selectedSort = '구매 최신순'; // 구매 최신순, 사용 최신순, 이름순

  @override
  Widget build(BuildContext context) {
    if (UserData.uid == null || UserData.uid!.isEmpty) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterAndSortBar(),
        Expanded(
          child: _buildGifticonList(),
        ),
      ],
    );
  }

  // 🎛️ 필터 및 정렬 바 UI
  Widget _buildFilterAndSortBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 상태 필터 (전체 / 미사용 / 사용완료)
          Row(
            children: ['전체', '미사용', '사용완료'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // 오른쪽: 정렬 버튼 (최신순 팝업 메뉴 / 이름순)
          Row(
            children: [
              _buildDateSortDropdown(),
              const SizedBox(width: 8),
              _buildSortButton('이름순'),
            ],
          ),
        ],
      ),
    );
  }

  // 📅 최신순 드롭다운 메뉴 (구매 / 사용)
  Widget _buildDateSortDropdown() {
    final isDateSort = _selectedSort.contains('최신순');

    return PopupMenuButton<String>(
      onSelected: (value) => setState(() => _selectedSort = value),
      offset: const Offset(0, 30),
      itemBuilder: (context) => [
        const PopupMenuItem(value: '구매 최신순', child: Text('구매 최신순', style: TextStyle(fontSize: 13))),
        const PopupMenuItem(value: '사용 최신순', child: Text('사용 최신순', style: TextStyle(fontSize: 13))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDateSort ? Colors.black : Colors.white,
          border: Border.all(color: isDateSort ? Colors.black : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              '최신순',
              style: TextStyle(
                fontSize: 12,
                color: isDateSort ? Colors.white : Colors.black87,
                fontWeight: isDateSort ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: isDateSort ? Colors.white : Colors.black87),
          ],
        ),
      ),
    );
  }

  // 🔤 일반 정렬 버튼 (이름순)
  Widget _buildSortButton(String sortName) {
    final isSelected = _selectedSort == sortName;
    return InkWell(
      onTap: () => setState(() => _selectedSort = sortName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          sortName,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
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
          return Center(child: Text('에러 발생:\n${snapshot.error}', textAlign: TextAlign.center));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
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
          return const Center(child: Text('기프티콘 내역이 없습니다.', style: TextStyle(color: Colors.grey)));
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

// 🎁 개별 기프티콘 카드 위젯
class GifticonItemCard extends StatelessWidget {
  final DocumentSnapshot purchaseDoc;

  const GifticonItemCard({Key? key, required this.purchaseDoc}) : super(key: key);

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
        final String imageUrl = gifticonData['imageUrl'] ?? ''; // DB 필드명에 맞춰 수정 필요

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4), // 플랫한 느낌의 둥근 모서리
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ 썸네일 영역
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                )
                    : const Icon(Icons.image_not_supported, color: Colors.grey),
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
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ),
                        // 상태 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: isUsed ? Colors.grey.shade300 : Colors.black),
                            color: isUsed ? Colors.grey.shade100 : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isUsed ? '사용완료' : '미사용',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUsed ? Colors.grey.shade500 : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${NumberFormat('#,###').format(requiredPoint)}P',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('구매: ${_formatDate(createdAt)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text('사용: ${_formatDate(usedAt)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
      height: 120,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}