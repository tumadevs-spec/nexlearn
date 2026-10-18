import 'package:flutter/material.dart';

class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({
    super.key,
    required this.onChanged,
    this.size = 130,
  });

  /// Reports a vector with length 0..1. Offset.zero means released.
  final ValueChanged<Offset> onChanged;
  final double size;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  static const _knob = 52.0;
  Offset _delta = Offset.zero;

  void _update(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final max = widget.size / 2 - _knob / 2;
    var delta = local - center;
    if (delta.distance > max) delta = delta / delta.distance * max;
    setState(() => _delta = delta);
    widget.onChanged(delta / max);
  }

  void _release() {
    setState(() => _delta = Offset.zero);
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _release(),
      onPanCancel: _release,
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                  width: 3,
                ),
              ),
            ),
            Positioned(
              left: s / 2 - _knob / 2 + _delta.dx,
              top: s / 2 - _knob / 2 + _delta.dy,
              child: Container(
                width: _knob,
                height: _knob,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF7C3AED),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x553B0764),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}