import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whats_app/Colors/default_color.dart';
import 'package:whats_app/chats_message_area/chats_area/contacts_list.dart';
import 'package:whats_app/chats_message_area/chats_area/recents_chat.dart';
import 'package:whats_app/models/user_model.dart';

class ChatsArea extends StatelessWidget
{
  final UserModel currentUserData;

  ChatsArea({super.key, required this.currentUserData,});

  @override
  Widget build(BuildContext context)
  {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: const BoxDecoration(
          color: DefaultColors.lightBarBackgroundColor,
          border: Border(
            right: BorderSide(
              color: DefaultColors.backgroundColor,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [

            //header
            Container(
              color: DefaultColors.backgroundColor,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [

                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey,
                    backgroundImage: NetworkImage(
                      currentUserData.image,
                    ),
                  ),

                  const SizedBox(width: 12,),

                  Text(
                    currentUserData.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  IconButton(
                    onPressed: () async
                    {
                      await FirebaseAuth.instance.signOut().then((value)
                      {
                        Navigator.pushReplacementNamed(context, "/login");
                      });
                    },
                    icon: const Icon(Icons.logout),
                  ),

                ],
              ),
            ),

            //2 tabs buttons
            const TabBar(
              unselectedLabelColor: Colors.grey,
              labelColor: Colors.black,
              indicatorColor: DefaultColors.primaryColor,
              indicatorWeight: 2,
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              tabs: [
                Tab(
                  text: "Chats",
                ),
                Tab(
                  text: "Contacts",
                ),
              ],
            ),

            Expanded(
              child: Container(
                color: Colors.white,
                child: const TabBarView(
                  children: [

                    //show recent chats
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: RecentChats(),
                    ),

                    //show contacts list
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: ContactsList(),
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
