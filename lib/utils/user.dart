import 'package:flutter/material.dart';
import 'package:nomad_hub/utils/auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class User {
  static DatabaseReference userReference;
  static FirebaseMessaging firebaseMessaging;

  static String uid;
  static String email;
  static String displayName;
  static int age;
  static String hobbies;
  static String job;
  static String about;
  static String instagram;
  static String website;
  static double latitude;
  static double longitude;
  static String location;
  static String locality;
  static String adminArea;
  static String country;

  //placeholder photo
  static String photoUrl = "https://firebasestorage.googleapis.com/v0/b/"
      "digitalnomad-a5cac.appspot.com/o/app%2Fphoto.png?alt=media&token="
      "4078f781-5e53-4e40-9b5b-5fa3f291b8d5";

  //initializes the user with all the user specific data from auth and database
  static Future<bool> initialize() async {
    //enable database caching
    FirebaseDatabase.instance.setPersistenceEnabled(true);

    //get user data from auth
    await Auth.auth.currentUser().then((user) {
      uid = user.uid;
      email = user.email;
      print("User initialize! uid: $uid email: $email");
    }).catchError((error) {
      print(
          "User initialize! Something went wrong (auth)! ${error.toString()}");
    });

    //get reference to the user db entry
    userReference =
        FirebaseDatabase.instance.reference().child("user").child(User.uid);

    //keep user data synched
    userReference.keepSynced(true);

    //setup gps listener
    Location().onLocationChanged.listen((currentLocation) async {
      //update current coordinates
      latitude = currentLocation["latitude"];
      longitude = currentLocation["longitude"];
    });

    //setup fcm
    firebaseMessaging = FirebaseMessaging();
    try {
      firebaseMessaging.requestNotificationPermissions();

      firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) {},
        onResume: (Map<String, dynamic> message) {
          //triggers if app runs in background
          String from = message["from"];
          if(from.contains("topics")){
            from = from.substring(7);
            //push to the post
          }else{
            print(message.toString());
            //push to comment section
          }
        },
        onLaunch: (Map<String, dynamic> message) {
          //triggers if app is not active
        },
      );

      var token = await firebaseMessaging.getToken().timeout(Duration(milliseconds: 1500));
      userReference.update({"fcm_token": token}).then((b) {
        print("User initialize! FCM token: $token");
      }).catchError((error) {
        print("User initialize! FCM token update failed!");
      });
    } catch (error) {
      print("User initialize! Something went wrong (fmc token)! ${error
          .toString()}");
    }

    //get data from user database
    await userReference.once().then((DataSnapshot snapshot) {
      displayName = snapshot.value["displayName"];
      age = snapshot.value["age"];
      hobbies = snapshot.value["hobbies"];
      job = snapshot.value["job"];
      about = snapshot.value["about"];
      instagram = snapshot.value["instagram"];
      website = snapshot.value["website"];
      latitude = snapshot.value["latitude"];
      longitude = snapshot.value["longitude"];
      location = snapshot.value["location"];
      locality = snapshot.value["locality"];
      adminArea = snapshot.value["adminArea"];
      country = snapshot.value["country"];
      if (snapshot.value["photoUrl"] != null &&
          snapshot.value["photoUrl"] != "")
        photoUrl = snapshot.value["photoUrl"];

      print("User initialize! displayName: $displayName about: $about "
          "website: $website photoUrl: $photoUrl");
    }).catchError((error) {
      print("User initialize! Something went wrong (database)! ${error
          .toString()}");
    });

    return displayName != null;
  }

  static void resetUser() {
    userReference = null;
    firebaseMessaging = null;
    uid = null;
    email = null;
    displayName = null;
    age = null;
    hobbies = null;
    job = null;
    about = null;
    instagram = null;
    website = null;
    latitude = null;
    longitude = null;
    location = null;
    locality = null;
    adminArea = null;
    country = null;

    //placeholder photo
    photoUrl = "https://firebasestorage.googleapis.com/v0/b/"
        "digitalnomad-a5cac.appspot.com/o/app%2Fphoto.png?alt=media&token="
        "4078f781-5e53-4e40-9b5b-5fa3f291b8d5";
  }

  static Future<void> updateUser({
    @required String displayName,
    @required int age,
    @required String hobbies,
    @required String job,
    @required String about,
    @required String instagram,
    @required String website,
    @required String photoUrl,
  }) async {
    //update user database
    try {
      await User.userReference.update({
        "displayName": "$displayName",
        "age": age,
        "hobbies": "$hobbies",
        "job": "$job",
        "about": "$about",
        "instagram": "$instagram",
        "website": "$website",
        "photoUrl": (photoUrl ?? User.photoUrl),
      });

      User.displayName = displayName;
      User.age = age;
      User.hobbies = hobbies;
      User.job = job;
      User.about = about;
      User.instagram = instagram;
      User.website = website;
      if (photoUrl != null) User.photoUrl = photoUrl;
      print("User updateProfile!  displayName: $displayName "
          "about: $about website: $website photoUrl: ${User.photoUrl}");
    } catch (error) {
      print("User updateProfile! Something went wrong! ${error.toString()}");
    }
  }

  static Future<bool> updateLocation() async {
    try {
      //check if gps is active
      Location().getLocation;
      //setup gps listener
      Location().onLocationChanged.listen((currentLocation) async {
        //update current coordinates
        latitude = currentLocation["latitude"];
        longitude = currentLocation["longitude"];
      });

      if (latitude == null || longitude == null) {
        print("User updateLocation! Unable to receive current location!");
        return false;
      }

      //get location of coordinates
      final address = await Geocoder.local
          .findAddressesFromCoordinates(Coordinates(latitude, longitude));
      location = "${address.first.locality}, "
          "${address.first.adminArea}, "
          "${address.first.countryName}";
      locality = address.first.locality;
      adminArea = address.first.adminArea;
      country = address.first.countryName;

      //update user database
      await userReference.update({
        "latitude": latitude,
        "longitude": longitude,
        "location": location,
        "locality": address.first.locality,
        "adminArea": address.first.adminArea,
        "country": address.first.countryName
      }).then((res) {
        print("User updateLocation! latitude: $latitude "
            "longitude: $longitude "
            "location: $location");
      });
    } catch (error) {
      print("User updateLocation! Something went wrong! ${error.toString()}");
      return false;
    }

    return true;
  }
}
