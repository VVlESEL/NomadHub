import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nomad_hub/utils/user.dart';
import 'package:intl/intl.dart';

class NewPostScreen extends StatefulWidget {
  @override
  _NewPostScreenState createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _databaseReference =
      FirebaseDatabase.instance.reference().child("broadcast");
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();
  String _radioValue = "work";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Post"),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              if (_formKey.currentState.validate()) {
                final ref = _databaseReference.push()..set({
                  "senderUid": User.uid,
                  "senderName": User.displayName,
                  "latitude": User.latitude,
                  "longitude": User.longitude,
                  "locality": User.locality,
                  "adminArea": User.adminArea,
                  "country": User.country,
                  "text": _textController.text.trim(),
                  "topic": _radioValue,
                  "time": DateFormat.yMd().add_Hm().format(DateTime.now()),
                  "commentsCounter": 0
                });

                //subscribe to topic for notifications
                User.firebaseMessaging.subscribeToTopic(ref.key);

                Navigator.pop(context);
              }
            },
            child: Row(
              children: <Widget>[
                Text("Share"),
                Padding(padding: const EdgeInsets.only(left: 10.0)),
                Icon(Icons.send),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            TextFormField(
              controller: _textController,
              maxLines: 12,
              validator: (text) {
                if (text.length < 5 || text.length > 500)
                  return "Please write between 5 and 200 letters";
              },
              decoration: InputDecoration(
                  hintText:
                      "Share something with near nomads. \n\nYou can ask "
                      "for help, \ntell a joke, \nask to hang out... ;)"),
            ),
            Row(
              children: <Widget>[
                Text("Topic:"),
                Row(children: <Widget>[
                  Radio(
                    onChanged: (value) => setState(() => _radioValue = "work"),
                    value: "work",
                    groupValue: _radioValue,
                  ),
                  Text("Work"),
                ]),
                Row(children: <Widget>[
                  Radio(
                    onChanged: (value) => setState(() => _radioValue = "fun"),
                    value: "fun",
                    groupValue: _radioValue,
                  ),
                  Text("Fun"),
                ]),
                Row(children: <Widget>[
                  Radio(
                    onChanged: (value) => setState(() => _radioValue = "event"),
                    value: "event",
                    groupValue: _radioValue,
                  ),
                  Text("Event"),
                ]),
              ],
            )
          ],
        ),
      ),
    );
  }
}
