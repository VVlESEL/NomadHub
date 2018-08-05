import 'dart:async';
import 'package:nomad_hub/utils/calculations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomad_hub/utils/user.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nomad_hub/ui/home/post.dart';
import 'package:nomad_hub/ui/nomads/nomad_profile.dart';
import 'package:nomad_hub/ui/home/comments.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Query _databaseReference;
  bool _isLocated;
  String _rangeDesc;
  String _rangeType;

  @override
  void initState() {
    super.initState();

    //get range from shared preferences
    SharedPreferences.getInstance().then((prefs) {
      _rangeDesc = prefs.getString("rangeDesc") ?? "Worldwide";
      _rangeType = prefs.getString("rangeType") ?? "worldwide";
      if (_rangeType == "worldwide") {
        _databaseReference =
            FirebaseDatabase.instance.reference().child("broadcast");
      } else {
        _databaseReference = FirebaseDatabase.instance
            .reference()
            .child("broadcast")
            .orderByChild(_rangeType)
            .equalTo(_rangeDesc);
      }
    });

    User.updateLocation().then((b) {
      if (mounted) setState(() => _isLocated = b);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLocated == null || _databaseReference == null
        //position not updated yet
        ? Center(child: CircularProgressIndicator())
        : (!_isLocated
            //unable to update position
            ? Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Unable to find your position. Try again?"),
                  FlatButton(
                    onPressed: () {
                      setState(() => _isLocated = null);
                      User.updateLocation().then((b) {
                        setState(() => _isLocated = b);
                      });
                    },
                    child: Text("Sure!"),
                  )
                ],
              ))
            //updated position
            : Stack(
                children: <Widget>[
                  FirebaseAnimatedList(
                    query: _databaseReference,
                    sort: (a, b) => b.value["time"].compareTo(a.value["time"]),
                    itemBuilder: (_, DataSnapshot messageSnapshot,
                        Animation<double> animation, int pos) {
                      return (MessageCard(
                        messageSnapshot: messageSnapshot,
                        animation: animation,
                      ));
                    },
                  ),
                  Container(
                    child: FloatingActionButton(
                      onPressed: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (BuildContext context) {
                            return NewPostScreen();
                          })),
                      child: Icon(Icons.add,
                          size: 50.0, color: Theme.of(context).accentColor),
                      tooltip: "New post",
                      backgroundColor: Colors.white,
                    ),
                    alignment: Alignment.bottomRight,
                    margin: const EdgeInsets.all(10.0),
                  ),
                ],
              ));
  }
}

class MessageCard extends StatelessWidget {
  final DataSnapshot messageSnapshot;
  final Animation animation;

  MessageCard({this.messageSnapshot, this.animation});

  @override
  Widget build(BuildContext context) {
    //get position of post
    double latitude = messageSnapshot.value["latitude"];
    double longitude = messageSnapshot.value["longitude"];

    //get distance between user and other nomad
    double distance = distanceInKmBetweenEarthCoordinates(
        latitude, longitude, User.latitude, User.longitude);

    //get the background color depending on the topic
    Color backgroundColor;
    switch (messageSnapshot.value["topic"].toString().toLowerCase()) {
      case "work":
        backgroundColor = Colors.redAccent[100];
        break;
      case "fun":
        backgroundColor = Colors.yellowAccent[100];
        break;
      case "event":
        backgroundColor = Colors.blueAccent[100];
        break;
    }

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.decelerate),
      child: Card(
        color: backgroundColor,
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
                        .child(messageSnapshot.value["senderUid"])
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
                        child: FutureBuilder<String>(
                            future: _getPhotoUrl(),
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              if (snapshot.hasData) {
                                return CircleAvatar(
                                  backgroundImage: NetworkImage(snapshot.data),
                                );
                              } else {
                                return CircleAvatar();
                              }
                            }),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(messageSnapshot.value["senderName"]),
                          Text(messageSnapshot.value["time"],
                              style: TextStyle(fontSize: 10.0)),
                          Text(
                              distance < 3.0
                                  ? "< 3 KM"
                                  : "${distance.toStringAsFixed(0)} KM",
                              style: TextStyle(fontSize: 10.0)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: Container(height: 0.0, width: 0.0)),
                messageSnapshot.value["senderUid"] != User.uid
                    ? Container(height: 0.0, width: 0.0)
                    : PopupMenuButton(
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuItem<String>>[
                              PopupMenuItem(
                                child: FlatButton(
                                    child: Text("Delete"),
                                    onPressed: () {
                                      FirebaseDatabase.instance
                                          .reference()
                                          .child("broadcast")
                                          .child(messageSnapshot.key)
                                          .remove();
                                      Navigator.pop(context);
                                    }),
                              ),
                            ]),
              ],
            ),
            new Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(messageSnapshot.value["text"]),
            ),
            FlatButton(
              onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (BuildContext context) {
                    return SinglePostScreen(
                        messageSnapshot, distance, backgroundColor);
                  })),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Icon(
                    Icons.message,
                    size: 20.0,
                  ),
                  Padding(padding: const EdgeInsets.only(right: 8.0),),
                  Text(messageSnapshot.value["commentsCounter"]?.toString() ?? "0"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getPhotoUrl() async {
    var reference = await FirebaseDatabase.instance
        .reference()
        .child("user")
        .child(messageSnapshot.value["senderUid"])
        .once();

    return reference.value["photoUrl"];
  }
}
