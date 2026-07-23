import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// UI 모델: displayOrder 필드 포함
class BadgeUIModel {
  final String id;
  final String name;
  final String imageUrl;
  final bool isEarned;
  final DateTime? earnedAt;
  final bool isSelected;
  final int? displayOrder; // 대표 뱃지 표시 순서 (1, 2, 3)

  final String conditionType;
  final num? requiredPercent;

  BadgeUIModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isEarned,
    this.earnedAt,
    this.isSelected = false,
    this.displayOrder,
    required this.conditionType,
    this.requiredPercent,
  });

  BadgeUIModel copyWith({
    bool? isSelected,
    int? displayOrder,
  }) {
    return BadgeUIModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      isEarned: isEarned,
      earnedAt: earnedAt,
      isSelected: isSelected ?? this.isSelected,
      displayOrder: displayOrder ?? this.displayOrder,
      conditionType: conditionType,
      requiredPercent: requiredPercent,
    );
  }
}

class BadgeMainScreen extends StatefulWidget {
  const BadgeMainScreen({Key? key}) : super(key: key);

  @override
  State<BadgeMainScreen> createState() => _BadgeMainScreenState();
}

class _BadgeMainScreenState extends State<BadgeMainScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<BadgeUIModel> _allBadges = [];

  // 상태 관리 변수
  String _selectedFilter = '전체';
  String _selectedSort = '최신순';
  bool _showOnlyMaster = false;

  // 대표 뱃지 편집 모드 상태 변수
  bool _isEditMode = false;
  List<String> _selectedBadgeIds = []; // 순서대로 관리되는 대표 뱃지 ID 리스트

  @override
  void initState() {
    super.initState();
    _fetchBadges();
  }

  Future<void> _fetchBadges() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      // final uid = "4TtOtuHtn4QPXEplNBKy5dAqueb2"; // 테스트 시 주석 해제

      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }

      final badgeSnapshot = await FirebaseFirestore.instance
          .collection('badge')
          .where('isActive', isEqualTo: true)
          .get();

      final userBadgeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('users_badge')
          .get();

      final userBadgeMap = {
        for (var doc in userBadgeSnapshot.docs)
          doc.data()['badgeId']: doc.data()
      };

      final List<BadgeUIModel> loadedBadges = badgeSnapshot.docs.map((doc) {
        final data = doc.data();
        final badgeId = doc.id;
        final isEarned = userBadgeMap.containsKey(badgeId);
        final userBadgeData = userBadgeMap[badgeId];

        return BadgeUIModel(
          id: badgeId,
          name: data['name'] ?? '이름없음',
          imageUrl: data['imageUrl'] ?? '',
          isEarned: isEarned,
          earnedAt: isEarned && userBadgeData!['earnedAt'] != null
              ? (userBadgeData['earnedAt'] as Timestamp).toDate()
              : null,
          isSelected: isEarned && userBadgeData!['isSelected'] == true,
          displayOrder: isEarned ? userBadgeData!['displayOrder'] as int? : null,
          conditionType: data['conditionType'] ?? '',
          requiredPercent: data['requiredPercent'] as num?,
        );
      }).where((badge) => badge.isEarned).toList();

      // 기존 DB에 저장되어 있던 대표 뱃지들의 순서를 복원합니다.
      final selectedBadges = loadedBadges
          .where((b) => b.isSelected && b.displayOrder != null)
          .toList();
      selectedBadges.sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));

      setState(() {
        _allBadges = loadedBadges;
        _selectedBadgeIds = selectedBadges.map((b) => b.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('🔴 에러 발생: $e');
      setState(() => _isLoading = false);
    }
  }

  // 뱃지 클릭 시 대표 뱃지 선택/해제 처리
  void _toggleBadgeSelection(String badgeId) {
    setState(() {
      if (_selectedBadgeIds.contains(badgeId)) {
        _selectedBadgeIds.remove(badgeId);
      } else {
        if (_selectedBadgeIds.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('대표 뱃지는 최대 3개까지만 선택할 수 있습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedBadgeIds.add(badgeId);
      }
    });
  }

  // 편집 취소 처리
  void _cancelEditMode() {
    setState(() {
      _isEditMode = false;
      // 기존 설정 상태로 복원
      final selectedBadges = _allBadges
          .where((b) => b.isSelected && b.displayOrder != null)
          .toList();
      selectedBadges.sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
      _selectedBadgeIds = selectedBadges.map((b) => b.id).toList();
    });
  }

  // Firestore에 대표 뱃지 일괄 저장 (WriteBatch)
  Future<void> _saveRepresentativeBadges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final userBadgesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('users_badge');

      final querySnapshot = await userBadgesRef.get();

      for (var doc in querySnapshot.docs) {
        final badgeId = doc.data()['badgeId'] as String?;
        if (badgeId != null) {
          final int index = _selectedBadgeIds.indexOf(badgeId);
          if (index != -1) {
            batch.update(doc.reference, {
              'isSelected': true,
              'displayOrder': index + 1,
            });
          } else {
            batch.update(doc.reference, {
              'isSelected': false,
              'displayOrder': null,
            });
          }
        }
      }

      await batch.commit();

      setState(() {
        _allBadges = _allBadges.map((badge) {
          final index = _selectedBadgeIds.indexOf(badge.id);
          if (index != -1) {
            return badge.copyWith(isSelected: true, displayOrder: index + 1);
          } else {
            return badge.copyWith(isSelected: false, displayOrder: null);
          }
        }).toList();
        _isEditMode = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('대표 뱃지가 성공적으로 저장되었습니다!')),
        );
      }
    } catch (e) {
      debugPrint('🔴 대표 뱃지 저장 실패: $e');
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<BadgeUIModel> displayedBadges = List.from(_allBadges);

    // [필터 1] 종류 필터
    if (_selectedFilter == '로드') {
      displayedBadges = displayedBadges.where((b) => b.conditionType == 'road_progress').toList();
    } else if (_selectedFilter == '스탬프') {
      displayedBadges = displayedBadges.where((b) =>
      b.conditionType == 'stamp_count' && b.id != 'badge_01' && !b.name.contains('얌얌스타터')
      ).toList();
    }

    // [필터 2] 마스터만 보기
    if (_showOnlyMaster) {
      displayedBadges = displayedBadges.where((b) => b.requiredPercent == 100).toList();
    }

    // [정렬] 최신순 / 이름순
    if (_selectedSort == '최신순') {
      displayedBadges.sort((a, b) {
        final aTime = a.earnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.earnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    } else if (_selectedSort == '이름순') {
      displayedBadges.sort((a, b) => a.name.compareTo(b.name));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '뱃지',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 상단 필터 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildFilterButton('전체', _selectedFilter == '전체', () => setState(() => _selectedFilter = '전체')),
                    const SizedBox(width: 6),
                    _buildFilterButton('로드', _selectedFilter == '로드', () => setState(() => _selectedFilter = '로드')),
                    const SizedBox(width: 6),
                    _buildFilterButton('스탬프', _selectedFilter == '스탬프', () => setState(() => _selectedFilter = '스탬프')),
                  ],
                ),
                Row(
                  children: [
                    _buildFilterButton('최신순', _selectedSort == '최신순', () => setState(() => _selectedSort = '최신순')),
                    const SizedBox(width: 6),
                    _buildFilterButton('이름순', _selectedSort == '이름순', () => setState(() => _selectedSort = '이름순')),
                  ],
                ),
              ],
            ),
          ),

          // 2. 마스터만 보기 체크박스 (온전히 영역 유지)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                Checkbox(
                  value: _showOnlyMaster,
                  activeColor: Colors.black,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyMaster = value ?? false;
                    });
                  },
                ),
                const Text('마스터만 보기', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '총 뱃지 ${displayedBadges.length} 개',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // 3. 뱃지 그리드 뷰
          Expanded(
            child: displayedBadges.isEmpty
                ? const Center(
              child: Text('해당하는 뱃지가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.8,
              ),
              itemCount: displayedBadges.length,
              itemBuilder: (context, index) {
                final badge = displayedBadges[index];
                return _buildBadgeItem(badge);
              },
            ),
          ),

          // 🌟 4. 하단 고정 대표 뱃지 설정 컨트롤 바
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [편집 모드 전용] 상단 선택된 뱃지 수 안내
                if (_isEditMode) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '대표 뱃지 선택 ',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          '(${_selectedBadgeIds.length}/3)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],

                // [버튼 영역] 일반 모드: 넓은 버튼 1개 / 편집 모드: 취소 & 저장 버튼 2개
                _isEditMode
                    ? Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _cancelEditMode,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 저장 버튼
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveRepresentativeBadges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Text(
                            '저장하기',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditMode = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '대표 뱃지 설정',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )
        ),
      ),
    );
  }

  // 개별 뱃지 아이템 (편집 모드 시 ①, ②, ③ 배지 표시)
  Widget _buildBadgeItem(BadgeUIModel badge) {
    final int selectedIndex = _selectedBadgeIds.indexOf(badge.id);
    final bool isSelectedInEdit = selectedIndex != -1;

    return GestureDetector(
      onTap: () {
        if (_isEditMode) {
          _toggleBadgeSelection(badge.id);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      badge.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      },
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                    ),
                  ),

                  // 편집 모드에서 선택 순서 동그라미 배지 표시 (①, ②, ③)
                  if (_isEditMode)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelectedInEdit ? Colors.black : Colors.white,
                          border: Border.all(
                            color: isSelectedInEdit ? Colors.black : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isSelectedInEdit ? '${selectedIndex + 1}' : '',
                            style: TextStyle(
                              color: isSelectedInEdit ? Colors.white : Colors.transparent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}