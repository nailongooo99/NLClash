import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/widgets/liquid/liquid.dart';
import 'package:flutter/material.dart';

class CommonChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ChipType type;
  final Widget? avatar;
  final TextStyle? labelStyle;

  const CommonChip({
    super.key,
    required this.label,
    this.labelStyle,
    this.onPressed,
    this.avatar,
    this.type = ChipType.action,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidChip(
      label: label,
      avatar: avatar,
      labelStyle: labelStyle,
      onPressed: onPressed,
      onDeleted: type == ChipType.delete ? onPressed ?? () {} : null,
    );
  }
}
