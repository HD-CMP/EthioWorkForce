import 'package:flutter/material.dart';

enum FeedbackType {
  success,
  error,
  warning,
  info,
}

class VisualFeedbackOverlay {
  static OverlayEntry? _currentOverlay;

  static void showFlashFeedback(
    BuildContext context, {
    required FeedbackType type,
    required String message,
    String? subtitle,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    removeCurrentOverlay();

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _FlashFeedbackWidget(
        type: type,
        message: message,
        subtitle: subtitle,
        duration: duration,
        onDismiss: removeCurrentOverlay,
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }

  static void removeCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _FlashFeedbackWidget extends StatefulWidget {
  final FeedbackType type;
  final String message;
  final String? subtitle;
  final Duration duration;
  final VoidCallback onDismiss;

  const _FlashFeedbackWidget({
    required this.type,
    required this.message,
    this.subtitle,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_FlashFeedbackWidget> createState() => _FlashFeedbackWidgetState();
}

class _FlashFeedbackWidgetState extends State<_FlashFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case FeedbackType.success:
        return const Color(0xFF4CAF50);
      case FeedbackType.error:
        return const Color(0xFFF44336);
      case FeedbackType.warning:
        return const Color(0xFFFF9800);
      case FeedbackType.info:
        return const Color(0xFF2196F3);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case FeedbackType.success:
        return Icons.check_circle;
      case FeedbackType.error:
        return Icons.error;
      case FeedbackType.warning:
        return Icons.warning;
      case FeedbackType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getBackgroundColor().withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FullScreenFlashAnimation extends StatefulWidget {
  final FeedbackType type;
  final VoidCallback? onComplete;

  const FullScreenFlashAnimation({
    Key? key,
    required this.type,
    this.onComplete,
  }) : super(key: key);

  @override
  State<FullScreenFlashAnimation> createState() => _FullScreenFlashAnimationState();

  static void show(BuildContext context, FeedbackType type) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) => FullScreenFlashAnimation(
        type: type,
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _FullScreenFlashAnimationState extends State<FullScreenFlashAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.6),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.0),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getFlashColor() {
    switch (widget.type) {
      case FeedbackType.success:
        return const Color(0xFF4CAF50);
      case FeedbackType.error:
        return const Color(0xFFF44336);
      case FeedbackType.warning:
        return const Color(0xFFFF9800);
      case FeedbackType.info:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: _getFlashColor(),
      ),
    );
  }
}
