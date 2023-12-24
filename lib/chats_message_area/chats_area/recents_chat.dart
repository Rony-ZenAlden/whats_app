import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whats_app/models/user_model.dart';
import 'package:whats_app/provider/provider_chat.dart';

class RecentChats extends StatefulWidget {
  const RecentChats({super.key});

  @override
  State<RecentChats> createState() => _RecentChatsState();
}

class _RecentChatsState extends State<RecentChats> {
  late UserModel fromUserData;
  final streamController = StreamController<QuerySnapshot>.broadcast();
  late StreamSubscription streamSubscriptionChats;

  chatListener() {
    final streamRecentChats = FirebaseFirestore.instance
        .collection('chats')
        .doc(fromUserData.uid)
        .collection('lastMessage')
        .snapshots();

    streamSubscriptionChats = streamRecentChats.listen((newMessageData) {
      streamController.add(newMessageData);
    });
  }

  loadInitialData() {
    User? currentFirebaseUser = FirebaseAuth.instance.currentUser;

    if (currentFirebaseUser != null) {
      String userID = currentFirebaseUser.uid;
      String? name = currentFirebaseUser.displayName ?? '';
      String? email = currentFirebaseUser.email ?? '';
      String? password = '';
      String? profilePicture = currentFirebaseUser.photoURL ?? '';

      fromUserData = UserModel(
        userID,
        name,
        email,
        password,
        image: profilePicture,
      );
    }

    chatListener();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    streamSubscriptionChats.cancel();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return StreamBuilder(
      stream: streamController.stream,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return const Center(
              child: Column(
                children: [
                  Text('Loading Chats...'),
                  SizedBox(height: 6),
                  CircularProgressIndicator(),
                ],
              ),
            );
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading chats data!'),
              );
            } else {
              QuerySnapshot snapshotData = snapshot.data as QuerySnapshot;
              List<DocumentSnapshot> recentChatsList =
                  snapshotData.docs.toList();

              return ListView.separated(
                separatorBuilder: (context, index) {
                  return const Divider(
                    color: Colors.grey,
                    thickness: 0.3,
                  );
                },
                itemCount: recentChatsList.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot chat = recentChatsList[index];
                  String toUserImage = chat['toUserImage'];
                  String toUserName = chat['toUserName'];
                  String toUserEmail = chat['toUserEmail'];
                  String lastMessage = chat['lastMessage'];
                  String toUserID = chat['toUserId'];

                  final toUserData = UserModel(
                    toUserID,
                    toUserName,
                    toUserEmail,
                    '',
                    image: toUserImage,
                  );

                  return ListTile(
                    onTap: () {
                      setState(() {
                        if(width < 780) {
                          Navigator.pushNamed(context, '/messages',arguments: toUserData);
                        } else {
                          context.read<ProviderChat>().toUserData = toUserData;
                        }
                      });
                    },
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.grey,
                      backgroundImage: NetworkImage(
                        toUserData.image,
                      ),
                    ),
                    title: Text(
                      toUserData.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                        lastMessage.toString().contains('.jpg')
                        ? 'Sent you an Image.'
                        : lastMessage.toString().contains('.docx') ||
                        lastMessage.toString().contains('.pptx') ||
                        lastMessage.toString().contains('.pdf') ||
                        lastMessage.toString().contains('.mp3') ||
                        lastMessage.toString().contains('.mp4') ? 'Sent you a file'
                            : lastMessage.toString(),
                      style:const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    contentPadding:const EdgeInsets.all(9),
                  );
                },
              );
            }
        }
      },
    );
  }
}
