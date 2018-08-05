import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nomad_hub/utils/user.dart';
import 'package:nomad_hub/utils/image_compressor.dart';
import 'package:nomad_hub/utils/auth.dart';
import 'package:nomad_hub/ui/settings/login.dart';
import 'package:nomad_hub/main.dart';
import 'dart:io';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _hobbiesController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  ImageProvider _image;
  File _imageFile;

  Future<void> _updateImage() async {
    //get new image with ImagePicker
    _imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (_imageFile != null) setState(() => _image = FileImage(_imageFile));
  }

  Future<void> _updateProfile() async {
    //upload file to firebase storage
    String _downloadUrl;
    if (_imageFile != null) {
      //compress file size
      File compressedImage = await compressFile(_imageFile);

      final StorageReference storageReference = FirebaseStorage.instance
          .ref()
          .child("user")
          .child(User.uid)
          .child("photo.png");
      final StorageUploadTask uploadTask =
          storageReference.putFile(compressedImage);

      //update download url variable for user update
      _downloadUrl = (await uploadTask.future).downloadUrl.toString();
    }

    //update firebase auth display name and downloadUrl
    User.updateUser(
      displayName: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      hobbies: _hobbiesController.text.trim(),
      job: _jobController.text.trim(),
      about: _aboutController.text.trim(),
      instagram: _instagramController.text.trim(),
      website: _websiteController.text.trim(),
      photoUrl: _downloadUrl,
    );
  }

  @override
  void initState() {
    super.initState();

    //get initial values for current user
    setState(() {
      _image = NetworkImage(User.photoUrl);
      _nameController.text = User.displayName;
      _ageController.text = User.age?.toString() ?? "";
      _hobbiesController.text = User.hobbies;
      _jobController.text = User.job;
      _aboutController.text = User.about;
      _instagramController.text = User.instagram;
      _websiteController.text = User.website;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              //logout and go back to login screen if user does not provide any information
              if (User.displayName == null) {
                Auth.signOut().then((b) {
                  if (b)
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => LoginScreen()),
                        (_) => false);
                });
              } else {
                _onWillPop().then((b) {
                  if (b) Navigator.pop(context);
                });
              }
            },
          ),
          title: Text("Profile"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  if (User.displayName == null) {
                    await _updateProfile();
                    Navigator.push(context,
                        MaterialPageRoute(builder: (BuildContext context) {
                      return MainScaffold();
                    }));
                  } else {
                    _updateProfile();
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: <Widget>[
              FlatButton(
                onPressed: _updateImage,
                child: Center(
                  child: CircleAvatar(
                          maxRadius: 75.0,
                          minRadius: 75.0,
                          backgroundImage: _image ?? Image.asset("images/icon_photo.png"),
                        ),
                ),
              ),
              Text(
                "Name",
                style: _titleStyle,
              ),
              TextFormField(
                controller: _nameController,
                validator: (text) {
                  if (text.isEmpty) return "Please enter your name";
                },
                decoration: InputDecoration(
                  hintText: "Type your display name here",
                  hintStyle: _titleStyle,
                ),
              ),
              Padding(padding: const EdgeInsets.all(8.0)),
              Text(
                "Age",
                style: _titleStyle,
              ),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                validator: (text) {
                  if (int.tryParse(text) == null) return "Please enter your age";
                },
                decoration: InputDecoration(
                  hintText: "Enter your age here",
                  hintStyle: _titleStyle,
                ),
              ),
              Padding(padding: const EdgeInsets.all(8.0)),
              Text(
                "Hobbies",
                style: _titleStyle,
              ),
              TextFormField(
                controller: _hobbiesController,
                decoration: InputDecoration(
                  hintText: "Type your hobbies here",
                  hintStyle: _titleStyle,
                ),
              ),
              Padding(padding: const EdgeInsets.all(8.0)),
              Text(
                "Job",
                style: _titleStyle,
              ),
              TextFormField(
                controller: _jobController,
                validator: (text) {
                  if (text.isEmpty) return "Please enter your job";
                },
                decoration: InputDecoration(
                  hintText: "Do you work and/or travel?",
                  hintStyle: _titleStyle,
                ),
              ),
              Padding(padding: const EdgeInsets.all(8.0)),
              Text(
                "About",
                style: _titleStyle,
              ),
              TextFormField(
                controller: _aboutController,
                validator: (text) {
                  if (text.isEmpty) return "Please tell us something about you";
                },
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "What describes you and your skills the best?",
                  hintStyle: _titleStyle,
                ),
              ),
              Padding(padding: const EdgeInsets.all(8.0)),
              Text(
                "Instagram",
                style: _titleStyle,
              ),
              TextFormField(
                controller: _instagramController,
                decoration: InputDecoration(
                  hintText: "@johndoe",
                  hintStyle: _titleStyle,
                ),
              ),
              Padding(padding: const EdgeInsets.all(8.0)),
              Text(
                "Website",
                style: _titleStyle,
              ),
              TextFormField(
                controller: _websiteController,
                decoration: InputDecoration(
                  hintText: "https://www.",
                  hintStyle: _titleStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _titleStyle {
    return TextStyle(
      fontSize: 14.0,
      color: Colors.grey,
    );
  }

  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
                title: new Text("Unsafed Changes?"),
                content: new Text(
                    "You might have unsaved changes. If you go back they will not be applied."),
                actions: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).buttonColor,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: FlatButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: new Text(
                        "Go back",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
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
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }
}
