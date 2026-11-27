import 'package:flutter/material.dart';

/// Paint-only feedback; the button retains its hit area, semantics and action.
class PressFeedback extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const PressFeedback({super.key, required this.child, this.enabled = true});
  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool pressed = false;
  void update(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context);
    final down = pressed && widget.enabled && !quiet;
    final duration = Duration(
      milliseconds: quiet
          ? 0
          : down
          ? 80
          : 120,
    );
    return Listener(
      onPointerDown: widget.enabled ? (_) => update(true) : null,
      onPointerUp: (_) => update(false),
      onPointerCancel: (_) => update(false),
      child: AnimatedSlide(
        offset: Offset(0, down ? .025 : 0),
        duration: duration,
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: down ? .985 : 1,
          duration: duration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
