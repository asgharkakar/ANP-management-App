import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class ViewCentralActivities extends StatefulWidget {
  const ViewCentralActivities({super.key});

  @override
  State<ViewCentralActivities> createState() => _ViewCentralActivitiesState();
}

class _ViewCentralActivitiesState extends State<ViewCentralActivities> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? centralPresidentName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCentralPresidentName();
  }

  Future<void> fetchCentralPresidentName() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        isLoading = false;
        centralPresidentName = "User not logged in";
      });
      return;
    }

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('central_ids') // Correct collection name
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          centralPresidentName = querySnapshot.docs.first['name'] ?? "Unknown";
        });
      } else {
        setState(() {
          centralPresidentName = "President not found";
        });
      }
    } catch (e) {
      print("Error fetching central president name: $e");
      setState(() {
        centralPresidentName = "Error fetching data";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          centralPresidentName ?? "Loading...",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : centralPresidentName == "User not logged in" || centralPresidentName == "Error fetching data"
          ? Center(child: Text(centralPresidentName!))
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("CentralCollection")
            .doc(centralPresidentName) // Use central president's name as document ID
            .collection("Activities")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading activities"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No activities found"));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var activity = snapshot.data!.docs[index];
                List<dynamic> images = activity['pictures'] ?? [];

                return Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.red.shade300, width: 2),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['activityname'] ?? "Unknown Activity",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                        const SizedBox(height: 5),
                        Text(activity['activitydiscription'] ?? "No description available"),
                        const SizedBox(height: 10),
                        if (images.isNotEmpty)
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 200,
                              autoPlay: true,
                              enlargeCenterPage: true,
                            ),
                            items: images.map((base64Image) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  base64Decode(base64Image),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
