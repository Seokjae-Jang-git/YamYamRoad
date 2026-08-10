import 'package:flutter/material.dart';

class AiRecommendationBanner extends StatelessWidget {
  const AiRecommendationBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6DDD0), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFFE6DDD0).withAlpha(80),
          highlightColor: const Color(0xFFE6DDD0).withAlpha(30),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFF0E8DD),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      color: Color(0xFF4A3E3D),
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI 맞춤 추천 받기',
                    style: TextStyle(
                      color: Color(0xFF4A3E3D),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF8C7E7A),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
