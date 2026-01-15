import 'package:hive_flutter/hive_flutter.dart';

class HiveHelper {
  static const String userBox = 'userBox';
  static const String habitsBox = 'habitsBox';
  static const String settingsBox = 'settingsBox';
  static const String todoBox = 'todoBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(userBox);
    await Hive.openBox(habitsBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(todoBox);
  }

  static Box get user => Hive.box(userBox);
  static Box get habits => Hive.box(habitsBox);
  static Box get settings => Hive.box(settingsBox);
  static Box get todo => Hive.box(todoBox);
}
