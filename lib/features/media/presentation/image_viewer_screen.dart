/// Fullscreen image viewer: Hero transition in from the chat bubble,
/// pinch-to-zoom via InteractiveViewer, and double-tap to zoom toward the
/// tap point (or back out if already zoomed).
library image_viewer_screen;

import 'dart:io';

import 'package:flutter/material.dart';

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.filePath,
    required this.heroTag,
  });

  final String filePath;
  final String heroTag;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        if (_animation != null) {
          _transformController.value = _animation!.value;
        }
      });
  }

  void _onDoubleTapDown(TapDownDetails details) => _doubleTapDetails = details;

  void _onDoubleTap() {
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final isZoomedIn = _transformController.value != Matrix4.identity();

    final Matrix4 end = isZoomedIn
        ? Matrix4.identity()
        : (Matrix4.identity()
          ..translate(-position.dx * 2, -position.dy * 2)
          ..scale(3.0));

    _animation = Matrix4Tween(begin: _transformController.value, end: end)
        .animate(CurveTween(curve: Curves.easeOut).animate(_animController));
    _animController.forward(from: 0);
  }

  @override
  void dispose() {
    _animController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onDoubleTapDown: _onDoubleTapDown,
        onDoubleTap: _onDoubleTap,
        child: Center(
          child: Hero(
            tag: widget.heroTag,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 1,
              maxScale: 5,
              child: Image.file(File(widget.filePath)),
            ),
          ),
        ),
      ),
    );
  }
}
