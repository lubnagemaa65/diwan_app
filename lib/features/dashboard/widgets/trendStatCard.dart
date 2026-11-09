import 'package:flutter/material.dart';

/// بطاقة مؤشر حديثة: تدرّج لوني خفيف، أيقونة دائرية، ورقم بيدخل بأنيميشن
/// بدل ما يظهر فجأة (TweenAnimationBuilder، بدون أي حزمة إضافية).
class TrendStatCard extends StatelessWidget {
  const TrendStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.numericValue,
    this.onTap,
  });

  final String title;

  /// النص الجاهز للعرض (مثال: "24 جهاز"، "3 أيام"). يُستخدم إذا لم يُمرَّر
  /// [numericValue]، أو كنص إضافي بعد الرقم المتحرك.
  final String value;

  /// إن مُرِّر، يُعرض كرقم صحيح يتحرك تصاعدياً عند أول ظهور للبطاقة.
  final int? numericValue;

  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.14),
                color.withValues(alpha: 0.04)
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 14),
              numericValue != null
                  ? TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: numericValue),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(
                        '$v',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
