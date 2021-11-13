import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class NotificationsProvider extends ChangeNotifier {
  var noty = Hive.box('notifications');

  late List<bool> _notifications;

  List<bool> getNotifications() {
    for (var i = 0; i < 5; i++) {
      if (noty.get(i) == null) {
        noty.put(i, true);
      }
    }

    _notifications = [
      noty.get(0), // Sobh
      noty.get(1), // Duhr
      noty.get(2), // Asr
      noty.get(3), // Maghreb
      noty.get(4), // Isha
    ];
    return _notifications;
  }

  updateNotifications(int id) {
    noty.put(id, !_notifications[id]);
    notifyListeners();
  }
}
