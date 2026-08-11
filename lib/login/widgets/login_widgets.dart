import 'package:flutter/material.dart';

// 🌟 로고 패인터 (도넛 + 지도핀 모티프)
class PinLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint pinPaint = Paint()..color = const Color(0xFFE8845A);
    final Paint holePaint = Paint()..color = Colors.white;
    final Paint sprinkleDark = Paint()..color = const Color(0xFF3E2723);
    final Paint sprinklePink = Paint()..color = const Color(0xFFF4A6C0);

    final double w = size.width;
    final double h = size.height;

    final Path pinPath = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..cubicTo(w * 0.85, h * 0.05, w * 0.95, h * 0.35, w * 0.95, h * 0.5)
      ..cubicTo(w * 0.95, h * 0.75, w * 0.6, h * 0.95, w * 0.5, h * 1.0)
      ..cubicTo(w * 0.4, h * 0.95, w * 0.05, h * 0.75, w * 0.05, h * 0.5)
      ..cubicTo(w * 0.05, h * 0.35, w * 0.15, h * 0.05, w * 0.5, h * 0.05)
      ..close();

    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.42), w * 0.16, holePaint);

    canvas.drawCircle(Offset(w * 0.38, h * 0.3), w * 0.035, sprinkleDark);
    canvas.drawCircle(Offset(w * 0.62, h * 0.28), w * 0.035, sprinklePink);
    canvas.drawCircle(Offset(w * 0.68, h * 0.45), w * 0.035, sprinkleDark);
    canvas.drawCircle(Offset(w * 0.33, h * 0.5), w * 0.035, sprinklePink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 🌟 카카오 말풍선 아이콘
class KakaoIcon extends StatelessWidget {
  final double size;
  const KakaoIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KakaoBubblePainter()),
    );
  }
}

class _KakaoBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF3C1E1E);
    final w = size.width;
    final h = size.height;

    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h * 0.78),
      Radius.circular(h * 0.4),
    );
    canvas.drawRRect(bubble, paint);

    final tail = Path()
      ..moveTo(w * 0.22, h * 0.72)
      ..lineTo(w * 0.12, h * 0.98)
      ..lineTo(w * 0.38, h * 0.74)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 🌟 네이버 아이콘
class NaverIcon extends StatelessWidget {
  final double size;
  const NaverIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.78,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// 🌟 구글 아이콘
class GoogleIcon extends StatelessWidget {
  final double size;
  const GoogleIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;

    final paintBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    canvas.drawArc(rect, _deg(-40), _deg(100), false, paintBase..color = const Color(0xFF4285F4));
    canvas.drawArc(rect, _deg(60), _deg(70), false, paintBase..color = const Color(0xFF34A853));
    canvas.drawArc(rect, _deg(130), _deg(80), false, paintBase..color = const Color(0xFFFBBC05));
    canvas.drawArc(rect, _deg(210), _deg(110), false, paintBase..color = const Color(0xFFEA4335));

    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.42, w * 0.46, h * 0.18),
      barPaint,
    );
  }

  double _deg(double degrees) => degrees * 3.1415926535 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 🌟 소셜 로그인 공통 버튼 위젯
class SocialButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final IconData? icon;
  final Widget? customIcon;
  final bool loading;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.loading,
    required this.onPressed,
    this.icon,
    this.customIcon,
    this.borderColor,
  }) : assert(icon != null || customIcon != null, 'icon 또는 customIcon 중 하나는 필요합니다');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? Colors.transparent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon ?? Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}