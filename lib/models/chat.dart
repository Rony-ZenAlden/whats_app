class Chat {
  String fromUserId;
  String toUserId;
  String lastMessage;
  String toUserName;
  String toUserEmail;
  String toUserImage;

  Chat(
    this.fromUserId,
    this.toUserId,
    this.lastMessage,
    this.toUserName,
    this.toUserEmail,
    this.toUserImage,
  );

  Map<String, dynamic> toMap() {
    Map<String, dynamic> mapChat = {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'lastMessage': lastMessage,
      'toUserName': toUserName,
      'toUserEmail': toUserEmail,
      'toUserImage': toUserImage,
    };

    return mapChat;
  }
}
