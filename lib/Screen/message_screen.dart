import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whats_app/models/user_model.dart';
import 'package:whats_app/widget/messages_widget.dart';

class MessagesScreen extends StatefulWidget {
  MessagesScreen(this.toUserData, {Key? key}) : super(key: key);

  final UserModel toUserData;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late UserModel toUser;
  late UserModel fromUser;

  getUserData() {
    toUser = widget.toUserData;
    User? loggedInUser = FirebaseAuth.instance.currentUser;
    if (loggedInUser != null) {
      fromUser = UserModel(
        loggedInUser.uid,
        loggedInUser.displayName ?? '',
        loggedInUser.email ?? '',
        '',
        image: loggedInUser.photoURL ?? '',
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage(toUser.image),
            ),
            const SizedBox(width: 8),
            Text(
              toUser.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.more_vert),
        ],
      ),
      body: SafeArea(
        child: MessagesWidget(
          fromUserData: fromUser,
          toUserData: toUser,
        ),
      ),
    );
  }
}
