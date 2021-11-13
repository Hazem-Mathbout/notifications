// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notifications_two/prayer_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'prayer_model.dart';
import 'main.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void callBackDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName!));
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;
  await Hive.initFlutter(appDocPath);
  await Hive.openBox('notifications');
  var i = Hive.box("notifications");
  List listNotifi = i.values.toList();

  //=================//
  var initializationSettingsAndroid =
      const AndroidInitializationSettings('solidarieta_logo');
  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {});
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
  });
  //=======================//

  Future scheduleAlarm(int id, String title, String body, String prayer) async {
    DateTime scheduledNotificationDateTime = selectAlarmDateTime(prayer);
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'alarm_notif', 'alarm_notif',
        icon: 'solidarieta_logo',
        playSound: true,
        sound: RawResourceAndroidNotificationSound('a_long_cold_sting.wav'),
        largeIcon: DrawableResourceAndroidBitmap('solidarieta_logo'),
        importance: Importance.max);

    var iOSPlatformChannelSpecifics = const IOSNotificationDetails(
        sound: 'a_long_cold_sting.wav',
        presentAlert: true,
        presentBadge: true,
        presentSound: true);
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Workmanager().executeTask((taskName, inputData) async {
    List<int> listID = await getIdForNotifications();

    if (listNotifi[0] == true) {
      print("Fajr : Done");
      await scheduleAlarm(
          listID[0], getTitlePrayer("Fajr"), getBodyPrayer("Fajr"), "Fajr");
    }
    if (listNotifi[1] == true) {
      print("Duher : Done");

      await scheduleAlarm(
          listID[1], getTitlePrayer("Duhr"), getBodyPrayer("Duhr"), "Duhr");
    }
    if (listNotifi[2] == true) {
      print("Asr : Done");

      await scheduleAlarm(
          listID[2], getTitlePrayer("Asr"), getBodyPrayer("Asr"), "Asr");
    }
    if (listNotifi[3] == true) {
      print("Maghreb : Done");

      await scheduleAlarm(listID[3], getTitlePrayer("Maghreb"),
          getBodyPrayer("Maghreb"), "Maghreb");
    }
    if (listNotifi[4] == true) {
      print("Isha : Done");

      await scheduleAlarm(
          listID[4], getTitlePrayer("Isha"), getBodyPrayer("Isha"), "Isha");
    }

    return Future.value(true);
  });
}

Future<List<int>> getIdForNotifications() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int idFajr = (prefs.getInt("0") ?? 0) + 1;
  int idDuhr = (prefs.getInt("1") ?? 1) + 1;
  int idAsr = (prefs.getInt("2") ?? 2) + 1;
  int idMaghreb = (prefs.getInt("3") ?? 3) + 1;
  int idIsha = (prefs.getInt("4") ?? 4) + 1;
  prefs.setInt("0", idFajr);
  prefs.setInt("1", idDuhr);
  prefs.setInt("2", idAsr);
  prefs.setInt("3", idMaghreb);
  prefs.setInt("4", idIsha);
  List<int> listID = [idFajr, idDuhr, idAsr, idMaghreb, idIsha];
  return listID;
}

List<Prayer> getNamePrayer = getPrayers();
List<Prayer> prayerNextDateBody = getDateTimeForNextDay();
String getTitlePrayer(String name) {
  String title;
  if (name == "Fajr") {
    title = "Salat Al ${getNamePrayer[0].name} 🤲";
  } else if (name == "Duhr") {
    title = "Salat Al ${getNamePrayer[1].name} 🤲";
  } else if (name == "Asr") {
    title = "Salat Al ${getNamePrayer[2].name} 🤲";
  } else if (name == "Maghreb") {
    title = "Salat Al ${getNamePrayer[3].name} 🤲";
  } else {
    title = "Salat Al ${getNamePrayer[4].name} 🤲";
  }
  return title;
}

bool nowIsAfterPrayer(String prayer) {
  bool res;
  DateTime now = DateTime.now();
  List<Prayer> prayerTime = getPrayers();
  List<DateTime> listPrayerTime = [];
  for (int i = 0; i < 5; i++) {
    listPrayerTime.add(prayerTime[i]
        .dateTime
        .toLocal()
        .subtract(DateTime.now().timeZoneOffset));
  }
  if (prayer == "Fajr") {
    if (now.isAfter(listPrayerTime[0])) {
      res = true;
    } else {
      res = false;
    }
  } else if (prayer == "Duhr") {
    if (now.isAfter(listPrayerTime[1])) {
      res = true;
    } else {
      res = false;
    }
  } else if (prayer == "Asr") {
    if (now.isAfter(listPrayerTime[2])) {
      res = true;
    } else {
      res = false;
    }
  } else if (prayer == "Maghreb") {
    if (now.isAfter(listPrayerTime[3])) {
      res = true;
    } else {
      res = false;
    }
  } else {
    if (now.isAfter(listPrayerTime[4])) {
      res = true;
    } else {
      res = false;
    }
  }
  return res;
}

String getBodyPrayer(String name) {
  String body;
  if (name == "Fajr") {
    if (nowIsAfterPrayer("Fajr")) {
      body =
          "It's time of prayer now : ${prayerNextDateBody[0].hour}:${prayerNextDateBody[0].minute} 🕌";
    } else {
      body =
          "It's time of prayer now : ${getNamePrayer[0].hour}:${getNamePrayer[0].minute} 🕌";
    }
  } else if (name == "Duhr") {
    if (nowIsAfterPrayer("Duhr")) {
      body =
          "It's time of prayer now : ${prayerNextDateBody[1].hour}:${prayerNextDateBody[1].minute} 🕌";
    } else {
      body =
          "It's time of prayer now : ${getNamePrayer[1].hour}:${getNamePrayer[1].minute} 🕌";
    }
  } else if (name == "Asr") {
    if (nowIsAfterPrayer("Asr")) {
      body =
          "It's time of prayer now : ${prayerNextDateBody[2].hour}:${prayerNextDateBody[2].minute} 🕌";
    } else {
      body =
          "It's time of prayer now : ${getNamePrayer[2].hour}:${getNamePrayer[2].minute} 🕌";
    }
  } else if (name == "Maghreb") {
    if (nowIsAfterPrayer("Maghreb")) {
      body =
          "It's time of prayer now : ${prayerNextDateBody[3].hour}:${prayerNextDateBody[3].minute} 🕌";
    } else {
      body =
          "It's time of prayer now : ${getNamePrayer[3].hour}:${getNamePrayer[3].minute} 🕌";
    }
  } else {
    if (nowIsAfterPrayer("Isha")) {
      body =
          "It's time of prayer now : ${prayerNextDateBody[4].hour}:${prayerNextDateBody[4].minute} 🕌";
    } else {
      body =
          "It's time of prayer now : ${getNamePrayer[4].hour}:${getNamePrayer[4].minute} 🕌";
    }
  }
  return body;
}

//-------------------------This Function Return Alarm Date For Prayer-------------------------//

DateTime selectAlarmDateTime(String prayer) {
  List<Prayer> nextPrayer2 = getPrayers();
  // Will get Date For Prayer For This Day
  List<Prayer> prayerNextDate = getDateTimeForNextDay();
  // Will get Date For Prayer For Next Day
  DateTime date;
  if (prayer == "Fajr") {
    if (nowIsAfterPrayer("Fajr")) {
      date = prayerNextDate[0].dateTime;
    } else {
      date = nextPrayer2[0].dateTime;
    }
  } else if (prayer == "Duhr") {
    if (nowIsAfterPrayer("Duhr")) {
      date = prayerNextDate[1].dateTime;
    } else {
      date = nextPrayer2[1].dateTime;
    }
  } else if (prayer == "Asr") {
    if (nowIsAfterPrayer("Asr")) {
      date = prayerNextDate[2].dateTime;
    } else {
      date = nextPrayer2[2].dateTime;
    }
  } else if (prayer == "Maghreb") {
    if (nowIsAfterPrayer("Maghreb")) {
      date = prayerNextDate[3].dateTime;
    } else {
      date = nextPrayer2[3].dateTime;
    }
  } else {
    if (nowIsAfterPrayer("Isha")) {
      date = prayerNextDate[4].dateTime;
    } else {
      date = nextPrayer2[4].dateTime;
    }
  }

  return date.toLocal().subtract(DateTime.now().timeZoneOffset);
}

//----------------------------End Alarm Date For Prayer----------------------------//

Future scheduleAlarm(int id, String title, String body, String prayer) async {
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName!));
  print(tz.local);
  var initializationSettingsAndroid =
      const AndroidInitializationSettings('solidarieta_logo');
  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {});
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
  });

  DateTime scheduledNotificationDateTime = selectAlarmDateTime(prayer);
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'alarm_notif', 'alarm_notif',
      icon: 'solidarieta_logo',
      playSound: true,
      sound: RawResourceAndroidNotificationSound('a_long_cold_sting.wav'),
      largeIcon: DrawableResourceAndroidBitmap('solidarieta_logo'),
      importance: Importance.max);

  var iOSPlatformChannelSpecifics = const IOSNotificationDetails(
      sound: 'a_long_cold_sting.wav',
      presentAlert: true,
      presentBadge: true,
      presentSound: true);
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
    platformChannelSpecifics,
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
