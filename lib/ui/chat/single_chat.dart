import 'dart:async';
import 'dart:io';
import 'package:nomad_hub/utils/auth.dart';
import 'package:nomad_hub/utils/image_compressor.dart';
import 'package:nomad_hub/utils/user.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nomad_hub/ui/nomads/nomad_profile.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final DataSnapshot userSnapshot;

  ChatScreen(this.userSnapshot);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textEditingController =
      new TextEditingController();
  bool _isComposingMessage = false;
  DatabaseReference _chatReference;
  bool _isBlocked;

  @override
  void dispose() {
    super.dispose();

    //update last checked timestamp
    var reference = FirebaseDatabase.instance
        .reference()
        .child("user")
        .child(User.uid)
        .child("chats")
        .child(widget.userSnapshot.key);

    reference.once().then((snapshot) {
      if (snapshot.value != null && snapshot.value["timestamp"] != null) {
        reference.update(
            {"timestampChecked": DateTime.now().millisecondsSinceEpoch});
      }
    });
  }

  @override
  void initState() {
    super.initState();

    //get chat id
    final String chatId = User.uid.compareTo(widget.userSnapshot.key) > 0
        ? User.uid + "_" + widget.userSnapshot.key
        : widget.userSnapshot.key + "_" + User.uid;

    //get chat reference
    _chatReference =
        FirebaseDatabase.instance.reference().child("chat").child(chatId);

    if (widget.userSnapshot.value["blockedUser"] != null &&
        widget.userSnapshot.value["blockedUser"]
            .toString()
            .contains(User.uid)) {
      setState(() => _isBlocked = true);
    } else {
      setState(() => _isBlocked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            FlatButton(
              onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (BuildContext context) {
                    return NomadProfileScreen(widget.userSnapshot);
                  })),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CircleAvatar(
                        backgroundImage: NetworkImage(
                            widget.userSnapshot.value["photoUrl"])),
                  ),
                  Text(widget.userSnapshot.value["displayName"]),
                ],
              ),
            ),
            Expanded(
              child: Container(),
            ),
          ],
        ),
      ),
      body: Container(
        child: _chatReference == null
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  Flexible(
                    child: FirebaseAnimatedList(
                      query: _chatReference,
                      padding: const EdgeInsets.all(8.0),
                      reverse: true,
                      sort: (a, b) => b.key.compareTo(a.key),
                      //comparing timestamp of messages to check which one would appear first
                      itemBuilder: (_, DataSnapshot messageSnapshot,
                          Animation<double> animation, int pos) {
                        return ChatMessage(
                          messageSnapshot: messageSnapshot,
                          animation: animation,
                          partnerSnapshot: widget.userSnapshot,
                        );
                      },
                    ),
                  ),
                  Divider(height: 1.0),
                  Container(
                    decoration:
                        BoxDecoration(color: Theme.of(context).cardColor),
                    child: _isBlocked
                        ? Text("You are blocked by this user")
                        : _buildTextComposer(),
                  ),
                ],
              ),
      ),
    );
  }

  CupertinoButton getIOSSendButton() {
    return CupertinoButton(
      child: Text(
        "Send",
        style: TextStyle(
            color: _isComposingMessage
                ? Theme.of(context).accentColor
                : Theme.of(context).disabledColor),
      ),
      onPressed: _isComposingMessage
          ? () => _textMessageSubmitted(_textEditingController.text)
          : null,
    );
  }

  IconButton getDefaultSendButton() {
    return IconButton(
      icon: Icon(Icons.send),
      onPressed: _isComposingMessage
          ? () => _textMessageSubmitted(_textEditingController.text)
          : null,
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
        data: IconThemeData(
          color: _isComposingMessage
              ? Theme.of(context).accentColor
              : Theme.of(context).disabledColor,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: <Widget>[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                child: IconButton(
                    icon: Icon(
                      Icons.photo_camera,
                      color: Theme.of(context).accentColor,
                    ),
                    onPressed: () async {
                      File imageFile = await ImagePicker.pickImage(
                          source: ImageSource.gallery);
                      int timestamp = DateTime.now().millisecondsSinceEpoch;

                      //compress file size
                      File compressedImage = await compressFile(imageFile);

                      StorageReference storageReference = FirebaseStorage
                          .instance
                          .ref()
                          .child("user")
                          .child(User.uid)
                          .child("sent_images")
                          .child("img_" + timestamp.toString() + ".png");
                      StorageUploadTask uploadTask =
                          storageReference.putFile(compressedImage);
                      Uri downloadUrl = (await uploadTask.future).downloadUrl;
                      _sendMessage(
                          messageText: null, imageUrl: downloadUrl.toString());
                    }),
              ),
              Flexible(
                child: TextField(
                  controller: _textEditingController,
                  onChanged: (String messageText) {
                    setState(() {
                      _isComposingMessage = messageText.length > 0;
                    });
                  },
                  onSubmitted: _textMessageSubmitted,
                  decoration:
                      InputDecoration.collapsed(hintText: "Send a message"),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? getIOSSendButton()
                    : getDefaultSendButton(),
              ),
            ],
          ),
        ));
  }

  Future<Null> _textMessageSubmitted(String text) async {
    _textEditingController.clear();

    setState(() {
      _isComposingMessage = false;
    });

    _sendMessage(messageText: text, imageUrl: null);
  }

  void _sendMessage({String messageText, String imageUrl}) {
    var time = DateFormat.yMd().add_Hm().format(DateTime.now());

    _chatReference.push().set({
      'text': messageText,
      'time': time,
      'email': User.email,
      'imageUrl': imageUrl,
    });

    var timestamp = DateTime.now().millisecondsSinceEpoch;

    //update chats of user
    FirebaseDatabase.instance
        .reference()
        .child("user")
        .child(User.uid)
        .child("chats")
        .child(widget.userSnapshot.key)
        .update({
      "timestamp": timestamp,
      "time": time,
      "lastMessage": messageText ?? "image",
      "partnerName": widget.userSnapshot.value["displayName"],
      "photoUrl": widget.userSnapshot.value["photoUrl"],
    });

    //update chats of partner
    FirebaseDatabase.instance
        .reference()
        .child("user")
        .child(widget.userSnapshot.key)
        .child("chats")
        .child(User.uid)
          ..update({
            "timestamp": timestamp,
            "time": time,
            "lastMessage": messageText ?? "image",
            "partnerName": User.displayName,
            "photoUrl": User.photoUrl,
          });

    //update counter of partner
    FirebaseDatabase.instance
        .reference()
        .child("user")
        .child(widget.userSnapshot.key)
        .child("newMessages")
        .runTransaction((MutableData data) async {
      if (data.value != null) {
        data.value++;
      } else {
        data.value = 1;
      }
      return data;
    });

    //send notification
    FirebaseDatabase.instance
        .reference()
        .child("admin")
        .child("fcm")
        .once()
        .then((snapshot) {
      String data =
          '{"notification": {"body": "${messageText ?? "image"}","title": '
          '"${User
          .displayName}"}, "priority": "high", "data": {"click_action": '
          '"FLUTTER_NOTIFICATION_CLICK", "id": "1", "status": "done"}, "to": '
          '"${widget.userSnapshot.value["fcm_token"]}"}';
      String url = "https://fcm.googleapis.com/fcm/send";
      Map<String, String> headers = {
        "Content-Type": "application/json",
        "Authorization": "key=${snapshot.value["serverkey"]}"
      };
      http.post(url, headers: headers, body: data);
    });

    Auth.analytics.logEvent(name: "send_message");
  }
}

class ChatMessage extends StatelessWidget {
  final DataSnapshot messageSnapshot;
  final Animation animation;
  final DataSnapshot partnerSnapshot;

  ChatMessage({this.messageSnapshot, this.animation, this.partnerSnapshot});

  @override
  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.decelerate),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: User.email == messageSnapshot.value["email"]
              ? getSentMessageLayout()
              : getReceivedMessageLayout(),
        ),
      ),
    );
  }

  List<Widget> getSentMessageLayout() {
    return <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(User.displayName,
                style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            Text(messageSnapshot.value["time"],
                style: TextStyle(fontSize: 10.0, color: Colors.grey)),
            Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: messageSnapshot.value["imageUrl"] != null
                  ? Image.network(
                      messageSnapshot.value["imageUrl"],
                      width: 150.0,
                    )
                  : Text(messageSnapshot.value["text"]),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
              margin: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(User.photoUrl),
              )),
        ],
      ),
    ];
  }

  List<Widget> getReceivedMessageLayout() {
    return <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundImage:
                    NetworkImage(partnerSnapshot.value["photoUrl"]),
              )),
        ],
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(partnerSnapshot.value["displayName"],
                style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            Text(messageSnapshot.value["time"],
                style: TextStyle(fontSize: 10.0, color: Colors.grey)),
            Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: messageSnapshot.value["imageUrl"] != null
                  ? Image.network(
                      messageSnapshot.value["imageUrl"],
                      width: 150.0,
                    )
                  : Text(messageSnapshot.value["text"]),
            ),
          ],
        ),
      ),
    ];
  }
}
