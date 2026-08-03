import 'package:flutter/material.dart';

import '../models/point_models.dart';
import '../logic/point_usage_calculator.dart';
import 'point_shop_common.dart';

abstract final class PointBalanceColors {
  static const deepChocolate = Color(0xFF4A3225);
  static const pointCoralRed = Color(0xFFFF6B57);
  static const subBrown = Color(0xFF7A6B63);
  static const creamPanel = Color(0xFFFFF5EC);
  static const surfaceMuted = Color(0xFFF8F3ED);
  static const cardBorder = Color(0xFFEFEBE4);
  static const success = Color(0xFF3C8D68);
}

class PointBalanceHeader extends StatelessWidget {
  const PointBalanceHeader({
    super.key,
    required this.balance,
    required this.isLoading,
  });

  final PointBalance? balance;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Text(
        '포인트 조회 중',
        style: TextStyle(
          color: PointBalanceColors.subBrown,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final currentBalance = balance;
    if (currentBalance == null) {
      return const Text(
        '잔액 확인 불가',
        style: TextStyle(
          color: PointBalanceColors.subBrown,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${formatPointNumber(currentBalance.totalPoint)} P',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PointBalanceColors.pointCoralRed,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '무료 ${formatPointNumber(currentBalance.freePoint)} · '
            '유료 ${formatPointNumber(currentBalance.paidPoint)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PointBalanceColors.subBrown,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class PointUsagePanel extends StatelessWidget {
  const PointUsagePanel({super.key, required this.usage});

  final PointUsageCalculation usage;

  @override
  Widget build(BuildContext context) {
    return _PointSummaryPanel(
      backgroundColor: PointBalanceColors.surfaceMuted,
      rows: [
        PointAmountRow(
          label: '사용 포인트',
          value:
              '- ${formatPointNumber(usage.usedFreePoint + usage.usedPaidPoint)} P',
          emphasized: true,
        ),
        PointAmountRow(
          label: '무료 사용',
          value: '${formatPointNumber(usage.usedFreePoint)} P',
        ),
        PointAmountRow(
          label: '유료 사용',
          value: '${formatPointNumber(usage.usedPaidPoint)} P',
        ),
      ],
    );
  }
}

class PointBalancePanel extends StatelessWidget {
  const PointBalancePanel({
    super.key,
    required this.title,
    required this.freePoint,
    required this.paidPoint,
    this.highlighted = false,
  });

  final String title;
  final int freePoint;
  final int paidPoint;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return _PointSummaryPanel(
      backgroundColor: highlighted
          ? PointBalanceColors.creamPanel
          : PointBalanceColors.surfaceMuted,
      borderColor: highlighted
          ? const Color(0xFFFFD9CE)
          : PointBalanceColors.cardBorder,
      rows: [
        PointAmountRow(
          label: title,
          value: '${formatPointNumber(freePoint + paidPoint)} P',
          valueColor: highlighted
              ? PointBalanceColors.pointCoralRed
              : PointBalanceColors.deepChocolate,
          emphasized: true,
        ),
        PointAmountRow(label: '무료', value: '${formatPointNumber(freePoint)} P'),
        PointAmountRow(label: '유료', value: '${formatPointNumber(paidPoint)} P'),
      ],
    );
  }
}

class PointAmountRow extends StatelessWidget {
  const PointAmountRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = PointBalanceColors.deepChocolate,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final fontWeight = emphasized ? FontWeight.w700 : FontWeight.w500;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized
                  ? PointBalanceColors.deepChocolate
                  : PointBalanceColors.subBrown,
              fontSize: emphasized ? 13 : 12,
              fontWeight: fontWeight,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: emphasized ? 14 : 12,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );
  }
}

class _PointSummaryPanel extends StatelessWidget {
  const _PointSummaryPanel({
    required this.backgroundColor,
    required this.rows,
    this.borderColor = PointBalanceColors.cardBorder,
  });

  final Color backgroundColor;
  final Color borderColor;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const SizedBox(height: 5),
            rows[index],
          ],
        ],
      ),
    );
  }
}
