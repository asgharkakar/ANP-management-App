import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ViewUnitAllActivities extends StatefulWidget {
  final String tehsilName;

  const ViewUnitAllActivities({super.key, required this.tehsilName});

  @override
  State<ViewUnitAllActivities> createState() => _ViewUnitAllActivitiesState();
}

class _ViewUnitAllActivitiesState extends State<ViewUnitAllActivities> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> unitNames = [];

  @override
  void initState() {
    super.initState();
    fetchUnitNames();
  }

  Future<void> fetchUnitNames() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('basicunit_ids')
          .where('tehsil', isEqualTo: widget.tehsilName)
          .get();

      setState(() {
        unitNames = querySnapshot.docs
            .map((doc) => doc['basicunit'].toString())
            .toList();
      });
    } catch (e) {
      print("Error fetching unit names: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.tehsilName} - Unit Activities"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: unitNames.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: unitNames.length,
        itemBuilder: (context, index) {
          String unitName = unitNames[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                child: Text(
                  "📌 Unit: $unitName",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection("UnitCollection")
                    .doc(unitName)
                    .collection("Activities")
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text("No activities found."),
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((activity) {
                      List<dynamic> images = activity['pictures'] ?? [];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['activityname'],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
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
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
