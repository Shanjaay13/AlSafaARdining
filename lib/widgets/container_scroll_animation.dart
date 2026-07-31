import 'package:flutter/material.dart';

class ContainerScroll extends StatefulWidget {
  final Widget titleComponent;
  final Widget child;
  final ScrollController? scrollController;

  const ContainerScroll({
    Key? key,
    required this.titleComponent,
    required this.child,
    this.scrollController,
  }) : super(key: key);

  @override
  State<ContainerScroll> createState() => _ContainerScrollState();
}

class _ContainerScrollState extends State<ContainerScroll> {
  late ScrollController _scrollController;
  bool _createdOwnController = false;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _createdOwnController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.viewportDimension * 0.4;
    final currentOffset = _scrollController.offset.clamp(0.0, maxScroll);
    final progress = (currentOffset / maxScroll).clamp(0.0, 1.0);

    if (progress != _scrollProgress) {
      setState(() {
        _scrollProgress = progress;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_createdOwnController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3D Perspective Rotation from 20deg (0.35 rad) down to 0deg
    final double rotateX = (1.0 - _scrollProgress) * 0.30;
    final double scale = 0.90 + (_scrollProgress * 0.10);
    final double translateY = (1.0 - _scrollProgress) * -20.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Header Title Component with subtle upward translate
          Transform.translate(
            offset: Offset(0, translateY),
            child: widget.titleComponent,
          ),

          const SizedBox(height: 16),

          // 3D Perspectives Tilt Card
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015) // Perspective perspective depth
              ..rotateX(rotateX),
            alignment: Alignment.topCenter,
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF142A22),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.4), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 24,
                      spreadRadius: 4,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: const Color(0xFFD4A24C).withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
