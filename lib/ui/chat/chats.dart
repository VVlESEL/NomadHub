import 'package:nomad_hub/ui/chat/single_chat.dart';
import 'package:nomad_hub/utils/user.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _databaseReference = FirebaseDatabase.instance
      .reference()
      .child("user")
      .child(User.uid)
      .child("chats");

  @override
  void initState(){
    super.initState();

    FirebaseDatabase.instance.reference().child("user").child(User.uid).update({"newMessages": 0});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Flexible(
            child: FirebaseAnimatedList(
              query: _databaseReference,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              sort: (a, b) =>
                  b.value["timestamp"].compareTo(a.value["timestamp"]),
              //comparing timestamp of messages to check which one would appear first
              itemBuilder: (_, DataSnapshot chatSnapshot,
                  Animation<double> animation, int pos) {
                return UserEntry(
                  chatSnapshot: chatSnapshot,
                  animation: animation,
                );
              },
            ),
          ),
        ],
      ),
      decoration: Theme.of(context).platform == TargetPlatform.iOS
          ? BoxDecoration(
              border: Border(
                  top: BorderSide(
              color: Colors.grey[200],
            )))
          : null,
    );
  }
}

class UserEntry extends StatelessWidget {
  final DataSnapshot chatSnapshot;
  final Animation animation;

  UserEntry({this.chatSnapshot, this.animation});

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.decelerate),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(chatSnapshot.value["photoUrl"]),
            ),
            onTap: () async {
              var userSnapshot = await FirebaseDatabase.instance
                  .reference()
                  .child("user")
                  .child(chatSnapshot.key)
                  .once();

              Navigator.push(
                context,
                MaterialPageRoute(builder: (BuildContext context) {
                  return ChatScreen(userSnapshot);
                }),
              );
            },
            title: Text(chatSnapshot.value["partnerName"] ?? "name"),
            subtitle: Text(
              chatSnapshot.value["lastMessage"] ?? "message",
              maxLines: 1,
              style: TextStyle(
                  //check if user opened chat after last message
                  fontWeight: (chatSnapshot.value["timestampChecked"] == null ||
                          chatSnapshot.value["timestampChecked"] <
                              chatSnapshot.value["timestamp"])
                      ? FontWeight.w900
                      : FontWeight.normal),
            ),
            trailing: Text(
              chatSnapshot.value["time"] ?? "time",
              style: TextStyle(fontSize: 12.0),
            ),
          ),
          Divider(height: 1.0),
        ],
      ),
    );
  }
}
