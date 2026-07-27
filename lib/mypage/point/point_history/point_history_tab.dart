import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:yamyam_road/common/user_data.dart'; // UserData 경로에 맞게 필요시 수정해주세요.

class PointHistoryTab extends StatefulWidget {
  const PointHistoryTab({Key? key}) : super(key: key);

  @override
  State<PointHistoryTab> createState() => _PointHistoryTabState();
}

class _PointHistoryTabState extends State<PointHistoryTab> {
  final String uid = UserData.uid ?? '';

  // --- 필터 UI 선택 상태 변수 ---
  bool _isFilterExpanded = false;
  String _selectedPeriod = '1개월'; // 1개월, 3개월, 6개월, 12개월
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  String _selectedType = '전체'; // 전체, 충전, 사용
  String _selectedSort = '최신순'; // 최신순, 과거순

  // --- 실제 조회(적용)된 필터 상태 변수 ---
  DateTime _appliedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _appliedEndDate = DateTime.now();
  String _appliedType = '전체';
  String _appliedSort = '최신순';

  Stream<QuerySnapshot>? _transactionStream;

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  void _updateStream() {
    if (uid.isEmpty) return;
    _transactionStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users_point_transaction')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_appliedStartDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_appliedEndDate))
        .orderBy('createdAt', descending: _appliedSort == '최신순')
        .snapshots();
  }

  // 기간 버튼 클릭 처리
  void _onPeriodSelected(String period, int days) {
    setState(() {
      _selectedPeriod = period;
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days));
    });
  }

  // 초기화 버튼
  void _resetFilter() {
    setState(() {
      _selectedPeriod = '1개월';
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(const Duration(days: 30));
      _selectedType = '전체';
      _selectedSort = '최신순';
    });
  }

  // 조회 버튼
  void _applyFilter() {
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      _appliedType = _selectedType;
      _appliedSort = _selectedSort;
      _isFilterExpanded = false;

      _updateStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const Center(child: Text('로그인 정보가 없습니다.'));

    return Column(
      children: [
        _buildPointSummaryCard(uid),
        _buildFilterAccordion(),
        Expanded(
          child: _buildTransactionList(uid),
        ),
      ],
    );
  }

  // 상단 내 보유 포인트 요약 카드 (회색 영역 제거 및 1px 구분선 적용)
  Widget _buildPointSummaryCard(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        num parseToNum(dynamic value) {
          if (value == null) return 0;
          if (value is num) return value;
          if (value is String) return num.tryParse(value) ?? 0;
          return 0;
        }

        final num paidPoint = parseToNum(data?['paidPointBalance']);
        final num freePoint = parseToNum(data?['freePointBalance']);
        final num totalPoint = paidPoint + freePoint;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            // 🌟 회색 바(border width 8)를 없애고 연한 1px 실선으로 구분
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('현재 보유 포인트', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${NumberFormat('#,###').format(totalPoint)} 포인트', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('유료: ${NumberFormat('#,###').format(paidPoint)}포인트', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 8),
                  Text('무료: ${NumberFormat('#,###').format(freePoint)}포인트', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 와이어프레임 기반 필터 아코디언 UI
  Widget _buildFilterAccordion() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Column(
        children: [
          // 기본 요약 바 (토글 버튼)
          InkWell(
            onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text('$_appliedPeriodText / $_appliedType / $_appliedSort', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Icon(_isFilterExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),

          // 확장된 상세 필터 영역
          if (_isFilterExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildFilterSectionTitle('기간'),
                  Row(
                    children: [
                      _buildSelectButton('1개월', _selectedPeriod == '1개월', () => _onPeriodSelected('1개월', 30)),
                      const SizedBox(width: 8),
                      _buildSelectButton('3개월', _selectedPeriod == '3개월', () => _onPeriodSelected('3개월', 90)),
                      const SizedBox(width: 8),
                      _buildSelectButton('6개월', _selectedPeriod == '6개월', () => _onPeriodSelected('6개월', 180)),
                      const SizedBox(width: 8),
                      _buildSelectButton('12개월', _selectedPeriod == '12개월', () => _onPeriodSelected('12개월', 365)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildDateBox(_startDate)),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~')),
                      Expanded(child: _buildDateBox(_endDate)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildFilterSectionTitle('구분'),
                  Row(
                    children: [
                      _buildSelectButton('전체', _selectedType == '전체', () => setState(() => _selectedType = '전체')),
                      const SizedBox(width: 8),
                      _buildSelectButton('충전', _selectedType == '충전', () => setState(() => _selectedType = '충전')),
                      const SizedBox(width: 8),
                      _buildSelectButton('사용', _selectedType == '사용', () => setState(() => _selectedType = '사용')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildFilterSectionTitle('정렬'),
                  Row(
                    children: [
                      _buildSelectButton('최신순', _selectedSort == '최신순', () => setState(() => _selectedSort = '최신순')),
                      const SizedBox(width: 8),
                      _buildSelectButton('과거순', _selectedSort == '과거순', () => setState(() => _selectedSort = '과거순')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFilter,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('초기화', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('조회', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 거래 내역 리스트
  Widget _buildTransactionList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _transactionStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('데이터 로드 오류:\n${snapshot.error}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center));
        }

        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.black));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('포인트 거래 내역이 없습니다.', style: TextStyle(color: Colors.grey)));

        num parseToNum(dynamic value) {
          if (value == null) return 0;
          if (value is num) return value;
          if (value is String) return num.tryParse(value) ?? 0;
          return 0;
        }

        final docs = snapshot.data!.docs.where((doc) {
          final txData = doc.data() as Map<String, dynamic>;
          final num amount = parseToNum(txData['amount']);

          if (_appliedType == '충전' && amount <= 0) return false;
          if (_appliedType == '사용' && amount >= 0) return false;

          return true;
        }).toList();

        if (docs.isEmpty) return const Center(child: Text('조건에 맞는 내역이 없습니다.', style: TextStyle(color: Colors.grey)));

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
          itemBuilder: (context, index) {
            final txData = docs[index].data() as Map<String, dynamic>;
            return TransactionItemWidget(uid: uid, txData: txData);
          },
        );
      },
    );
  }

  // --- UI Helper 메서드들 ---
  String get _appliedPeriodText {
    int days = _appliedEndDate.difference(_appliedStartDate).inDays;
    if (days <= 31) return '1개월';
    if (days <= 92) return '3개월';
    if (days <= 184) return '6개월';
    if (days <= 366) return '12개월';
    return '직접입력';
  }

  Widget _buildFilterSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSelectButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(text, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildDateBox(DateTime date) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
      child: Text(DateFormat('yyyy.MM.dd').format(date), style: const TextStyle(fontSize: 13, color: Colors.black87)),
    );
  }
}

// 🌟 개별 거래 내역 아이템 위젯
class TransactionItemWidget extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> txData;

  const TransactionItemWidget({Key? key, required this.uid, required this.txData}) : super(key: key);

  @override
  State<TransactionItemWidget> createState() => _TransactionItemWidgetState();
}

class _TransactionItemWidgetState extends State<TransactionItemWidget> {
  bool _isExpanded = false;
  late Future<String> _titleFuture;

  @override
  void initState() {
    super.initState();
    _titleFuture = _fetchTransactionTitle(widget.uid, widget.txData);
  }

  @override
  void didUpdateWidget(TransactionItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.txData['refId'] != widget.txData['refId']) {
      _titleFuture = _fetchTransactionTitle(widget.uid, widget.txData);
    }
  }

  Future<String> _fetchTransactionTitle(String uid, Map<String, dynamic> txData) async {
    try {
      final String refType = txData['refType'] ?? '';
      final String? refId = txData['refId'];
      final String fallback = txData['source'] ?? '알 수 없는 내역';

      if (refId == null) return fallback;

      if (refType == 'purchase') {
        final purchaseDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('users_purchase')
            .doc(refId)
            .get();

        if (!purchaseDoc.exists) return fallback;
        final purchaseData = purchaseDoc.data()!;
        final String purchaseType = purchaseData['purchaseType'] ?? '';

        if (purchaseType == 'point_package') {
          return '포인트 충전';
        } else if (purchaseType == 'emoticon' || purchaseType == 'gifticon') {
          final String? itemId = purchaseData['itemId'];
          if (itemId == null) return fallback;

          final String targetCollection = purchaseType == 'emoticon' ? 'emoticon' : 'gifticon';
          final String prefix = purchaseType == 'emoticon' ? '이모티콘' : '기프티콘';

          final itemDoc = await FirebaseFirestore.instance.collection(targetCollection).doc(itemId).get();

          if (itemDoc.exists) {
            final String itemName = itemDoc.data()?['name'] ?? '알 수 없는 상품';
            return '$prefix - $itemName';
          }
          return '$prefix - 상품 정보 없음';
        }
      } else if (refType == 'stamp') {
        final stampDoc = await FirebaseFirestore.instance.collection('stamp').doc(refId).get();

        if (!stampDoc.exists) return fallback;
        final String? placeId = stampDoc.data()?['placeId'];

        if (placeId == null) return fallback;

        final placeDoc = await FirebaseFirestore.instance.collection('place').doc(placeId).get();
        if (placeDoc.exists) {
          final String placeName = placeDoc.data()?['name'] ?? '알 수 없는 업체';
          return '스탬프 - $placeName';
        }
        return '스탬프 - 업체 정보 없음';
      }

      return fallback;
    } catch (e) {
      return txData['source'] ?? '정보 불러오기 실패';
    }
  }

  @override
  Widget build(BuildContext context) {
    final txData = widget.txData;

    final Timestamp? timestamp = txData['createdAt'] as Timestamp?;
    final String dateStr = timestamp != null
        ? DateFormat('yyyy. MM. dd HH:mm').format(timestamp.toDate())
        : '-';

    // 🌟 타입 방어 파싱 함수
    num parseToNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    final num amount = parseToNum(txData['amount']);
    final bool isEarn = amount > 0;
    final String amountStr = '${isEarn ? '+' : '-'} ${NumberFormat('#,###').format(amount.abs())} 포인트';
    final Color amountColor = isEarn ? Colors.black : Colors.red;

    final num paidBalance = parseToNum(txData['paidPointBalanceAfter']);
    final num freeBalance = parseToNum(txData['freePointBalanceAfter']);

    final bool showPaymentDetails = txData['refType'] == 'purchase' && txData['refId'] != null && isEarn;

    return Column(
      children: [
        InkWell(
          onTap: showPaymentDetails ? () => setState(() => _isExpanded = !_isExpanded) : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _titleFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text(
                              '불러오는 중...',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey),
                            );
                          }
                          return Text(
                            snapshot.data ?? '알 수 없는 내역',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          amountStr,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: amountColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '유료: ${NumberFormat('#,###').format(paidBalance)} 포인트',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '무료: ${NumberFormat('#,###').format(freeBalance)} 포인트',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
                if (showPaymentDetails) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('결제내역 보기', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade600),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),

        // 결제 상세 아코디언 영역
        if (_isExpanded && showPaymentDetails)
          Container(
            width: double.infinity,
            color: const Color(0xFFF9F9F9),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.uid)
                  .collection('users_purchase')
                  .doc(txData['refId'])
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(color: Colors.black)));

                final purchaseData = snapshot.data!.data() as Map<String, dynamic>?;
                if (purchaseData == null) return const Text('결제 정보를 불러올 수 없습니다.', style: TextStyle(fontSize: 13));

                final paidAmount = parseToNum(purchaseData['paidAmount']);
                final paymentMethod = purchaseData['paymentMethod'] == 'cash' ? '신용카드' : '기타';
                final approvalNum = purchaseData['approvalNumber'] ?? "-";

                final Map<String, String> cardIssuerMap = {
                  'HYUNDAI_CARD': '현대',
                  'KOOKMIN_CARD': '국민',
                  'SAMSUNG_CARD': '삼성',
                  'SHINHAN_CARD': '신한',
                  'LOTTE_CARD': '롯데',
                  'HANA_CARD': '하나',
                  'BC_CARD': 'BC',
                  'NH_CARD': '농협',
                  'WOORI_CARD': '우리',
                  'KAKAOBANK_CARD': '카카오뱅크',
                  'TOSS_BANK_CARD': '토스뱅크',
                };

                final String rawCardIssuer = purchaseData['cardIssuer'] ?? '';
                final String cardName = cardIssuerMap[rawCardIssuer] ?? rawCardIssuer;
                final String maskedCardNumber = purchaseData['maskedCardNumber'] ?? '';

                String cardInfo = '정보 없음';
                if (maskedCardNumber.isNotEmpty) {
                  cardInfo = cardName.isNotEmpty ? '$cardName $maskedCardNumber' : maskedCardNumber;
                }

                return Column(
                  children: [
                    _buildDetailRow('결제 수단', paymentMethod),
                    const SizedBox(height: 12),
                    _buildDetailRow('카드번호', cardInfo),
                    const SizedBox(height: 12),
                    _buildDetailRow('거래일시', dateStr),
                    const SizedBox(height: 12),
                    _buildDetailRow('승인번호', approvalNum),
                    const SizedBox(height: 12),
                    _buildDetailRow('거래금액', '${NumberFormat('#,###').format(paidAmount)}원', isBold: true),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}