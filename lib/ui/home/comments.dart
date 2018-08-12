import 'dart:async';

import 'package:nomad_hub/utils/auth.dart';
import 'package:nomad_hub/utils/user.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:nomad_hub/ui/nomads/nomad_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class SinglePostScreen extends StatefulWidget {
  final DataSnapshot messageSnapshot;
  final double distance;
  final Color backgroundColor;

  SinglePostScreen(this.messageSnapshot, this.distance, this.backgroundColor);

  @override
  _SinglePostScreenState createState() => _SinglePostScreenState();
}

class _SinglePostScreenState extends State<SinglePostScreen> {
  DatabaseReference _postReference;
  final TextEditingController _textEditingController =
      new TextEditingController();
  bool _isComposingMessage = false;

  @override
  void initState() {
    super.initState();

    _postReference = FirebaseDatabase.instance
        .reference()
        .child("broadcast")
        .child(widget.messageSnapshot.key)
        .child("comments");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Comments")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            color: widget.backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    FlatButton(
                      onPressed: () async {
                        var userSnapshot = await FirebaseDatabase.instance
                            .reference()
                            .child("user")
                            .child(widget.messageSnapshot.value["senderUid"])
                            .once();
                        Navigator.push(context,
                            MaterialPageRoute(builder: (BuildContext context) {
                          return NomadProfileScreen(userSnapshot);
                        }));
                      },
                      child: Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FutureBuilder(
                                future: _getPhotoUrl(),
                                builder: (BuildContext context,
                                    AsyncSnapshot snapshot) {
                                  if (snapshot.hasData) {
                                    return CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(snapshot.data),
                                    );
                                  } else {
                                    return CircleAvatar();
                                  }
                                }),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(widget.messageSnapshot.value["senderName"]),
                              Text(widget.messageSnapshot.value["time"],
                                  style: TextStyle(fontSize: 10.0)),
                              Text(
                                  widget.distance < 3.0
                                      ? "< 3.00 KM"
                                      : "${widget.distance.toStringAsFixed(
                                      2)} KM",
                                  style: TextStyle(fontSize: 10.0)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: Container(height: 0.0, width: 0.0)),
                    widget.messageSnapshot.value["senderUid"] != User.uid
                        ? Container(height: 0.0, width: 0.0)
                        : PopupMenuButton(
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuItem<String>>[
                                  PopupMenuItem(
                                    child: FlatButton(
                                      child: Text("Delete"),
                                      onPressed: () {
                                        _postReference.parent().remove();
                                        Navigator.popUntil(
                                            context, ModalRoute.withName('/'));
                                      },
                                    ),
                                  ),
                                ]),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0, bottom: 15.0),
                  child: Text(widget.messageSnapshot.value["text"]),
                ),
              ],
            ),
          ),
          Divider(height: 1.0),
          Flexible(
            child: FirebaseAnimatedList(
              query: _postReference,
              padding: const EdgeInsets.all(8.0),
              //comparing timestamp of messages to check which one would appear first
              itemBuilder: (_, DataSnapshot commentSnapshot,
                  Animation<double> animation, int pos) {
                return Comment(
                  commentSnapshot: commentSnapshot,
                  animation: animation,
                  postReference: _postReference,
                );
              },
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Future<String> _getPhotoUrl() async {
    var reference = await FirebaseDatabase.instance
        .reference()
        .child("user")
        .child(widget.messageSnapshot.value["senderUid"])
        .once();

    return reference.value["photoUrl"];
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
                      InputDecoration.collapsed(hintText: "Comment post"),
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

    _postReference.push().set({
      'text': messageText,
      'time': time,
      'senderUid': User.uid,
      'senderName': User.displayName,
      'senderPhotoUrl': User.photoUrl,
    });

    _postReference
        .parent()
        .child("commentsCounter")
        .runTransaction((MutableData data) async {
      if (data.value != null) {
        data.value++;
      } else {
        data.value = 1;
      }
      return data;
    });

    //subscribe to topic for notifications
    User.firebaseMessaging.subscribeToTopic(widget.messageSnapshot.key);

    //send notification
    FirebaseDatabase.instance
        .reference()
        .child("admin")
        .child("fcm")
        .once()
        .then((snapshot) {
      String data = '{"notification": {"body": "${widget.messageSnapshot.value["senderName"]}: ${widget.messageSnapshot
          .value["text"]}","title": '
          '"${User.displayName} commented this post"}, "priority": "high", "data": {"click_action": '
          '"FLUTTER_NOTIFICATION_CLICK", "id": "1", "status": "done"}, "to": '
          '"/topics/${widget.messageSnapshot.key}"}';
      String url = "https://fcm.googleapis.com/fcm/send";
      Map<String, String> headers = {
        "Content-Type": "application/json",
        "Authorization": "key=${snapshot.value["serverkey"]}"
      };

      http.post(url, headers: headers, body: data);
    });

    Auth.analytics.logEvent(name: 'send_comment');
  }
}

class Comment extends StatelessWidget {
  final DataSnapshot commentSnapshot;
  final Animation animation;
  final DatabaseReference postReference;

  Comment({this.commentSnapshot, this.animation, this.postReference});

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.decelerate),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () async {
                  var userSnapshot = await FirebaseDatabase.instance
                      .reference()
                      .child("user")
                      .child(commentSnapshot.value["senderUid"])
                      .once();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (BuildContext context) {
                    return NomadProfileScreen(userSnapshot);
                  }));
                },
                child: Row(children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundImage:
                          NetworkImage(commentSnapshot.value["senderPhotoUrl"]),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(commentSnapshot.value["senderName"]),
                      Text(commentSnapshot.value["time"],
                          style: TextStyle(fontSize: 10.0)),
                    ],
                  ),
                ]),
              ),
              Expanded(child: Container(height: 0.0, width: 0.0)),
              commentSnapshot.value["senderUid"] != User.uid
                  ? Container(height: 0.0, width: 0.0)
                  : PopupMenuButton(
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuItem<String>>[
                            PopupMenuItem(
                              child: FlatButton(
                                  child: Text("Delete"),
                                  onPressed: () {
                                    postReference
                                        .child(commentSnapshot.key)
                                        .remove();
                                    Navigator.pop(context);

                                    postReference
                                        .parent()
                                        .child("commentsCounter")
                                        .runTransaction(
                                            (MutableData data) async {
                                      if (data.value != null) {
                                        data.value--;
                                      } else {
                                        data.value = 0;
                                      }
                                      return data;
                                    });
                                  }),
                            ),
                          ]),
            ],
          ),
          Text(commentSnapshot.value["text"]),
          Divider(
            height: 1.0,
          ),
        ],
      ),
    );
  }
}
