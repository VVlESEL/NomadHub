import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:nomad_hub/utils/themes.dart';
import 'package:nomad_hub/ui/chat/chats.dart';
import 'package:nomad_hub/ui/home/home.dart';
import 'package:nomad_hub/utils/auth.dart';
import 'package:nomad_hub/utils/user.dart';
import 'package:nomad_hub/ui/settings/settings.dart';
import 'package:nomad_hub/ui/settings/login.dart';
import 'package:nomad_hub/ui/nomads/nomads.dart';
import 'package:nomad_hub/ui/settings/update_user_profile.dart';
import 'package:firebase_database/firebase_database.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    title: "Nomad Hub",
    theme: Themes.defaultTheme,
    home: MainScaffold(),
  ));
}

class MainScaffold extends StatefulWidget {
  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  bool _isSignedIn;
  bool _isInitialized;
  bool _isTimeout = false;
  bool _isNewMessage = false;
  int _menuIndex = 0;

  @override
  void initState() {
    super.initState();
    _initUserOperations();
  }

  void _initUserOperations() async {
    await Auth.checkSignIn().then((b) async {
      setState(() => _isSignedIn = b);
      //get user specific data
      if (_isSignedIn) {
        await User.initialize().then((b) {
          setState(() => _isInitialized = b);
        });
      } else {
        _isInitialized = false;
      }
      Timer(Duration(seconds: 5), () {
        if (_isSignedIn == null || _isInitialized == null) {
          setState(() => _isTimeout = true);
        }
      });
    });

    if(!_isInitialized) return;

    var userReference = FirebaseDatabase.instance
        .reference()
        .child("user")
        .child(User.uid);

    //check for new messages on application start
    _isNewMessage = false;

    userReference.once().then((snapshot) {
      var messages = snapshot.value["newMessages"];
      if(messages != null && messages > 0){
        setState(() => _isNewMessage = true);
      }
    });

    //set listener for new chat messages
    userReference.child("newMessages").onValue.listen((Event event) {
      if(event.snapshot.value > 0){
        setState(() => _isNewMessage = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isSignedIn == null || _isInitialized == null
        ? Stack(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("images/loadscreen_small.jpg"),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              _isTimeout
                  ? Center(
                      child: Container(
                        height: 100.0,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        ),
                        child: FlatButton(
                          onPressed: () {
                            setState(() => _isTimeout = false);
                            _initUserOperations();
                          },
                          child: Text(
                            "Connection failed. Try again? \n\nSure!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(width: 0.0, height: 0.0),
            ],
          )
        : (!_isSignedIn
            ? LoginScreen()
            : (User.displayName == null
                ? ProfileScreen()
                : Scaffold(
                    appBar: AppBar(
                      title: Image.asset("images/icon_nomad_hub_vertical.png"),
                    ),
                    body: Container(child: _getBody()),
                      bottomNavigationBar: BottomNavigationBar(
                        fixedColor: Colors.black,
                        currentIndex: _menuIndex,
                      onTap: (int index) {
                        setState(() {
                          _menuIndex = index;
                        });
                      },
                      //update body widget
                      type: BottomNavigationBarType.fixed,
                      items: <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          title: Text("Home"),
                          icon: Icon(Icons.home),
                        ),
                        BottomNavigationBarItem(
                          title: Text("Nomads"),
                          icon: Icon(Icons.people),
                        ),
                        BottomNavigationBarItem(
                          title: Text("Chat"),
                          icon: _isNewMessage
                              ? Icon(Icons.notifications_active, color: Colors.redAccent,)
                              : Icon(Icons.chat),
                        ),
                        BottomNavigationBarItem(
                          title: Text("Settings"),
                          icon: Icon(Icons.settings),
                        ),
                      ],
                    ),
                  )));
  }

  Widget _getBody() {
    switch (_menuIndex) {
      case 0:
        return HomeScreen();
      case 1:
        return NomadsScreen();
      case 2:
        setState(() => _isNewMessage = false);
        return ChatsScreen();
      case 3:
        return SettingsScreen();
      default:
        return Container();
    }
  }
}
