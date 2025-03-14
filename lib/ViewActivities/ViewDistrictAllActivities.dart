import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ViewDistrictAllActivities extends StatefulWidget {
  final String districtName;

  const ViewDistrictAllActivities({super.key, required this.districtName});

  @override
  State<ViewDistrictAllActivities> createState() => _ViewDistrictAllActivitiesState();
}

class _ViewDistrictAllActivitiesState extends State<ViewDistrictAllActivities> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> tehsilNames = [];

  @override
  void initState() {
    super.initState();
    fetchTehsilNames();
  }

  Future<void> fetchTehsilNames() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('tehsil_ids')
          .where('district', isEqualTo: widget.districtName)
          .get();

      setState(() {
        tehsilNames = querySnapshot.docs
            .map((doc) => doc['tehsil'].toString())
            .toList();
      });
    } catch (e) {
      print("Error fetching tehsil names: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.districtName} - Tehsil Activities"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: tehsilNames.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: tehsilNames.length,
        itemBuilder: (context, index) {
          String tehsilName = tehsilNames[index];
          return TehsilActivityCard(tehsilName: tehsilName, firestore: _firestore);
        },
      ),
    );
  }
}

class TehsilActivityCard extends StatelessWidget {
  final String tehsilName;
  final FirebaseFirestore firestore;

  const TehsilActivityCard({super.key, required this.tehsilName, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.red, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Text(
              "📍 Tehsil: $tehsilName",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection("TehsilCollection")
                .doc(tehsilName)
                .collection("Activities")
                .orderBy("timestamp", descending: true)
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
          ),
          ViewUnitAllActivities(tehsilName: tehsilName),
        ],
      ),
    );
  }
}

class ViewUnitAllActivities extends StatelessWidget {
  final String tehsilName;

  const ViewUnitAllActivities({super.key, required this.tehsilName});

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('basicunit_ids').where('tehsil', isEqualTo: tehsilName).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No units found in this tehsil."),
          );
        }
        List<String> unitNames = snapshot.data!.docs.map((doc) => doc['basicunit'].toString()).toList();
        return Column(
          children: unitNames.map((unitName) => UnitActivityCard(unitName: unitName, firestore: firestore)).toList(),
        );
      },
    );
  }
}

class UnitActivityCard extends StatelessWidget {
  final String unitName;
  final FirebaseFirestore firestore;

  const UnitActivityCard({super.key, required this.unitName, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.red.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Text(
              "📌 Unit: $unitName",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: firestore
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
              return ActivityList(snapshot: snapshot);
            },
          ),
        ],
      ),
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
        List<dynamic> images = activity['pictures'] ?? [];
        return Card(
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(activity['activityname'], style: TextStyle(color: Colors.red)),
                subtitle: Text(activity['activitydiscription']),
              ),
              if (images.isNotEmpty)
                CarouselSlider(
                  options: CarouselOptions(height: 200, autoPlay: true, enlargeCenterPage: true),
                  items: images.map((base64Image) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(base64Decode(base64Image), fit: BoxFit.cover),
                  )).toList(),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
