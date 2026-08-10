import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OwnedGifticonDetailPage extends StatefulWidget {
  const OwnedGifticonDetailPage({
    super.key,
    required this.userId,
    required this.purchaseId,
    required this.gifticonId,
    required this.stockId,
    required this.brandName,
    required this.productName,
    required this.thumbnailUrl,
    required this.requiredPoint,
    required this.purchasedAt,
    required this.usedAt,
  });

  final String userId;
  final String purchaseId;
  final String gifticonId;
  final String stockId;
  final String brandName;
  final String productName;
  final String thumbnailUrl;
  final int requiredPoint;
  final DateTime? purchasedAt;
  final DateTime? usedAt;

  @override
  State<OwnedGifticonDetailPage> createState() =>
      _OwnedGifticonDetailPageState();
}

class _OwnedGifticonDetailPageState extends State<OwnedGifticonDetailPage> {
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);
  static const Color cardBorder = Color(0xFFEFEBE4);

  late Future<_OwnedGifticonStock> _stockFuture;

  @override
  void initState() {
    super.initState();
    _stockFuture = _loadOwnedStock();
  }

  Future<_OwnedGifticonStock> _loadOwnedStock() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('gifticon_stock')
        .doc(widget.stockId)
        .get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      throw const _GifticonDetailException('발급된 기프티콘 정보를 찾을 수 없습니다.');
    }
    if (data['assignedUserId'] != widget.userId ||
        data['purchaseId'] != widget.purchaseId ||
        data['gifticonId'] != widget.gifticonId) {
      throw const _GifticonDetailException('이 기프티콘의 소유 정보를 확인할 수 없습니다.');
    }

    final couponImagePath = (data['couponImagePath'] as String? ?? '').trim();
    if (couponImagePath.isEmpty) {
      throw const _GifticonDetailException('바코드가 포함된 기프티콘 이미지가 없습니다.');
    }

    final imageUrl = await _resolveImageUrl(couponImagePath);
    return _OwnedGifticonStock(
      imageUrl: imageUrl,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Future<String> _resolveImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Future.value(imagePath);
    }
    if (imagePath.startsWith('gs://')) {
      return FirebaseStorage.instance.refFromURL(imagePath).getDownloadURL();
    }
    return FirebaseStorage.instance.ref(imagePath).getDownloadURL();
  }

  void _retry() {
    setState(() => _stockFuture = _loadOwnedStock());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        backgroundColor: creamyIvory,
        foregroundColor: deepChocolate,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '기프티콘 상세',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<_OwnedGifticonStock>(
        future: _stockFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: pointCoralRed),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            final message = snapshot.error is _GifticonDetailException
                ? (snapshot.error! as _GifticonDetailException).message
                : '기프티콘 이미지를 불러오지 못했습니다.';
            return _GifticonLoadError(message: message, onRetry: _retry);
          }

          return _buildDetails(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildDetails(_OwnedGifticonStock stock) {
    final isUsed = widget.usedAt != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                _ProductThumbnail(imageUrl: widget.thumbnailUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.brandName,
                        style: const TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.productName,
                        style: const TextStyle(
                          color: deepChocolate,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${NumberFormat('#,###').format(widget.requiredPoint)} P',
                        style: const TextStyle(
                          color: pointCoralRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _UsageStatusBadge(isUsed: isUsed),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                const Text(
                  '매장에서 아래 바코드 이미지를 보여주세요',
                  style: TextStyle(
                    color: deepChocolate,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: Colors.white,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.network(
                        stock.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        semanticLabel: '${widget.productName} 바코드 기프티콘',
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            height: 360,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: pointCoralRed,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            height: 260,
                            child: Center(
                              child: Text(
                                '기프티콘 이미지를 표시할 수 없습니다.',
                                style: TextStyle(color: subTextColor),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GifticonInfoRow(
            label: '구매일시',
            value: _formatDate(widget.purchasedAt),
          ),
          const SizedBox(height: 8),
          _GifticonInfoRow(
            label: '유효기간',
            value: _formatDate(stock.expiresAt, dateOnly: true),
          ),
          if (isUsed) ...[
            const SizedBox(height: 8),
            _GifticonInfoRow(
              label: '사용일시',
              value: _formatDate(widget.usedAt),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? dateTime, {bool dateOnly = false}) {
    if (dateTime == null) return '-';
    return DateFormat(dateOnly ? 'yyyy. MM. dd' : 'yyyy. MM. dd HH:mm')
        .format(dateTime);
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 72,
        child: imageUrl.isEmpty
            ? const ColoredBox(
                color: Color(0xFFF6F2ED),
                child: Icon(
                  Icons.card_giftcard_outlined,
                  color: _OwnedGifticonDetailPageState.subTextColor,
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(
                      color: Color(0xFFF6F2ED),
                      child: Icon(
                        Icons.card_giftcard_outlined,
                        color: _OwnedGifticonDetailPageState.subTextColor,
                      ),
                    ),
              ),
      ),
    );
  }
}

class _UsageStatusBadge extends StatelessWidget {
  const _UsageStatusBadge({required this.isUsed});

  final bool isUsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isUsed ? const Color(0xFFF2F0ED) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUsed
              ? Colors.transparent
              : _OwnedGifticonDetailPageState.pointCoralRed,
        ),
      ),
      child: Text(
        isUsed ? '사용완료' : '미사용',
        style: TextStyle(
          color: isUsed
              ? _OwnedGifticonDetailPageState.subTextColor
              : _OwnedGifticonDetailPageState.pointCoralRed,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _GifticonInfoRow extends StatelessWidget {
  const _GifticonInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _OwnedGifticonDetailPageState.cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: _OwnedGifticonDetailPageState.subTextColor,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _OwnedGifticonDetailPageState.deepChocolate,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GifticonLoadError extends StatelessWidget {
  const _GifticonLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: _OwnedGifticonDetailPageState.subTextColor,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _OwnedGifticonDetailPageState.subTextColor,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _OwnedGifticonDetailPageState.pointCoralRed,
              ),
              child: const Text('다시 불러오기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnedGifticonStock {
  const _OwnedGifticonStock({required this.imageUrl, required this.expiresAt});

  final String imageUrl;
  final DateTime? expiresAt;
}

class _GifticonDetailException implements Exception {
  const _GifticonDetailException(this.message);

  final String message;
}
