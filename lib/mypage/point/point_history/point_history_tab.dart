import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:yamyam_road/common/user_data.dart';

class PointHistoryTab extends StatefulWidget {
  // 🌟 부모로부터 스크롤 컨트롤러를 전달받음
  final ScrollController scrollController;

  const PointHistoryTab({Key? key, required this.scrollController}) : super(key: key);

  @override
  // 🌟 다시 프라이빗(private) 상태 클래스로 안전하게 변경
  State<PointHistoryTab> createState() => _PointHistoryTabState();
}

class _PointHistoryTabState extends State<PointHistoryTab> {
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  final String uid = UserData.uid ?? '';

  bool _isFilterExpanded = false;
  String _selectedPeriod = '1개월';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  String _selectedType = '전체';
  String _selectedSort = '최신순';

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

  // 🌟 당겨서 새로고침 메서드
  Future<void> _onRefresh() async {
    setState(() {
      _updateStream();
    });
    await Future.delayed(const Duration(milliseconds: 500));
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

  void _onPeriodSelected(String period, int days) {
    setState(() {
      _selectedPeriod = period;
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days));
    });
  }

  void _resetFilter() {
    setState(() {
      _selectedPeriod = '1개월';
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(const Duration(days: 30));
      _selectedType = '전체';
      _selectedSort = '최신순';
    });
  }

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
    if (uid.isEmpty) return const Center(child: Text('로그인 정보가 없습니다.', style: TextStyle(color: deepChocolate)));

    return Container(
      color: creamyIvory,
      child: Column(
        children: [
          _buildPointSummaryCard(uid),
          _buildFilterAccordion(),
          Expanded(
            child: _buildTransactionList(uid),
          ),
        ],
      ),
    );
  }

  Widget _buildPointSummaryCard(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: deepChocolate)));

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
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: deepChocolate.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: deepChocolate.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('현재 보유 포인트', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: deepChocolate)),
                  Text('${NumberFormat('#,###').format(totalPoint)} P', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: pointCoralRed)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('유료: ${NumberFormat('#,###').format(paidPoint)} P', style: const TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  Text('무료: ${NumberFormat('#,###').format(freePoint)} P', style: const TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterAccordion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: deepChocolate.withOpacity(0.1), width: 1)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 18, color: deepChocolate.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Text('$_appliedPeriodText / $_appliedType / $_appliedSort', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: deepChocolate)),
                  const Spacer(),
                  Icon(_isFilterExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: deepChocolate),
                ],
              ),
            ),
          ),

          if (_isFilterExpanded)
            Container(
              padding: const EdgeInsets.only(bottom: 20),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDateBox(_startDate)),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~', style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold))),
                      Expanded(child: _buildDateBox(_endDate)),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 20),

                  _buildFilterSectionTitle('정렬'),
                  Row(
                    children: [
                      _buildSelectButton('최신순', _selectedSort == '최신순', () => setState(() => _selectedSort = '최신순')),
                      const SizedBox(width: 8),
                      _buildSelectButton('과거순', _selectedSort == '과거순', () => setState(() => _selectedSort = '과거순')),
                      const Spacer(flex: 2),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFilter,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: deepChocolate.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('초기화', style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pointCoralRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('조회', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTransactionList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _transactionStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('데이터 로드 오류:\n${snapshot.error}', style: const TextStyle(color: pointCoralRed), textAlign: TextAlign.center));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: deepChocolate));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return RefreshIndicator(
            color: pointCoralRed,
            backgroundColor: Colors.white,
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: const Center(
                    child: Text('포인트 거래 내역이 없습니다.', style: TextStyle(color: subTextColor)),
                  ),
                ),
              ],
            ),
          );
        }

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

        if (docs.isEmpty) {
          return RefreshIndicator(
            color: pointCoralRed,
            backgroundColor: Colors.white,
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: const Center(
                    child: Text('조건에 맞는 내역이 없습니다.', style: TextStyle(color: subTextColor)),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: pointCoralRed,
          backgroundColor: Colors.white,
          onRefresh: _onRefresh,
          child: ListView.builder(
            // 🌟 부모로부터 받아온 컨트롤러를 리스트뷰에 연결
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final txData = docs[index].data() as Map<String, dynamic>;
              return TransactionItemWidget(uid: uid, txData: txData);
            },
          ),
        );
      },
    );
  }

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
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: deepChocolate)),
    );
  }

  Widget _buildSelectButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? deepChocolate : Colors.white,
            border: Border.all(color: isSelected ? deepChocolate : deepChocolate.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(text, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : subTextColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildDateBox(DateTime date) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: deepChocolate.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(8)
      ),
      child: Text(DateFormat('yyyy.MM.dd').format(date), style: const TextStyle(fontSize: 13, color: deepChocolate, fontWeight: FontWeight.w500)),
    );
  }
}

class TransactionItemWidget extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> txData;

  const TransactionItemWidget({Key? key, required this.uid, required this.txData}) : super(key: key);

  @override
  State<TransactionItemWidget> createState() => _TransactionItemWidgetState();
}

class _TransactionItemWidgetState extends State<TransactionItemWidget> {
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

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

    num parseToNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    final num amount = parseToNum(txData['amount']);
    final bool isEarn = amount > 0;
    final String amountStr = '${isEarn ? '+' : '-'} ${NumberFormat('#,###').format(amount.abs())} P';

    final Color amountColor = isEarn ? pointCoralRed : deepChocolate;

    final num paidBalance = parseToNum(txData['paidPointBalanceAfter']);
    final num freeBalance = parseToNum(txData['freePointBalanceAfter']);

    final bool showPaymentDetails = txData['refType'] == 'purchase' && txData['refId'] != null && isEarn;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: deepChocolate.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: deepChocolate.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: showPaymentDetails ? () => setState(() => _isExpanded = !_isExpanded) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: subTextColor)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _titleFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text(
                                '불러오는 중...',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: deepChocolate.withOpacity(0.5)),
                              );
                            }
                            return Text(
                              snapshot.data ?? '알 수 없는 내역',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: deepChocolate),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amountStr,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: amountColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '유료: ${NumberFormat('#,###').format(paidBalance)} P',
                            style: const TextStyle(fontSize: 11, color: subTextColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '무료: ${NumberFormat('#,###').format(freeBalance)} P',
                            style: const TextStyle(fontSize: 11, color: subTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (showPaymentDetails) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('결제내역 보기', style: TextStyle(fontSize: 12, color: deepChocolate.withOpacity(0.7), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: deepChocolate.withOpacity(0.7)),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),

          if (_isExpanded && showPaymentDetails)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: creamyIvory,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                border: Border(top: BorderSide(color: deepChocolate.withOpacity(0.05))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.uid)
                    .collection('users_purchase')
                    .doc(txData['refId'])
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(color: deepChocolate)));

                  final purchaseData = snapshot.data!.data() as Map<String, dynamic>?;
                  if (purchaseData == null) return const Text('결제 정보를 불러올 수 없습니다.', style: TextStyle(fontSize: 13, color: subTextColor));

                  final paidAmount = parseToNum(purchaseData['paidAmount']);
                  final paymentMethod = purchaseData['paymentMethod'] == 'cash' ? '신용카드' : '기타';
                  final approvalNum = purchaseData['approvalNumber'] ?? "-";

                  final Map<String, String> cardIssuerMap = {
                    'HYUNDAI_CARD': '현대', 'KOOKMIN_CARD': '국민', 'SAMSUNG_CARD': '삼성',
                    'SHINHAN_CARD': '신한', 'LOTTE_CARD': '롯데', 'HANA_CARD': '하나',
                    'BC_CARD': 'BC', 'NH_CARD': '농협', 'WOORI_CARD': '우리',
                    'KAKAOBANK_CARD': '카카오뱅크', 'TOSS_BANK_CARD': '토스뱅크',
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
                      const SizedBox(height: 8),
                      _buildDetailRow('카드번호', cardInfo),
                      const SizedBox(height: 8),
                      _buildDetailRow('거래일시', dateStr),
                      const SizedBox(height: 8),
                      _buildDetailRow('승인번호', approvalNum),
                      const SizedBox(height: 8),
                      _buildDetailRow('거래금액', '${NumberFormat('#,###').format(paidAmount)}원', isBold: true),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? pointCoralRed : deepChocolate,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}