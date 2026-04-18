import 'package:flutter/material.dart';

class ProtocolIcons {
  static final Map<String, IconData> _iconMap = {
    'layers': Icons.layers_outlined,
    'verified': Icons.verified_outlined,
    'diamond': Icons.diamond_outlined,
    'camera': Icons.camera_alt_outlined,
    'warning': Icons.warning_amber_rounded,
    'check_circle': Icons.check_circle_outline_rounded,
    'error': Icons.error_outline_rounded,
    'info': Icons.info_outline_rounded,
    'bolt': Icons.bolt_rounded,
    'history': Icons.history_rounded,
    'build': Icons.build_outlined,
    'visibility': Icons.visibility_outlined,
    'map': Icons.map_outlined,
  };

  static IconData get(String? name) {
    if (name == null || name.isEmpty) return Icons.help_outline;
    return _iconMap[name.toLowerCase()] ?? Icons.help_outline;
  }
}
