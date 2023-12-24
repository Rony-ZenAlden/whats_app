import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:whats_app/Colors/default_color.dart';
import 'package:whats_app/chats_message_area/chats_area/chat_area.dart';
import 'package:whats_app/chats_message_area/messages_area.dart';
import 'package:whats_app/models/user_model.dart';

import '../widget/notification_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserModel currentUserData;
  String? _token;
  Stream<String>? _tokenStream;

  readCurrentUserData() async {
    User? currentFirebaseUser = FirebaseAuth.instance.currentUser!;
    if (currentFirebaseUser != null) {
      String uid = currentFirebaseUser.uid;
      String name = currentFirebaseUser.displayName ?? '';
      String email = currentFirebaseUser.email ?? '';
      String password = '';
      String image = currentFirebaseUser.photoURL ?? '';

      currentUserData = UserModel(uid, name, email, password, image: image);
    }

    await getPermissionForNotifications();

    await pushNotificationMessageListener();

    await FirebaseMessaging.instance.getToken().then(setTokenNow);
    _tokenStream = FirebaseMessaging.instance.onTokenRefresh;
    _tokenStream!.listen(setTokenNow);

    await saveTokenToUserInfo();
  }

  getPermissionForNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  pushNotificationMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return NotificationDialog(
              titleText: message.notification!.title,
              body: message.notification!.body,
            );
          },
        );
      }
    });
  }

  setTokenNow(String? token) {
    print('FCM User Recognition Token = ' + token.toString() + "\n\n");

    setState(() {
      _token = token;
    });
  }

  saveTokenToUserInfo() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'token': _token,
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readCurrentUserData();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: DefaultColors.lightBarBackgroundColor,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                color: DefaultColors.primaryColor,
                width: MediaQuery.of(context).size.width,
              ),
            ),
            Positioned(
              ////////////////////////
              ////////////////////////
              ////////////////////////
              child: width < 780
                  ? Column(
                      children: [
                        Expanded(
                          flex: 4,
                          child: ChatsArea(
                            currentUserData: currentUserData,
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Row(
                        children: [
                          // chatting area
                          Expanded(
                            flex: 4,
                            child: ChatsArea(
                              currentUserData: currentUserData,
                            ),
                          ),
                          //message area
                          Expanded(
                            flex: 10,
                            child: MessagesArea(
                              currentUserData: currentUserData,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
