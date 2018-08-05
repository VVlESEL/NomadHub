import 'package:firebase_database/firebase_database.dart';
import 'package:nomad_hub/ui/chat/single_chat.dart';
import 'package:nomad_hub/ui/settings/update_user_profile.dart';
import 'package:nomad_hub/utils/user.dart';
import 'package:flutter/material.dart';

class NomadProfileScreen extends StatefulWidget {
  final DataSnapshot userSnapshot;

  NomadProfileScreen(this.userSnapshot);

  @override
  _NomadProfileScreenState createState() => _NomadProfileScreenState();
}

class _NomadProfileScreenState extends State<NomadProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userSnapshot.value["displayName"]),
        actions: <Widget>[
          //check if profile belongs to current user
          widget.userSnapshot.key.trim() == User.uid.trim()
              ? IconButton(
                  icon: Icon(Icons.mode_edit),
                  onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => ProfileScreen()),
                      ),
                )
              : IconButton(
                  icon: Icon(Icons.message),
                  onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ChatScreen(widget.userSnapshot)),
                      ),
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: CircleAvatar(
                    maxRadius: 75.0,
                    minRadius: 75.0,
                    backgroundImage:
                        NetworkImage(widget.userSnapshot.value["photoUrl"]),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "${
                          widget.userSnapshot.value["displayName"]}, ${widget
                          .userSnapshot.value["age"]}",
                      style: TextStyle(fontSize: 28.0),
                    ),
                  ],
                ),
              )
            ],
          ),
          Padding(padding: const EdgeInsets.symmetric(vertical: 8.0)),
          widget.userSnapshot.value["showLocation"] != null &&
          widget.userSnapshot.value["showLocation"] &&
          widget.userSnapshot.value["location"].toString().isNotEmpty &&
          widget.userSnapshot.value["location"] != null
              ? ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text(widget.userSnapshot.value["location"],
                      style: TextStyle(fontSize: 20.0)),
                )
              : Container(width: 0.0, height: 0.0),
          widget.userSnapshot.value["job"].toString().isNotEmpty &&
                  widget.userSnapshot.value["job"] != null
              ? ListTile(
                  leading: Icon(Icons.work),
                  title: Text(
                    widget.userSnapshot.value["job"],
                    style: TextStyle(fontSize: 20.0),
                  ),
                )
              : Container(width: 0.0, height: 0.0),
          widget.userSnapshot.value["hobbies"].toString().isNotEmpty &&
                  widget.userSnapshot.value["hobbies"] != null
              ? ListTile(
                  leading: Icon(Icons.wb_sunny),
                  title: Text(
                    widget.userSnapshot.value["hobbies"],
                    style: TextStyle(fontSize: 20.0),
                  ),
                )
              : Container(width: 0.0, height: 0.0),
          widget.userSnapshot.value["about"].toString().isNotEmpty &&
                  widget.userSnapshot.value["about"] != null
              ? ListTile(
                  leading: Icon(Icons.info),
                  title: Text(
                    widget.userSnapshot.value["about"],
                    style: TextStyle(fontSize: 20.0),
                  ),
                )
              : Container(width: 0.0, height: 0.0),
          widget.userSnapshot.value["instagram"].toString().isNotEmpty &&
                  widget.userSnapshot.value["instagram"] != null
              ? ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text(
                    widget.userSnapshot.value["instagram"],
                    style: TextStyle(fontSize: 20.0),
                  ),
                )
              : Container(width: 0.0, height: 0.0),
          widget.userSnapshot.value["website"].toString().isNotEmpty &&
                  widget.userSnapshot.value["website"] != null
              ? ListTile(
                  leading: Icon(Icons.public),
                  title: Text(
                    widget.userSnapshot.value["website"],
                    style: TextStyle(fontSize: 20.0),
                  ),
                )
              : Container(width: 0.0, height: 0.0),
        ],
      ),
    );
  }
}
