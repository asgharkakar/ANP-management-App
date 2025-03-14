import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ViewTehsilActivities extends StatefulWidget {
  const ViewTehsilActivities({super.key});

  @override
  State<ViewTehsilActivities> createState() => _ViewTehsilActivitiesState();
}

class _ViewTehsilActivitiesState extends State<ViewTehsilActivities> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? tehsilName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTehsilName();
  }

  Future<void> fetchTehsilName() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('tehsil_ids')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          tehsilName = querySnapshot.docs.first['tehsil'];
        });
      } else {
        print("Tehsil not found");
      }
    } catch (e) {
      print("Error fetching tehsil name: $e");
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
          tehsilName != null ? "$tehsilName Activities" : "Loading...",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tehsilName == null
          ? const Center(child: Text("Tehsil not found"))
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("TehsilCollection")
            .doc(tehsilName)
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
                          activity['activityname'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 5),
                        Text(activity['activitydiscription']),
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
