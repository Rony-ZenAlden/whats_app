import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whats_app/Colors/default_color.dart';
import 'package:whats_app/models/user_model.dart';
import 'package:whats_app/provider/provider_chat.dart';
import 'package:whats_app/widget/messages_widget.dart';

class MessagesArea extends StatelessWidget {
  final UserModel currentUserData;

  MessagesArea({
    super.key,
    required this.currentUserData,
  });

  @override
  Widget build(BuildContext context) {
    UserModel? toUserData = context.watch<ProviderChat>().toUserData;

    return toUserData == null
        ? Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.white,
            child: Center(
              child: Image.asset("images/whatsapp.png"),
            ),
          )
        : Column(
            children: [
              //header
              Container(
                color: DefaultColors.barBackgroundColor,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey,
                      backgroundImage: NetworkImage(
                        toUserData.image,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      toUserData.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.search,
                    ),
                    const Icon(
                      Icons.more_vert,
                    ),
                  ],
                ),
              ),

              //messages list
              Expanded(
                child: MessagesWidget(
                  fromUserData: currentUserData,
                  toUserData: toUserData,
                ),
              ),
            ],
          );
  }
}
