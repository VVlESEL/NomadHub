import 'package:firebase_database/firebase_database.dart';
import 'package:nomad_hub/ui/settings/login.dart';
import 'package:flutter/foundation.dart';
import 'package:nomad_hub/ui/settings/privacy_policy.dart';
import 'package:nomad_hub/utils/auth.dart';
import 'package:nomad_hub/utils/user.dart';
import 'package:share/share.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nomad_hub/ui/nomads/nomad_profile.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences _prefs;
  String _rangeDesc = "Worldwide";
  String _rangeType = "worldwide";
  double _sliderValue = 3.0;
  bool _isShowLocation = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      setState(() {
        _sliderValue = _prefs.getDouble("rangeValue") ?? _sliderValue;
        _rangeDesc = _prefs.getString("rangeDesc") ?? _rangeDesc;
        _isShowLocation = (prefs.getBool("isShowLocation") ?? _isShowLocation);
        _isLoaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return !_isLoaded
        //waiting for shared prefs
        ? Center(child: CircularProgressIndicator())
        : ListView(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.person_outline),
                title: Text("Profile"),
                onTap: () async {
                  var userSnapshot = await FirebaseDatabase.instance
                      .reference()
                      .child("user")
                      .child(User.uid)
                      .once();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (BuildContext context) {
                      return NomadProfileScreen(userSnapshot);
                    }),
                  );
                },
              ),
              Divider(height: 1.0),
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text("Show Location in Profile"),
                trailing: Switch(
                  value: _isShowLocation,
                  onChanged: (b) {
                    setState(() => _isShowLocation = b);
                    _prefs.setBool("isShowLocation", _isShowLocation);
                    FirebaseDatabase.instance
                        .reference()
                        .child("user")
                        .child(User.uid)
                        .update({"showLocation": _isShowLocation});
                  },
                ),
                onTap: () {
                  setState(() => _isShowLocation = !_isShowLocation);
                  _prefs.setBool("isShowLocation", _isShowLocation);
                  FirebaseDatabase.instance
                      .reference()
                      .child("user")
                      .child(User.uid)
                      .update({"showLocation": _isShowLocation});
                },
              ),
              Divider(height: 1.0),
              ListTile(
                leading: Icon(Icons.gps_fixed),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Range"),
                    Slider(
                        activeColor: Colors.black,
                        inactiveColor: Colors.grey[400],
                        min: 0.0,
                        max: 3.0,
                        value: _sliderValue,
                        divisions: 3,
                        label: "$_rangeDesc",
                        onChanged: (value) {
                          setState(() {
                            _sliderValue = value;
                            if (value == 0.0) {
                              _rangeDesc = User.locality;
                              _rangeType = "locality";
                            } else if (value == 1.0) {
                              _rangeDesc = User.adminArea;
                              _rangeType = "adminArea";
                            } else if (value == 2.0) {
                              _rangeDesc = User.country;
                              _rangeType = "country";
                            } else {
                              _rangeDesc = "Worldwide";
                              _rangeType = "worldwide";
                            }
                          });
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.setDouble("rangeValue", _sliderValue);
                            prefs.setString("rangeDesc", _rangeDesc);
                            prefs.setString("rangeType", _rangeType);
                          });
                        }),
                  ],
                ),
              ),
              Divider(height: 1.0),
              ListTile(
                onTap: () => defaultTargetPlatform == TargetPlatform.android
                    ? Share.share(
                        'Join the nomad community! Search for Nomad Hub in the play store')
                    : Share.share(
                        'Join the nomad community! Search for Nomad Hub in the app store'),
                leading: Icon(Icons.share),
                title: Text("Share this app"),
              ),
              Divider(height: 1.0),
              ListTile(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            PrivacyPolicyScreen())),
                leading: Icon(Icons.info_outline),
                title: Text("Privacy Policy"),
              ),
              Divider(height: 1.0),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text("Sign out"),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Logout?"),
                          content:
                              Text("Are you sure that you want to logout?"),
                          actions: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).buttonColor,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: FlatButton(
                                child: Text(
                                  "Yes",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  Auth.signOut().then((b) {
                                    print("signout $b");
                                    if(b) User.resetUser();
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                LoginScreen()),
                                        (_) => false);
                                  });
                                },
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).buttonColor,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: FlatButton(
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        );
                      });
                },
              ),
              Divider(height: 1.0),
              /*
        ListTile(
          leading: Icon(Icons.delete_forever),
          title: Text("Delete account"),
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Delete account?"),
                    content: Text(
                        "Are you sure that you want to delete your account? This will delete all your data and can not be undone!"),
                    actions: <Widget>[
                      FlatButton(
                        onPressed: () {
                          Auth.deleteUser().then((b) {
                            if (b) {
                              User.resetUser();
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          LoginScreen()),
                                  (_) => false);
                            } else {
                              Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      "Did not work. Please relogin to verify your credentials.")));
                            }
                          });
                        },
                        child: Text("Yes"),
                      ),
                      FlatButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                      )
                    ],
                  );
                });
          },
        ),
        */
            ],
          );
  }
}
