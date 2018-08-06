import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomad_hub/utils/calculations.dart';
import 'package:nomad_hub/ui/chat/single_chat.dart';
import 'package:nomad_hub/utils/user.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:nomad_hub/ui/nomads/nomad_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NomadsScreen extends StatefulWidget {
  @override
  _NomadsScreenState createState() => _NomadsScreenState();
}

class _NomadsScreenState extends State<NomadsScreen> {
  Query _databaseReference;
  bool _isLocated;
  String _rangeDesc;
  String _rangeType;

  @override
  void initState() {
    super.initState();

    //get max distance from shared prefs?
    //get range from shared preferences
    SharedPreferences.getInstance().then((prefs) {
      _rangeDesc = prefs.getString("rangeDesc") ?? "Worldwide";
      _rangeType = prefs.getString("rangeType") ?? "worldwide";
      if (_rangeType == "worldwide") {
        _databaseReference =
            FirebaseDatabase.instance.reference().child("user");
      } else {
        _databaseReference = FirebaseDatabase.instance
            .reference()
            .child("user")
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
    return _isLocated == null
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
        : Container(
      child: FirebaseAnimatedList(
        query: _databaseReference,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemBuilder: (_, DataSnapshot userSnapshot,
            Animation<double> animation, int pos) {
          return ((User.uid == userSnapshot.key ||
              userSnapshot.value["photoUrl"] == null ||
              userSnapshot.value["displayName"] == null ||
              userSnapshot.value["latitude"] == null ||
              userSnapshot.value["longitude"] == null)
              ? Container(height: 0.0, width: 0.0)
              : UserEntry(
            userSnapshot: userSnapshot,
            animation: animation,
          ));
        },
      ),
    ));
  }
}

class UserEntry extends StatelessWidget {
  final DataSnapshot userSnapshot;
  final Animation animation;

  UserEntry({this.userSnapshot, this.animation});

  @override
  Widget build(BuildContext context) {
    //validate snapshot data
    var latitude = userSnapshot.value["latitude"];
    var longitude = userSnapshot.value["longitude"];

    if (latitude == null || longitude == null)
      return Container(width: 0.0, height: 0.0,);

    //get distance between user and other nomad
    double distance = distanceInKmBetweenEarthCoordinates(
        latitude, longitude, User.latitude, User.longitude);

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.decelerate),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(userSnapshot.value["photoUrl"]),
            ),
            title: Text(userSnapshot.value["displayName"]),
            subtitle: distance < 3
                ? Text("< 3 KM")
                : Text("${distance.toStringAsFixed(0)} KM"),
            trailing: PopupMenuButton(
                itemBuilder: (BuildContext context) =>
                <PopupMenuItem<String>>[
                  PopupMenuItem(
                    child: FlatButton(
                        child: Text("Profile"),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) {
                                  return NomadProfileScreen(userSnapshot);
                                }),
                          );
                        }),
                  ),
                  PopupMenuItem(
                    child: FlatButton(
                        child: Text("Chat"),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) {
                                  return ChatScreen(userSnapshot);
                                }),
                          );
                        }),
                  ),
                ]),
          ),
          Divider(height: 1.0),
        ],
      ),
    );
  }
}