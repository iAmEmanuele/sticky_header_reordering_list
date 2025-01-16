import 'package:flutter/material.dart';

class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size?> onChange;

  const MeasureSize({
    super.key,
    required this.child,
    required this.onChange,
  });

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final newSize = context.size;
          if (_oldSize != newSize) {
            _oldSize = newSize;
            widget.onChange(newSize);
          }
        });

        return widget.child;
      },
    );
  }
}
