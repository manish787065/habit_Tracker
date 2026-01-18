import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class QuickAccessBar extends StatefulWidget {
  final Function(String) onCategorySelected;

  const QuickAccessBar({super.key, required this.onCategorySelected});

  @override
  State<QuickAccessBar> createState() => _QuickAccessBarState();
}

class _QuickAccessBarState extends State<QuickAccessBar> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // The actual logic selection
  
  // Clean Data
  final List<Map<String, dynamic>> _tabs = [
    {"label": "Pomodoro", "icon": Icons.timer_outlined, "color": Colors.orange},
    {"label": "Habits", "icon": Icons.check_circle_outline, "color": Colors.green},
    {"label": "Study", "icon": Icons.menu_book_rounded, "color": Colors.blue},
    {"label": "Awards", "icon": Icons.emoji_events_outlined, "color": Colors.purple},
    {"label": "Tasks", "icon": Icons.task_alt_rounded, "color": Colors.teal},
    {"label": "Reflect", "icon": Icons.edit_note_rounded, "color": Colors.pink},
  ];

  late AnimationController _animController;
  late Animation<double> _curveAnimation;
  double _currentCurvePosition = 0.0; // 0.0 to (tabs.length - 1).0

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 300)
    );
    _curveAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic)
    )..addListener(() {
      setState(() {
        _currentCurvePosition = _curveAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    // Animate the curve from old index to new index
    _curveAnimation = Tween<double>(
      begin: _currentCurvePosition, 
      end: index.toDouble()
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic));
    
    _animController.forward(from: 0.0);

    setState(() {
      _selectedIndex = index;
    });

    widget.onCategorySelected(_tabs[index]["label"] as String);
  }

  @override
  Widget build(BuildContext context) {
    // Fixed width for consistent curve logic
    final double itemWidth = MediaQuery.of(context).size.width / 4.8;
    final double totalWidth = itemWidth * _tabs.length;
    final double height = 125; // Increased space for Hump + Icon + Text

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: totalWidth,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. The Animated Curve Painter (Background Layer)
              CustomPaint(
                size: Size(totalWidth, height),
                painter: CurvePainter(
                  position: _currentCurvePosition,
                  itemWidth: itemWidth,
                  color: Theme.of(context).dividerColor.withOpacity(0.3), // The Line Color
                ),
              ),

              // 2. The Items (Foreground Layer)
              Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = index == _selectedIndex;
                  final item = _tabs[index];
                  return _buildTabItem(item, isSelected, index, itemWidth);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(Map<String, dynamic> item, bool isSelected, int index, double width) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(bottom: 40), // Increased to clear the 25px hump
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Scaled Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()..scale(isSelected ? 1.3 : 1.0),
              transformAlignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(10), // Touch target padding
                child: Icon(
                  item["icon"] as IconData,
                  color: isSelected 
                      ? (item["color"] as Color) // Active Color
                      : AppColors.textSecondary.withOpacity(0.7), // Inactive Color
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Bold Text
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? (item["color"] as Color) : AppColors.textSecondary,
                fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
              ),
              child: Text(item["label"] as String),
            ),
          ],
        ),
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  final double position; // 0.0, 1.0, 1.5, etc.
  final double itemWidth;
  final Color color;

  CurvePainter({
    required this.position,
    required this.itemWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Line Level Y (slightly above bottom to accommodate stroke)
    final double lineY = size.height - 15.0; 
    
    // Calculate precise center of the curve based on animation 'position'
    final double centerX = (position * itemWidth) + (itemWidth / 2);
    
    // Define Hump Shape dimensions
    final double humpWidth = itemWidth * 0.8; 
    final double humpHeight = 25.0; // How high it goes
    
    // Start of the line
    path.moveTo(0, lineY);
    
    // Draw line until the start of the bump
    double bumpStart = centerX - (humpWidth / 2);
    double bumpEnd = centerX + (humpWidth / 2);
    
    // Ensure we don't draw backwards if near edge (clamp)
    // Actually simple lineTo handles it.
    
    path.lineTo(bumpStart, lineY);
    
    // The "Instamart" Curve: A smooth rise that frames the item
    // It goes UP (-y) relative to lineY
    
    path.cubicTo(
      bumpStart + (humpWidth * 0.2), lineY, // CP1 (Ease in from flat)
      centerX - (humpWidth * 0.25), lineY - humpHeight, // CP2 (Rise to peak left)
      centerX, lineY - humpHeight, // Peak
    );
    
    path.cubicTo(
      centerX + (humpWidth * 0.25), lineY - humpHeight, // CP3 (Fall from peak right)
      bumpEnd - (humpWidth * 0.2), lineY, // CP4 (Ease out to flat)
      bumpEnd, lineY // End
    );
    
    // Finish the line
    path.lineTo(size.width, lineY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CurvePainter oldDelegate) {
    return oldDelegate.position != position || 
           oldDelegate.itemWidth != itemWidth;
  }
}
