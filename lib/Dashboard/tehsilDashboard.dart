import 'dart:convert'; // Add this import for base64 decoding
import 'package:flutter/material.dart';
import 'package:partyapp/AddUnitActivities/AddTehsilActivites.dart';
import 'package:partyapp/GenetateIDs/basicunitsIds.dart';
import 'package:partyapp/NewsFeed/NewsFeedScreen.dart';
import 'package:partyapp/ViewActivities/ViewAllActivites.dart';
import 'package:partyapp/ViewActivities/ViewTehsilActivities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TehsilDashboard extends StatefulWidget {
  const TehsilDashboard({super.key});

  @override
  State<TehsilDashboard> createState() => _TehsilDashboardState();
}

class _TehsilDashboardState extends State<TehsilDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String tehsilName = "";
  String? userName;
  String? profilePicBase64; // Store the base64 string
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTehsilData();
  }

  Future<void> fetchTehsilData() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('tehsil_ids')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          tehsilName = data['tehsil'];
          userName = data['name']; // Fetch the user's name
          profilePicBase64 = data['profilePic']; // Fetch the base64 string
        });
      }
    } catch (e) {
      print("Error fetching tehsil data: $e");
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
        title: Text( "Tehsil Dashboard", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
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
                        "$userName!", // Display the user's name
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Manage your tehsil activities",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dashboard Cards
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
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddTehsilActivities())),
                  ),
                  _dashboardCard(
                    title: "Generate IDs",
                    icon: Icons.badge,
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GenerateBasicUnitIDScreen())),
                  ),
                  _dashboardCard(
                    title: "View Activities",
                    icon: Icons.visibility,
                    color: Colors.green,
                    onTap: tehsilName.isEmpty
                        ? null
                        : () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewUnitAllActivities(tehsilName: tehsilName))),
                  ),
                  _dashboardCard(
                    title: "Tehsil Activities",
                    icon: Icons.assignment,
                    color: Colors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewTehsilActivities())),
                  ),
                  _dashboardCard(
                    title: "News Feed",
                    icon: Icons.assignment,
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