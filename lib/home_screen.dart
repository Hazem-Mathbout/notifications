import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:notifications_two/notification_service.dart';
import 'package:notifications_two/notifications_provider.dart';
import 'package:notifications_two/prayer_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    List<Prayer> prayers = getPrayers();
    var notifications =
        Provider.of<NotificationsProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Notifications Testing",
          style: style(),
        ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Colors.deepOrange,
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prayers.length,
                  itemBuilder: (context, index) {
                    Prayer pr = prayers[index];
                    List<bool> list = notifications.getNotifications();
                    return Container(
                      margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(pr.name, style: style())),
                          Expanded(
                            child: Text(
                                pr.hour.toString() + ":" + pr.minute.toString(),
                                style: style()),
                          ),
                          // Text("Hello", style: style()),
                          FlutterSwitch(
                            activeColor: Colors.green,
                            inactiveColor: Colors.white,
                            inactiveTextColor: Colors.black,
                            activeTextColor: Colors.white,
                            width: 70.0,
                            height: 30.0,
                            valueFontSize: 15.0,
                            toggleSize: 15.0,
                            value: list[index],
                            padding: 8.0,
                            showOnOff: true,
                            onToggle: (value) async {
                              setState(() {
                                notifications.updateNotifications(index);
                              });
                              await onToggleUser(list, index, pr);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () async {},
                child: Text(
                  "Get Notified After 10 Seconds",
                  style: style(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onToggleUser(List<bool> list, int index, Prayer pr) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String getKeyForPrayer = index.toString();
    int? notificationID = prefs.getInt(getKeyForPrayer);

    if (list[index] == true) {
      await flutterLocalNotificationsPlugin.cancel(notificationID!);
    }
    if (list[index] == false) {
      await scheduleAlarm(notificationID!, getTitlePrayer(pr.name),
          getBodyPrayer(pr.name), pr.name);
    }
  }
}

TextStyle style() {
  return const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
