import 'package:flutter/material.dart';

enum PopupPosition { top, center, bottom, fullScreen }

enum PopupAnimation { slide, fade, scale, slideAndFade, none }

class CyberPopup {
  final BuildContext context;
  final Widget child; // Widget tùy chỉnh hoàn toàn
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
    this.transitionDuration = const Duration(milliseconds: 300),
    this.isScrollControlled = true,
  });

  // Show với kết quả trả về
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

  Future<T?> showBotton<T>() async {
    onShow?.call();

    return await _showAsBottomSheet<T>();
  }

  Future<T?> showFullScreen<T>() async {
    onShow?.call();

    return await _showAsFullScreen<T>();
  }

  Future<T?> _showAsDialog<T>() async {
    final result = await showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _buildContent();
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor,
      isDismissible: barrierDismissible,
      //builder: (context) => _buildBottomSheetContent(),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // ✅ Important
        ),
        child: _buildBottomSheetContent(),
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
          return _buildFullScreenContent();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    onClose?.call(result);
    return result;
  }

  Widget _buildContent() {
    return SafeArea(
      child: Align(
        alignment: _getAlignment(),
        child: Container(
          width: width,
          height: height,
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 20),
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            boxShadow: boxShadow != null
                ? [boxShadow!]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(color: Colors.transparent, child: child),
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent() {
    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius:
            borderRadius ??
            const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: boxShadow != null ? [boxShadow!] : null,
      ),
      child: Material(color: Colors.transparent, child: child),
    );
  }

  Widget _buildFullScreenContent() {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      body: SafeArea(child: child),
    );
  }

  Alignment _getAlignment() {
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

  Widget _buildTransition(Animation<double> animation, Widget child) {
    switch (this.animation) {
      case PopupAnimation.slide:
        return _slideTransition(animation, child);
      case PopupAnimation.fade:
        return FadeTransition(opacity: animation, child: child);
      case PopupAnimation.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      case PopupAnimation.slideAndFade:
        return FadeTransition(
          opacity: animation,
          child: _slideTransition(animation, child),
        );
      case PopupAnimation.none:
        return child;
    }
  }

  Widget _slideTransition(Animation<double> animation, Widget child) {
    Offset begin;
    switch (position) {
      case PopupPosition.top:
        begin = const Offset(0, -1);
        break;
      case PopupPosition.bottom:
        begin = const Offset(0, 1);
        break;
      default:
        begin = const Offset(0, 0.3);
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    );
  }

  // Helper method để đóng popup từ bên trong
  static void close<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }
}
