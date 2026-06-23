import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LiquidNavBar extends StatelessWidget {
  const LiquidNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavBarItemData(Icons.person_rounded, "Profile"),
      _NavBarItemData(Icons.home_rounded, "Home"),
      _NavBarItemData(Icons.history_rounded, "History"),
    ];

    return Container(
      padding: const EdgeInsets.only(left: 50, right: 50, bottom: 28),
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: 72,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final itemWidth = barWidth / items.length;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: selectedIndex.toDouble()),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  builder: (context, animValue, child) {
                    return CustomPaint(
                      size: Size(barWidth, 72),
                      painter: _LiquidNavPainter(animValue, items.length),
                    );
                  },
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  top: -12,
                  left: (selectedIndex * itemWidth) + (itemWidth / 2) - 26,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: AppTheme.policeBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33142C5C),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        )
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (index) {
                    final bool isActive = index == selectedIndex;

                    return GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: itemWidth,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutBack,
                              transform: Matrix4.translationValues(
                                0,
                                isActive ? -24 : 0,
                                0,
                              ),
                              child: Icon(
                                items[index].icon,
                                color: isActive ? Colors.white : const Color.fromARGB(255, 8, 90, 172),
                                size: 24,
                              ),
                            ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              bottom: isActive ? 12 : -15,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 250),
                                opacity: isActive ? 1.0 : 0.0,
                                child: Text(
                                  items[index].label,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.policeBlue,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavBarItemData {
  final IconData icon;
  final String label;
  _NavBarItemData(this.icon, this.label);
}

class _LiquidNavPainter extends CustomPainter {
  final double animValue;
  final int count;
  _LiquidNavPainter(this.animValue, this.count);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 255, 253, 253).withOpacity(0.78)
      ..style = PaintingStyle.fill;

    final path = Path();
    final double itemWidth = size.width / count;
    final double centerX = (animValue * itemWidth) + (itemWidth / 2);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(40),
    );
    path.addRRect(rrect);

    final cutoutPath = Path()
      ..moveTo(0, 0)
      ..lineTo(centerX - 50, 0)
      ..cubicTo(centerX - 30, 0, centerX - 25, 45, centerX, 45)
      ..cubicTo(centerX + 22, 45, centerX + 30, 0, centerX + 50, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final finalPath = Path.combine(PathOperation.intersect, path, cutoutPath);

    canvas.drawShadow(finalPath, Colors.black.withOpacity(0.06), 8.0, true);
    canvas.drawPath(finalPath, paint);

    final borderPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(finalPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidNavPainter oldDelegate) {
    return oldDelegate.animValue != animValue;
  }
}