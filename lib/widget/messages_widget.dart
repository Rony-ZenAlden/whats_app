import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:whats_app/Colors/default_color.dart';
import 'package:whats_app/models/chat.dart';
import 'package:whats_app/models/message.dart';
import 'package:whats_app/models/user_model.dart';
import 'package:whats_app/provider/provider_chat.dart';
import 'package:http/http.dart' as http;

class MessagesWidget extends StatefulWidget {
  final UserModel fromUserData;
  final UserModel toUserData;

  MessagesWidget(
      {super.key, required this.fromUserData, required this.toUserData});

  @override
  State<MessagesWidget> createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<MessagesWidget> {
  TextEditingController messageTextEditingController = TextEditingController();
  late StreamSubscription _streamSubscriptionMessages;
  final streamController = StreamController<QuerySnapshot>.broadcast();
  final scrollControllerMessages = ScrollController();
  String? fileTypeChoosed;
  bool _loadingPic = false;
  bool _loadingFile = false;
  Uint8List? _selectedImage;
  Uint8List? _selectedFile;
  String? _token;

  sendPushNotificationToWEB(String messageText, String fromUserName) async {
    if (_token == null) {
      var snackBar = const SnackBar(
        content: Center(
          child: Text('No Token Exists, Unable to Send Push Notification'),
        ),
        backgroundColor: DefaultColors.primaryColor,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      return;
    }
    try{
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type':'application/json',
          'Authorization':'key=AAAAgx0kvnE:APA91bEe3Sjv3hJ_p_rFVsHDu41xH27VVBaGS0-PyQjjZCTbviQkd3LNQ8V_BATkxF_BIq3ObSVrj5Ac2QGi_ye7yDPsAI-UJgJivB5qBrcOnJOI4cfwmsrcHkC9M9QgXvkx5ZlB1n8m',

        },
        body: json.encode({
          'to': _token,
          'message': {
            'token': _token,
          },
          'notification': {
            'title': fromUserName,
            'body': messageText,
          },
        }),
      );
    }
    catch(error) {
      var snackBar = SnackBar(
        content: Center(
          child: Text('Error =' + error.toString()),
        ),
        backgroundColor: DefaultColors.primaryColor,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  sendMessage() {
    String msgText = messageTextEditingController.text.trim();

    if (msgText.isNotEmpty) {
      String fromUserID = widget.fromUserData.uid;

      final message = Message(
        fromUserID,
        msgText,
        Timestamp.now().toString(),
      );

      String toUserID = widget.toUserData.uid;

      String messageID = DateTime.now().millisecondsSinceEpoch.toString();

      //save message for sender
      saveMessageToDatabase(fromUserID, toUserID, message, messageID);

      //save chat for recents [sender]
      final chatFromData = Chat(
        fromUserID,
        toUserID,
        message.text.trim(),
        widget.toUserData.name,
        widget.toUserData.email,
        widget.toUserData.image,
      );
      saveRecentChatToDatabase(chatFromData, msgText);

      //save message for receiver
      saveMessageToDatabase(toUserID, fromUserID, message, messageID);

      //save chat for recents [receiver]
      final chatToData = Chat(
        toUserID,
        fromUserID,
        message.text.trim(),
        widget.fromUserData.name,
        widget.fromUserData.email,
        widget.fromUserData.image,
      );
      saveRecentChatToDatabase(chatToData, msgText);
    }
  }

  saveMessageToDatabase(fromUserID, toUserID, message, messageID) {
    FirebaseFirestore.instance
        .collection("messages")
        .doc(fromUserID)
        .collection(toUserID)
        .doc(messageID)
        .set(message.toMap());

    messageTextEditingController.clear();
  }

  saveRecentChatToDatabase(Chat chat, msgText) {
    FirebaseFirestore.instance
        .collection("chats")
        .doc(chat.fromUserId)
        .collection("lastMessage")
        .doc(chat.toUserId)
        .set(chat.toMap())
        .then((value) async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(chat.toUserId)
          .get()
          .then((snapshot) {
        setState(() {
          _token = snapshot.data()!['token'];
        });
      });

      //send notification
      sendPushNotificationToWEB(msgText, widget.fromUserData.name);
    });
  }

  createMessageListener({UserModel? toUserData}) {
    //live refresh our messages page directly from firebase
    final streamMessages = FirebaseFirestore.instance
        .collection("messages")
        .doc(widget.fromUserData.uid)
        .collection(toUserData?.uid ?? widget.toUserData.uid)
        .orderBy("dateTime", descending: false)
        .snapshots();

    //scroll at the end of messages list
    _streamSubscriptionMessages = streamMessages.listen((data) {
      streamController.add(data);

      Timer(const Duration(seconds: 1), () {
        scrollControllerMessages
            .jumpTo(scrollControllerMessages.position.maxScrollExtent);
      });
    });
  }

  updateMessageListener() {
    UserModel? toUserData = context.watch<ProviderChat>().toUserData;

    if (toUserData != null) {
      createMessageListener(toUserData: toUserData);
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    //to update the message listeners through provider
    updateMessageListener();
  }

  @override
  void dispose() {
    _streamSubscriptionMessages.cancel();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    createMessageListener();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
          image: DecorationImage(
        image: AssetImage("images/background.png"),
        fit: BoxFit.cover,
      )),
      child: Column(
        children: [
          //display messages here
          StreamBuilder(
            stream: streamController.stream,
            builder: (context, dataSnapshot) {
              switch (dataSnapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Loading Data..."),
                          SizedBox(height: 8),
                          CircularProgressIndicator(),
                        ],
                      ),
                    ),
                  );

                case ConnectionState.active:
                case ConnectionState.done:
                  if (dataSnapshot.hasError) {
                    return const Center(
                      child: Text("Error Occurred"),
                    );
                  } else {
                    final snapshot = dataSnapshot.data as QuerySnapshot;

                    List<DocumentSnapshot> messagesList =
                        snapshot.docs.toList();

                    return Expanded(
                      child: ListView.builder(
                        controller: scrollControllerMessages,
                        itemCount: snapshot.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot eachMessage = messagesList[index];

                          //align message balloons from sender and receiver
                          Alignment alignment = Alignment.bottomLeft;
                          Color color = Colors.white;

                          if (widget.fromUserData.uid == eachMessage["uid"]) {
                            alignment = Alignment.bottomRight;
                            color = const Color(0xffd2ffa5);
                          }

                          Size width = MediaQuery.of(context).size * 0.8;

                          return GestureDetector(
                            onLongPress: () async {
                              if (eachMessage["uid"] ==
                                  FirebaseAuth.instance.currentUser!.uid) {
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            await deleteForMe(
                                              eachMessage.id,
                                              FirebaseAuth
                                                  .instance.currentUser!.uid,
                                              widget.toUserData.uid,
                                              eachMessage['text'].toString(),
                                            );

                                            await deleteForThem(
                                              eachMessage.id,
                                              FirebaseAuth
                                                  .instance.currentUser!.uid,
                                              widget.toUserData.uid,
                                              eachMessage['text'].toString(),
                                            );
                                          },
                                          child:
                                              const Text('Delete For Everyone'),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();

                                            await deleteForMe(
                                              eachMessage.id,
                                              FirebaseAuth
                                                  .instance.currentUser!.uid,
                                              widget.toUserData.uid,
                                              eachMessage['text'].toString(),
                                            );

                                            await deleteForThem(
                                              eachMessage.id,
                                              FirebaseAuth
                                                  .instance.currentUser!.uid,
                                              widget.toUserData.uid,
                                              eachMessage['text'].toString(),
                                            );
                                          },
                                          child: const Text('Delete For Me'),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                            child: eachMessage["text"]
                                    .toString()
                                    .contains('.jpg')
                                ? Align(
                                    alignment: alignment,
                                    child: Container(
                                      constraints: BoxConstraints.loose(width),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(9),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      margin: const EdgeInsets.all(6),
                                      child: Image.network(
                                        eachMessage["text"],
                                        width: 200,
                                        height: 200,
                                      ),
                                    ),
                                  )
                                : eachMessage["text"]
                                            .toString()
                                            .contains('.docx') ||
                                        eachMessage["text"]
                                            .toString()
                                            .contains('.pptx') ||
                                        eachMessage["text"]
                                            .toString()
                                            .contains('.xlsx') ||
                                        eachMessage["text"]
                                            .toString()
                                            .contains('.pdf') ||
                                        eachMessage["text"]
                                            .toString()
                                            .contains('.mp3') ||
                                        eachMessage["text"]
                                            .toString()
                                            .contains('.mp4')
                                    ? Align(
                                        alignment: alignment,
                                        child: Container(
                                          constraints:
                                              BoxConstraints.loose(width),
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(9),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          margin: const EdgeInsets.all(6),
                                          child: GestureDetector(
                                            onTap: () {},
                                            child: Image.asset(
                                              'assets/images/file.png',
                                              width: 200,
                                              height: 200,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Align(
                                        alignment: alignment,
                                        child: Container(
                                          constraints:
                                              BoxConstraints.loose(width),
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(9),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          margin: const EdgeInsets.all(6),
                                          child: Text(eachMessage["text"]),
                                        ),
                                      ),
                          );
                        },
                      ),
                    );
                  }
              }
            },
          ),

          //text field for sending message
          Container(
            padding: const EdgeInsets.all(8),
            color: DefaultColors.barBackgroundColor,
            child: Row(
              children: [
                //text field with 2 icon button
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(42),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_emoticon,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: TextField(
                            controller: messageTextEditingController,
                            decoration: const InputDecoration(
                              hintText: "Write a message",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        _loadingFile == false
                            ? IconButton(
                                onPressed: () {
                                  dialogBoxForSelectingFile();
                                },
                                icon: const Icon(
                                  Icons.attach_file,
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: DefaultColors.primaryColor,
                                ),
                              ),
                        _loadingPic == false
                            ? IconButton(
                                onPressed: () {
                                  selectImage();
                                },
                                icon: const Icon(
                                  Icons.camera_alt,
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: DefaultColors.primaryColor,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),

                FloatingActionButton(
                  backgroundColor: DefaultColors.primaryColor,
                  mini: true,
                  onPressed: () {
                    sendMessage();
                  },
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  dialogBoxForSelectingFile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Send File'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please Choose File Type From The Following:'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DropdownButton<String>(
                      hint: const Text('Choose Here'),
                      value: fileTypeChoosed,
                      underline: Container(),
                      items: <String>[
                        '.pdf',
                        '.mp4',
                        '.mp3',
                        '.docx',
                        '.pptx',
                        '.xlsx',
                      ].map((String value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          fileTypeChoosed = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();

                    // select file
                    selectFile(fileTypeChoosed);
                  },
                  child: const Text('Select File'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  selectFile(fileTypeChoosed) async {
    FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    setState(() {
      _selectedFile = pickerResult?.files.single.bytes;
    });
    uploadFile(_selectedFile);
  }

  uploadFile(selectedFile) {
    setState(() {
      _loadingFile = true;
    });
    if (selectedFile != null) {
      Reference fileRef = FirebaseStorage.instance.ref(
          'files/${DateTime.now().millisecondsSinceEpoch.toString()}$fileTypeChoosed');

      UploadTask uploadTask = fileRef.putData(selectedFile);

      uploadTask.whenComplete(() async {
        String linkFile = await uploadTask.snapshot.ref.getDownloadURL();

        setState(() {
          messageTextEditingController.text = linkFile;
        });
        sendMessage();

        setState(() {
          _loadingFile = false;
        });
      });
    }
  }

  selectImage() async {
    FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    setState(() {
      _selectedImage = pickerResult?.files.single.bytes;
    });
    uploadImage(_selectedImage);
  }

  uploadImage(selectedImage) {
    setState(() {
      _loadingPic = true;
    });
    if (selectedImage != null) {
      Reference fileRef = FirebaseStorage.instance.ref(
          'chatImages/${DateTime.now().millisecondsSinceEpoch.toString()}.jpg');

      UploadTask uploadTask = fileRef.putData(selectedImage);

      uploadTask.whenComplete(() async {
        String linkFile = await uploadTask.snapshot.ref.getDownloadURL();

        setState(() {
          messageTextEditingController.text = linkFile;
        });

        sendMessage();

        setState(() {
          _loadingPic = false;
        });
      });
    }
  }

  deleteForMe(messageID, myId, toUserID, messageTextToUpdate) async {
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(myId)
        .collection(toUserID)
        .doc(messageID)
        .update({
      'text': '🚫 message deleted',
    });
  }

  deleteForThem(messageID, myId, toUserID, messageTextToUpdate) async {
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(toUserID)
        .collection(myId)
        .doc(messageID)
        .update({
      'text': '🚫 message deleted',
    });
  }
}
