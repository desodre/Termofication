import 'package:flutter/material.dart';
import 'package:termofication_app/core/theme/app_colors.dart';

class BuildInModeCard extends StatefulWidget {
  const BuildInModeCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.themeColor,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color themeColor;

  @override
  State<BuildInModeCard> createState() => _BuildInModeCardState();
}

class _BuildInModeCardState extends State<BuildInModeCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            // Premium custom under construction feedback
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.construction_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'O modo ${widget.label} ainda está em construção! Fique ligado.',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF222225),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(
                    width: 320,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.themeColor.withValues(
                            alpha: _isHovered ? 0.25 : 0.15,
                          ),
                          widget.themeColor.withValues(
                            alpha: _isHovered ? 0.12 : 0.05,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isHovered
                            ? widget.themeColor.withValues(alpha: 0.6)
                            : widget.themeColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.themeColor.withValues(
                            alpha: _isHovered ? 0.18 : 0.05,
                          ),
                          blurRadius: _isHovered ? 20 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.themeColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.themeColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textWhite.withValues(alpha: 0.7),
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: widget.themeColor.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGray.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.lock_clock_outlined,
                          color: widget.themeColor.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  
                  // Diagonal under construction tape/banner in top-right corner
                  Positioned(
                    top: 10,
                    right: -25,
                    child: Transform.rotate(
                      angle: 0.785398, // 45 degrees in radians
                      child: Container(
                        width: 100,
                        height: 20,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: ConstructionTapePainter(),
                          child: const Center(
                            child: Text(
                              'BREVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(0.5, 0.5),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConstructionTapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF59E0B) // Amber 500
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final stripePaint = Paint()
      ..color = const Color(0xFF1E293B) // Slate 800
      ..style = PaintingStyle.fill;

    const double stripeWidth = 6.0;
    const double spacing = 10.0;

    for (double x = -size.height; x < size.width + size.height; x += stripeWidth + spacing) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripeWidth, 0)
        ..lineTo(x + stripeWidth - size.height, size.height)
        ..lineTo(x - size.height, size.height)
        ..close();
      canvas.drawPath(path, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}