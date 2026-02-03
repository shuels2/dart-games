import 'package:flutter/material.dart';

class TaggedInBorderWidget extends StatefulWidget {
  final Widget child;
  final bool isTaggedIn;
  final Color borderColor;
  final bool showBorderLine;

  const TaggedInBorderWidget({
    super.key,
    required this.child,
    required this.isTaggedIn,
    this.borderColor = const Color(0xFFFF007A), // Hot pink
    this.showBorderLine = true,
  });

  @override
  State<TaggedInBorderWidget> createState() => _TaggedInBorderWidgetState();
}

class _TaggedInBorderWidgetState extends State<TaggedInBorderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTaggedIn) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            border: widget.showBorderLine
                ? Border.all(
                    color: widget.borderColor.withOpacity(_animation.value),
                    width: 4.0,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withOpacity(_animation.value * 0.6),
                blurRadius: 16,
                spreadRadius: 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
