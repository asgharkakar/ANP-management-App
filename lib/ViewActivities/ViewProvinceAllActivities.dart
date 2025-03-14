import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewProvinceAllActivities extends StatefulWidget {
  final String provinceName;

  const ViewProvinceAllActivities({super.key, required this.provinceName});

  @override
  State<ViewProvinceAllActivities> createState() => _ViewProvinceAllActivitiesState();
}

class _ViewProvinceAllActivitiesState extends State<ViewProvinceAllActivities> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.provinceName} - Activities"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('district_ids')
            .where('province', isEqualTo: widget.provinceName)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var districts = snapshot.data!.docs;
          return ListView(
            children: districts.map((doc) {
              String districtName = doc['district'];
              return ExpansionTile(
                title: Text("📍 District: $districtName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                children: [
                  DistrictActivities(districtName: districtName),
                  ViewTehsilAllActivities(districtName: districtName),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class DistrictActivities extends StatelessWidget {
  final String districtName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  DistrictActivities({super.key, required this.districtName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("DistrictCollection")
          .doc(districtName)
          .collection("Activities")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No district activities found."),
          );
        }
        return ActivityList(snapshot: snapshot);
      },
    );
  }
}

class ViewTehsilAllActivities extends StatelessWidget {
  final String districtName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ViewTehsilAllActivities({super.key, required this.districtName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('tehsil_ids').where('district', isEqualTo: districtName).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No tehsils found."),
          );
        }
        var tehsils = snapshot.data!.docs;
        return Column(
          children: tehsils.map((doc) {
            String tehsilName = doc['tehsil'];
            return ExpansionTile(
              title: Text("📍 Tehsil: $tehsilName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              children: [
                TehsilActivities(tehsilName: tehsilName),
                ViewUnitAllActivities(tehsilName: tehsilName),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class TehsilActivities extends StatelessWidget {
  final String tehsilName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  TehsilActivities({super.key, required this.tehsilName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("TehsilCollection")
          .doc(tehsilName)
          .collection("Activities")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No tehsil activities found."),
          );
        }
        return ActivityList(snapshot: snapshot);
      },
    );
  }
}

class ViewUnitAllActivities extends StatelessWidget {
  final String tehsilName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ViewUnitAllActivities({super.key, required this.tehsilName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('basicunit_ids').where('tehsil', isEqualTo: tehsilName).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No units found."),
          );
        }
        var units = snapshot.data!.docs;
        return Column(
          children: units.map((doc) {
            String unitName = doc['basicunit'];
            return ExpansionTile(
              title: Text("📍 Unit: $unitName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              children: [UnitActivities(unitName: unitName)],
            );
          }).toList(),
        );
      },
    );
  }
}

class UnitActivities extends StatelessWidget {
  final String unitName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  UnitActivities({super.key, required this.unitName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("UnitCollection")
          .doc(unitName)
          .collection("Activities")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No activities found."),
          );
        }
        return ActivityList(snapshot: snapshot);
      },
    );
  }
}

class ActivityList extends StatelessWidget {
  final AsyncSnapshot<QuerySnapshot> snapshot;

  const ActivityList({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: snapshot.data!.docs.map((activity) {
        var activityData = activity.data() as Map<String, dynamic>?;

        String activityName = activityData?['activityname'] ?? 'Unknown Activity';
        String activityDescription = activityData?['activitydiscription'] ?? 'No description available';
        Timestamp? timestamp = activityData?['timestamp'];
        List<dynamic>? pictures = activityData?['pictures'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityName,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(activityDescription),
                if (pictures != null && pictures.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: 200,
                        enlargeCenterPage: true,
                        autoPlay: true,
                        aspectRatio: 16 / 9,
                        viewportFraction: 0.8,
                      ),
                      items: pictures.map((imageBase64) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(imageBase64),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    timestamp != null ? _formatTimestamp(timestamp) : '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute}";
  }
}

