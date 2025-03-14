import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class ViewCentralAllActivities extends StatefulWidget {
  const ViewCentralAllActivities({super.key});

  @override
  State<ViewCentralAllActivities> createState() => _ViewCentralAllActivitiesState();
}

class _ViewCentralAllActivitiesState extends State<ViewCentralAllActivities> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = "";

  // Combine multiple Firestore streams using rxdart
  Stream<List<QuerySnapshot>> get combinedStream {
    return Rx.combineLatest3(
      _firestore.collection('provincial_ids').snapshots(),
      _firestore.collection('district_ids').snapshots(),
      _firestore.collection('tehsil_ids').snapshots(),
          (provinceSnapshot, districtSnapshot, tehsilSnapshot) =>
      [provinceSnapshot, districtSnapshot, tehsilSnapshot],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Central - All Activities"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search by Province, District, or Tehsil",
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<QuerySnapshot>>(
              stream: combinedStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Extract data from the combined stream
                var provinceSnapshot = snapshot.data![0];
                var districtSnapshot = snapshot.data![1];
                var tehsilSnapshot = snapshot.data![2];

                // Filter provinces based on search query
                var provinces = provinceSnapshot.docs.where((doc) {
                  String provinceName = (doc['province'] ?? "").toString().toLowerCase();
                  return searchQuery.isEmpty || provinceName.contains(searchQuery);
                }).toList();

                // Filter districts based on search query
                var districts = districtSnapshot.docs.where((doc) {
                  String districtName = (doc['district'] ?? "").toString().toLowerCase();
                  return searchQuery.isEmpty || districtName.contains(searchQuery);
                }).toList();

                // Filter tehsils based on search query
                var tehsils = tehsilSnapshot.docs.where((doc) {
                  String tehsilName = (doc['tehsil'] ?? "").toString().toLowerCase();
                  return searchQuery.isEmpty || tehsilName.contains(searchQuery);
                }).toList();

                return ListView(
                  children: [
                    // Display provinces
                    ...provinces.map((doc) {
                      String provinceName = doc['province'] ?? "";
                      return ExpansionTile(
                        title: Text(
                          "🌍 Province: $provinceName",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        children: [
                          ViewProvinceAllActivities(provinceName: provinceName),
                          ViewDistrictAllActivities(provinceName: provinceName),
                        ],
                      );
                    }).toList(),

                    // Display districts
                    ...districts.map((doc) {
                      String districtName = doc['district'] ?? "";
                      return ExpansionTile(
                        title: Text(
                          "📍 District: $districtName",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        children: [
                          ViewDistrictActivities(districtName: districtName),
                          ViewTehsilAllActivities(districtName: districtName),
                        ],
                      );
                    }).toList(),

                    // Display tehsils
                    ...tehsils.map((doc) {
                      String tehsilName = doc['tehsil'] ?? "";
                      return ExpansionTile(
                        title: Text(
                          "🏘️ Tehsil: $tehsilName",
                          style: const TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                        children: [
                          ViewTehsilActivities(tehsilName: tehsilName),
                          ViewUnitAllActivities(tehsilName: tehsilName),
                        ],
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ViewProvinceAllActivities extends StatelessWidget {
  final String provinceName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ViewProvinceAllActivities({super.key, required this.provinceName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection("ProvinceCollection").doc(provinceName).collection("Activities").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No activities found for this province."),
          );
        }
        return ActivityList(snapshot: snapshot);
      },
    );
  }
}

class ViewDistrictAllActivities extends StatelessWidget {
  final String provinceName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ViewDistrictAllActivities({super.key, required this.provinceName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('district_ids').where('province', isEqualTo: provinceName).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var districts = snapshot.data!.docs;
        return Column(
          children: districts.map((doc) {
            String districtName = doc['district'];
            return ExpansionTile(
              title: Text("📍 District: $districtName",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              children: [
                ViewDistrictActivities(districtName: districtName),
                ViewTehsilAllActivities(districtName: districtName),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class ViewDistrictActivities extends StatelessWidget {
  final String districtName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ViewDistrictActivities({super.key, required this.districtName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection("DistrictCollection").doc(districtName).collection("Activities").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No activities found for this district."),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var tehsils = snapshot.data!.docs;
        return Column(
          children: tehsils.map((doc) {
            String tehsilName = doc['tehsil'];
            return ExpansionTile(
              title: Text("🏘️ Tehsil: $tehsilName",
                  style: const TextStyle(fontSize: 16, color: Colors.blue)),
              children: [
                ViewTehsilActivities(tehsilName: tehsilName),
                ViewUnitAllActivities(tehsilName: tehsilName),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class ViewTehsilActivities extends StatelessWidget {
  final String tehsilName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ViewTehsilActivities({super.key, required this.tehsilName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection("TehsilCollection").doc(tehsilName).collection("Activities").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No activities found for this tehsil."),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var units = snapshot.data!.docs;
        return Column(
          children: units.map((doc) {
            String unitName = doc['basicunit'];
            return ExpansionTile(
              title: Text("🏢 Unit: $unitName",
                  style: const TextStyle(fontSize: 16, color: Colors.green)),
              children: [
                ViewUnitActivities(unitName: unitName),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class ViewUnitActivities extends StatelessWidget {
  final String unitName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ViewUnitActivities({super.key, required this.unitName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection("UnitCollection").doc(unitName).collection("Activities").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("No activities found for this unit."),
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
        var activityData = activity.data() as Map<String, dynamic>? ?? {};

        String activityName = activityData['activityname'] ?? 'Unknown Activity';
        String activityDescription = activityData['activitydiscription'] ?? 'No description available';
        List<dynamic>? pictures = activityData['pictures'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activityName, style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(activityDescription),
                if (pictures != null && pictures.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CarouselSlider(
                      options: CarouselOptions(height: 200, enlargeCenterPage: true, autoPlay: true, aspectRatio: 16 / 9, viewportFraction: 0.8),
                      items: pictures.map((imageBase64) {
                        try {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(base64Decode(imageBase64), fit: BoxFit.cover, width: double.infinity),
                          );
                        } catch (e) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(imageBase64, fit: BoxFit.cover, width: double.infinity, errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Text("Image not available"));
                            }),
                          );
                        }
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}