import 'package:flutter/material.dart';

enum SidebarNodeType { group, item }

class SidebarNode {
  final String id;
  final String title;
  final IconData icon;
  final SidebarNodeType type;
  final List<SidebarNode> children;

  /// الشاشة المرتبطة (للعناصر النهائية فقط)
  final dynamic screen; // استخدم dynamic لتجنب circular import مع AppScreen

  /// إن كانت null والعنصر نهائي -> يظهر كـ "قريباً" (disabled)
  final bool enabled;

  const SidebarNode({
    required this.id,
    required this.title,
    required this.icon,
    this.type = SidebarNodeType.item,
    this.children = const [],
    this.screen,
    this.enabled = true,
  });

  bool get isGroup => type == SidebarNodeType.group && children.isNotEmpty;
}
