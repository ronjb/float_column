import 'package:flutter/material.dart';

class AnimatedRect extends StatefulWidget {
  const AnimatedRect({
    super.key,
    this.color = Colors.blue,
    this.size = const Size(200, 100),
    this.altSize,
  });

  final Color color;
  final Size size;
  final Size? altSize;

  @override
  // ignore: library_private_types_in_public_api
  _AnimatedRectState createState() => _AnimatedRectState();
}

class _AnimatedRectState extends State<AnimatedRect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _heightAnimation;
  late Size altSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    altSize = widget.altSize ?? widget.size;
    _widthAnimation =
        Tween<double>(begin: widget.size.width, end: altSize.width)
            .animate(_controller);
    _heightAnimation =
        Tween<double>(begin: widget.size.height, end: altSize.height)
            .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: _heightAnimation.value,
          color: widget.color,
        );
      },
    );
  }
}
