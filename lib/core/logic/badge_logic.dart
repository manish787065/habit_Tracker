import 'package:flutter/material.dart';

enum BadgeType {
  none,
  streakMaintainer,
  focused,
  warrior,
  godLevel,
}

class BadgeInfo {
  final String name;
  final IconData icon;
  final Color color;

  BadgeInfo(this.name, this.icon, this.color);
}

class BadgeLogic {
  static BadgeType getBadgeForHours(double hours) {
    if (hours >= 7) return BadgeType.godLevel;
    if (hours >= 5) return BadgeType.warrior;
    if (hours >= 3) return BadgeType.focused;
    if (hours >= 1) return BadgeType.streakMaintainer;
    return BadgeType.none;
  }

  static BadgeInfo getInfo(BadgeType type) {
    switch (type) {
      case BadgeType.godLevel:
        return BadgeInfo("God Level", Icons.bolt, Colors.amber);
      case BadgeType.warrior:
        return BadgeInfo("Warrior", Icons.shield, Colors.redAccent);
      case BadgeType.focused:
        return BadgeInfo("Focused", Icons.visibility, Colors.purple);
      case BadgeType.streakMaintainer:
        return BadgeInfo("Streak Maintainer", Icons.local_fire_department, Colors.orange);
      case BadgeType.none:
        return BadgeInfo("No Badge", Icons.hourglass_empty, Colors.grey);
    }
  }
}
