class Message {
  String uid;
  String text;
  String dateTime;

  Message(
    this.uid,
    this.text,
    this.dateTime,
  );

  Map<String, dynamic> toMap() {
    Map<String, dynamic> mapMessage = {
      'uid':uid,
      'text':text,
      'dateTime':dateTime,
    };

    return mapMessage;
  }
}
