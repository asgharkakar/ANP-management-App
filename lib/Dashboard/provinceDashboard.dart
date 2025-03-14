import 'dart:convert'; // Add this import for base64 decoding
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:partyapp/AddUnitActivities/AddProvinceActivites.dart';
import 'package:partyapp/GenetateIDs/DistrictIds.dart';
import 'package:partyapp/NewsFeed/NewsFeedScreen.dart';
import 'package:partyapp/ViewActivities/ViewProvinceActivities.dart';
import 'package:partyapp/ViewActivities/ViewProvinceAllActivities.dart';

class ProvinceDashboard extends StatefulWidget {
  const ProvinceDashboard({super.key});

  @override
  State<ProvinceDashboard> createState() => _ProvinceDashboardState();
}

class _ProvinceDashboardState extends State<ProvinceDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? provinceName;
  String? userName;
  String? profilePicBase64; // Store the base64 string
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProvinceData();
  }

  Future<void> fetchProvinceData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot querySnapshot = await _firestore
          .collection('provincial_ids')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          provinceName = data['province'];
          userName = data['name']; // Fetch the user's name
          profilePicBase64 = data['profilePic']; // Fetch the base64 string
        });
      }
    } catch (e) {
      print("Error fetching province data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
           "Province Dashboard",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: profilePicBase64 != null
                        ? MemoryImage(base64Decode(profilePicBase64!)) // Decode base64 to image
                        : AssetImage("assets/default_avatar.png") as ImageProvider,
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        " $userName!", // Display the user's name
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Manage your province activities",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _dashboardCard(
                    title: "Add Activities",
                    icon: Icons.add_task,
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddProvinceActivities())),
                  ),
                  _dashboardCard(
                    title: "Generate District IDs",
                    icon: Icons.badge,
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GenerateDistrictIDScreen())),
                  ),
                  _dashboardCard(
                    title: "View All Activities",
                    icon: Icons.visibility,
                    color: Colors.green,
                    onTap: provinceName == null
                        ? null
                        : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ViewProvinceAllActivities(provinceName: provinceName!))),
                  ),
                  _dashboardCard(
                    title: "View Province Activities",
                    icon: Icons.assignment,
                    color: Colors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewProvinceActivities())),
                  ),
                  _dashboardCard(
                    title: "News Feed",
                    icon: Icons.newspaper_outlined,
                    color: Colors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NewsFeedScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard({required String title, required IconData icon, required Color color, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}