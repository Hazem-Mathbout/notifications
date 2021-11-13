import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:notifications_two/home_screen.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'notifications_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // -------------- Hive ------------------- Start
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;
  await Hive.initFlutter(appDocPath);
  await Hive.openBox('notifications');
  // -------------- Hive ------------------- End

  // --------------WorkManager--------------Start

  await Workmanager().initialize(callBackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask("notifyPeriodicTask", "prayer",
      frequency: const Duration(days: 1));

  // --------------WorkManager--------------End

  runApp(
    ChangeNotifierProvider(
        create: (context) => NotificationsProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Notification Testing",
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
