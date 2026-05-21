import 'package:flutter/material.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final double shakeOffset;
  final Duration duration;
  final dynamic trigger;

  const ShakeWidget({
    super.key,
    required this.child,
    this.shakeOffset = 10.0,
    this.duration = const Duration(milliseconds: 500),
    this.trigger,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger != null) {
      _shake();
    }
  }

  void _shake() {
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: -1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: -1.0, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: -0.6), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: -0.6, end: 0.4), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.4, end: 0.0), weight: 15),
    ]).animate(_controller);

    return AnimatedBuilder(
      animation: offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(offsetAnimation.value * widget.shakeOffset, 0),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
