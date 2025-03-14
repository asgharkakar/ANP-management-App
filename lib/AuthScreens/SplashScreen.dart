import 'package:flutter/material.dart';
import 'package:partyapp/Dashboard/visitersDashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partyapp/AuthScreens/LoginScreen.dart';
import 'package:partyapp/Dashboard/basicunitDashboard.dart';
import 'package:partyapp/Dashboard/centralDashboard.dart';
import 'package:partyapp/Dashboard/districtDashboard.dart';
import 'package:partyapp/Dashboard/provinceDashboard.dart';
import 'package:partyapp/Dashboard/tehsilDashboard.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    String? userEmail = prefs.getString('userEmail');

    await Future.delayed(Duration(seconds: 2)); // Simulate a 2-second delay for the splash screen

    if (isLoggedIn && userEmail != null) {
      // Navigate to the appropriate dashboard based on the user's role
      bool isCentralUser = await _checkUserInCollection("central_ids", userEmail);
      bool isProvincialUser = await _checkUserInCollection("provincial_ids", userEmail);
      bool isDistrictUser = await _checkUserInCollection("district_ids", userEmail);
      bool isTehsilUser = await _checkUserInCollection("tehsil_ids", userEmail);
      bool isBasicunitUser = await _checkUserInCollection("basicunit_ids", userEmail);
      bool isGeneralUser = await _checkUserInCollection("general_ids", userEmail);

      if (isCentralUser) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CentralDashboard()));
      } else if (isProvincialUser) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProvinceDashboard()));
      } else if (isDistrictUser) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DistrictDashboard()));
      } else if (isTehsilUser) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TehsilDashboard()));
      } else if (isBasicunitUser) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BasicUnitDashboard()));
      }
      else if(isGeneralUser){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => visiterDashboard()));
      }

    } else {
      // Navigate to the LoginScreen if the user is not logged in
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  Future<bool> _checkUserInCollection(String collectionName, String email) async {
    QuerySnapshot querySnapshot = await _firestore.collection(collectionName).where("email".toLowerCase(), isEqualTo: email.toLowerCase()).get();
    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.network(
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_0VdHxcBYO8swUKcclsptOwd-Qsitxa6C1Q&s",
          height: 150,
        ),
      ),
    );
  }
}