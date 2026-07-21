import 'package:flutter/material.dart';
import 'package:portone_flutter/v2/model/entity/currency.dart';
import 'package:portone_flutter/v2/model/entity/payment_pay_method.dart';
import 'package:portone_flutter/v2/model/request/payment_request.dart';
import 'package:portone_flutter/v2/model/response/payment_response.dart';
import 'package:portone_flutter/v2/portone_payment.dart';

import '../logic/portone_point_payment_api_client.dart';

class PortoneCheckoutResult {
  const PortoneCheckoutResult.success({required this.paymentId})
    : errorMessage = null;

  const PortoneCheckoutResult.failure({
    required this.paymentId,
    required this.errorMessage,
  });

  final String paymentId;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null;
}

class PortonePaymentScreen extends StatelessWidget {
  const PortonePaymentScreen({
    super.key,
    required this.userId,
    required this.preparation,
  });

  static const String _appScheme = 'yamyamroad';

  final String userId;
  final PortonePaymentPreparation preparation;

  @override
  Widget build(BuildContext context) {
    return PortonePayment(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '포인트 결제',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      initialChild: const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      ),
      data: PaymentRequest(
        storeId: preparation.storeId,
        channelKey: preparation.channelKey,
        paymentId: preparation.paymentId,
        orderName: preparation.orderName,
        totalAmount: preparation.totalAmount,
        currency: Currency.KRW,
        payMethod: PaymentPayMethod.CARD,
        appScheme: _appScheme,
        customData: {
          'userId': userId,
          'pointPackageId': preparation.pointPackageId,
        },
      ),
      callback: (PaymentResponse response) {
        if (!context.mounted) return;
        final errorMessage = response.message?.trim();
        if (response.code != null ||
            (errorMessage != null && errorMessage.isNotEmpty)) {
          Navigator.of(context).pop(
            PortoneCheckoutResult.failure(
              paymentId: preparation.paymentId,
              errorMessage: errorMessage?.isNotEmpty == true
                  ? errorMessage!
                  : '결제가 취소되었거나 실패했습니다.',
            ),
          );
          return;
        }

        Navigator.of(
          context,
        ).pop(PortoneCheckoutResult.success(paymentId: response.paymentId));
      },
    );
  }
}
