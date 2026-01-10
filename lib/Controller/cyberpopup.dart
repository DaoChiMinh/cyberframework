import 'package:flutter/material.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum PopupPosition { top, center, bottom, fullScreen }

enum PopupAnimation { slide, fade, scale, slideAndFade, none }

// ============================================================================
// ✅ OPTIMIZED: CyberPopup - Performance & Memory Optimized
// ============================================================================

class CyberPopup {
  final BuildContext context;
  final Widget child;
  final PopupPosition position;
  final PopupAnimation animation;
  final bool barrierDismissible;
  final Color? barrierColor;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final BoxShadow? boxShadow;
  final Function(dynamic)? onClose;
  final Function()? onShow;
  final Duration transitionDuration;
  final bool isScrollControlled;

  // ✅ OPTIMIZED: Static const default values
  static const EdgeInsets _defaultMargin = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets _defaultBottomPadding = EdgeInsets.all(20);
  static const BorderRadius _defaultBorderRadius = BorderRadius.all(
    Radius.circular(12),
  );
  static const BorderRadius _defaultBottomSheetRadius = BorderRadius.vertical(
    top: Radius.circular(20),
  );
  static const BoxShadow _defaultBoxShadow = BoxShadow(
    color: Color(0x33000000), // ✅ Const color instead of withValues
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  // ✅ OPTIMIZED: Cached values (initialized in constructor)
  late final Alignment _alignment;
  late final BoxDecoration _containerDecoration;
  late final BoxDecoration _bottomSheetDecoration;
  late final Widget _cachedDialogContent;
  late final Widget _cachedBottomSheetContent;
  late final Widget _cachedFullScreenContent;
  late final Offset _slideBegin;

  // ✅ OPTIMIZED: Animation caching
  Animation<double>? _scaleAnimation;
  Animation<Offset>? _slideAnimation;
  CurvedAnimation? _curvedAnimation;
  CurvedAnimation? _slideCurvedAnimation;
  bool _animationsInitialized = false;

  CyberPopup({
    required this.context,
    required this.child,
    this.position = PopupPosition.center,
    this.animation = PopupAnimation.slideAndFade,
    this.barrierDismissible = true,
    this.barrierColor,
    this.margin,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.onClose,
    this.onShow,
    this.transitionDuration = const Duration(milliseconds: 100),
    this.isScrollControlled = true,
  }) {
    // ✅ Initialize all cached values in constructor
    _initializeCachedValues();
  }

  /// ✅ OPTIMIZED: Initialize all cached values once
  void _initializeCachedValues() {
    // Cache alignment
    _alignment = _calculateAlignment();

    // Cache slide begin offset
    _slideBegin = _calculateSlideBegin();

    // Cache container decoration
    _containerDecoration = BoxDecoration(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: borderRadius ?? _defaultBorderRadius,
      boxShadow: boxShadow != null
          ? [boxShadow!]
          : backgroundColor != null && backgroundColor != Colors.transparent
          ? [_defaultBoxShadow]
          : null,
    );

    // Cache bottom sheet decoration
    _bottomSheetDecoration = BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: borderRadius ?? _defaultBottomSheetRadius,
      boxShadow: boxShadow != null ? [boxShadow!] : null,
    );

    // ✅ Pre-build content widgets
    _cachedDialogContent = _buildContent();
    _cachedBottomSheetContent = _buildBottomSheetContent();
    _cachedFullScreenContent = _buildFullScreenContent();
  }

  /// ✅ Calculate alignment once
  Alignment _calculateAlignment() {
    switch (position) {
      case PopupPosition.top:
        return Alignment.topCenter;
      case PopupPosition.center:
        return Alignment.center;
      case PopupPosition.bottom:
        return Alignment.bottomCenter;
      case PopupPosition.fullScreen:
        return Alignment.center;
    }
  }

  /// ✅ Calculate slide begin offset once
  Offset _calculateSlideBegin() {
    switch (position) {
      case PopupPosition.top:
        return const Offset(0, -1);
      case PopupPosition.bottom:
        return const Offset(0, 1);
      default:
        return const Offset(0, 0.3);
    }
  }

  // ========================================================================
  // PUBLIC METHODS
  // ========================================================================

  /// Show popup với kết quả trả về
  Future<T?> show<T>() async {
    onShow?.call();

    if (position == PopupPosition.bottom) {
      return await _showAsBottomSheet<T>();
    } else if (position == PopupPosition.fullScreen) {
      return await _showAsFullScreen<T>();
    } else {
      return await _showAsDialog<T>();
    }
  }

  /// Show as bottom sheet
  Future<T?> showBotton<T>() async {
    onShow?.call();
    return await _showAsBottomSheet<T>();
  }

  /// Show as full screen
  Future<T?> showFullScreen<T>() async {
    onShow?.call();
    return await _showAsFullScreen<T>();
  }

  /// Helper method để đóng popup từ bên trong
  static void close<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  // ========================================================================
  // ✅ OPTIMIZED: SHOW METHODS
  // ========================================================================

  Future<T?> _showAsDialog<T>() async {
    final result = await showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _cachedDialogContent; // ✅ Use cached content
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(animation, child);
      },
    );

    onClose?.call(result);
    return result;
  }

  Future<T?> _showAsBottomSheet<T>() async {
    final result = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor,
      isDismissible: barrierDismissible,
      builder: (context) => _BottomSheetWrapper(
        child: _cachedBottomSheetContent, // ✅ Use cached content
      ),
    );

    onClose?.call(result);
    return result;
  }

  Future<T?> _showAsFullScreen<T>() async {
    final result = await Navigator.of(context).push<T>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor ?? Colors.black54,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _cachedFullScreenContent; // ✅ Use cached content
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    onClose?.call(result);
    return result;
  }

  // ========================================================================
  // ✅ OPTIMIZED: BUILD METHODS (Cached)
  // ========================================================================

  Widget _buildContent() {
    return SafeArea(
      child: Align(
        alignment: _alignment, // ✅ Cached alignment
        child: Container(
          width: width,
          height: height,
          margin: margin ?? _defaultMargin,
          padding: padding,
          decoration: _containerDecoration, // ✅ Cached decoration
          child: child, // ✅ No Material wrapper
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent() {
    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: padding ?? _defaultBottomPadding,
      decoration: _bottomSheetDecoration, // ✅ Cached decoration
      child: child, // ✅ No Material wrapper
    );
  }

  Widget _buildFullScreenContent() {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      body: SafeArea(child: child),
    );
  }

  // ========================================================================
  // ✅ OPTIMIZED: ANIMATION METHODS
  // ========================================================================

  /// ✅ OPTIMIZED: Initialize animations ONCE
  void _initializeAnimations(Animation<double> animation) {
    if (_animationsInitialized) return;
    _animationsInitialized = true;

    // Create curved animation for scale
    _curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    // Create scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(_curvedAnimation!);

    // Create curved animation for slide
    _slideCurvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    // Create slide animation
    _slideAnimation = Tween<Offset>(
      begin: _slideBegin, // ✅ Use cached offset
      end: Offset.zero,
    ).animate(_slideCurvedAnimation!);
  }

  /// ✅ OPTIMIZED: Build transition using cached animations
  Widget _buildTransition(Animation<double> animation, Widget child) {
    // ✅ Initialize animations once
    _initializeAnimations(animation);

    switch (this.animation) {
      case PopupAnimation.slide:
        return SlideTransition(
          position: _slideAnimation!, // ✅ Cached animation
          child: child,
        );

      case PopupAnimation.fade:
        return FadeTransition(opacity: animation, child: child);

      case PopupAnimation.scale:
        return ScaleTransition(
          scale: _scaleAnimation!, // ✅ Cached animation
          child: FadeTransition(opacity: animation, child: child),
        );

      case PopupAnimation.slideAndFade:
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: _slideAnimation!, // ✅ Cached animation
            child: child,
          ),
        );

      case PopupAnimation.none:
        return child;
    }
  }
}

// ============================================================================
// ✅ OPTIMIZED: Bottom Sheet Keyboard Wrapper
// ============================================================================

/// Wrapper for bottom sheet with smooth keyboard animation
class _BottomSheetWrapper extends StatelessWidget {
  final Widget child;

  const _BottomSheetWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: child,
    );
  }
}
