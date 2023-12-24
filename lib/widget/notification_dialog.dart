import 'package:flutter/material.dart';

class NotificationDialog extends StatefulWidget {
  const NotificationDialog({
    Key? key,
    required this.titleText,
    required this.body,
  }) : super(key: key);

  final titleText;
  final body;

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titleText),
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.close),
          label: const Text('Close'),
        ),
      ],
      content: widget.body.toString().contains('.jpg')
          ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Send you image.'),
                const SizedBox(
                  height: 14,
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Image.network(
                    widget.body.toString(),
                    width: 160,
                    height: 160,
                  ),
                ),
              ],
            )
          : widget.body.toString().contains('.docx') ||
                  widget.body.toString().contains('.pptx') ||
                  widget.body.toString().contains('.xlsx') ||
                  widget.body.toString().contains('.pdf') ||
                  widget.body.toString().contains('.mp3') ||
                  widget.body.toString().contains('.mp4')
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Send you file.'),
                    const SizedBox(
                      height: 14,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Image.asset(
                        'assets/images/file.png',
                        width: 160,
                        height: 160,
                      ),
                    ),
                  ],
                )
              : Text(widget.body),
    );
  }
}
