import 'package:flutter/material.dart';
import '../core/constants.dart';

class ConfidenceBadge extends StatelessWidget {
  final double confidence; // 0.0 a 1.0

  const ConfidenceBadge({super.key, required this.confidence});

  Color get _color {
    if (confidence >= AgroConfig.yoloHighConf) return AgroColors.healthy;
    if (confidence >= AgroConfig.yoloMidConf)  return AgroColors.yellow;
    return AgroColors.orange;
  }

  Color get _bgColor => _color.withOpacity(0.15);

  String get _label => '${(confidence * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: AgroText.fontBody,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}