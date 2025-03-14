import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:partyapp/AuthScreens/SingupScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Dashboard/basicunitDashboard.dart';
import '../Dashboard/centralDashboard.dart';
import '../Dashboard/districtDashboard.dart';
import '../Dashboard/provinceDashboard.dart';
import '../Dashboard/tehsilDashboard.dart';
import '../Dashboard/visitersDashboard.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a method to check if the user is already logged in
  Future<void> checkLoginState(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    String? userEmail = prefs.getString('userEmail');

    if (isLoggedIn && userEmail != null) {
      // Navigate to the appropriate dashboard based on the user's role
      bool isCentralUser = await checkUserInCollection("central_ids", userEmail);
      bool isProvincialUser = await checkUserInCollection("provincial_ids", userEmail);
      bool isDistrictUser = await checkUserInCollection("district_ids", userEmail);
      bool isTehsilUser = await checkUserInCollection("tehsil_ids", userEmail);
      bool isBasicunitUser = await checkUserInCollection("basicunit_ids", userEmail);

      bool isGeneralUser = await checkUserInCollection("general_ids", userEmail);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check the login state when the widget is built
    checkLoginState(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.network("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_0VdHxcBYO8swUKcclsptOwd-Qsitxa6C1Q&s",
                  height: 100,),
                SizedBox(height: 20),
                Text(
                  "ANP Management App",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      UserCredential userCredential = await _auth
                          .signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                      // Save the login state and user email in SharedPreferences
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', true);
                      await prefs.setString('userEmail', emailController.text.trim());

                      String email = emailController.text.trim();
                      bool isCentralUser = await checkUserInCollection("central_ids", email);
                      bool isProvincialUser = await checkUserInCollection("provincial_ids", email);
                      bool isDistrictUser = await checkUserInCollection("district_ids", email);
                      bool isTehsilUser = await checkUserInCollection("tehsil_ids", email);
                      bool isBasicunitUser = await checkUserInCollection("basicunit_ids", email);

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
                    } catch (e) {
                      print("Error: $e");
                    }
                  },
                  child: Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>SignupScreen()),
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> checkUserInCollection(String collectionName, String email) async {
    QuerySnapshot querySnapshot = await _firestore.collection(collectionName).where("email".toLowerCase(), isEqualTo: email.toLowerCase()).get();
    return querySnapshot.docs.isNotEmpty;
  }
}