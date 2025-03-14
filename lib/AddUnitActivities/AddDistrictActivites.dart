import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class AddDistrictActivities extends StatefulWidget {
  const AddDistrictActivities({super.key});

  @override
  State<AddDistrictActivities> createState() => _AddDistrictActivitiesState();
}

class _AddDistrictActivitiesState extends State<AddDistrictActivities> {
  final TextEditingController activityNameController = TextEditingController();
  final TextEditingController activityDescriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> imageBase64List = [];
  String? districtName;

  @override
  void initState() {
    super.initState();
    fetchDistrictName();
  }

  Future<void> fetchDistrictName() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return;

      QuerySnapshot querySnapshot = await _firestore
          .collection('district_ids')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          districtName = querySnapshot.docs.first['district'];
        });
      }
    } catch (e) {
      print("Error fetching district name: $e");
    }
  }

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.length > 3) {
      pickedFiles = pickedFiles.sublist(0, 3);
    }

    List<String> base64Images = [];
    for (var file in pickedFiles) {
      File imageFile = File(file.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      base64Images.add(base64Encode(imageBytes));
    }

    setState(() {
      imageBase64List = base64Images;
    });
  }

  Future<void> saveActivity() async {
    if (districtName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("District not found")));
      return;
    }

    await _firestore.collection("DistrictCollection")
        .doc(districtName)
        .collection("Activities")
        .add({
      "activityname": activityNameController.text,
      "activitydiscription": activityDescriptionController.text,
      "pictures": imageBase64List,
      "uid": _auth.currentUser?.uid,
      "timestamp": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activity Saved Successfully")));

    activityNameController.clear();
    activityDescriptionController.clear();
    setState(() {
      imageBase64List.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Add District Activities", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
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
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.red),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome Back!",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("District: ${districtName ?? "Loading..."}",
                          style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _inputField("Activity Name", activityNameController),
                  _inputField("Activity Description", activityDescriptionController),
                  _imageUploadSection(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: saveActivity,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Save Activity", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _imageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Upload Images"),
        ElevatedButton(
          onPressed: pickImages,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: const Text("Pick Images", style: TextStyle(color: Colors.white)),
        ),
        Wrap(
          children: imageBase64List.map((base64) {
            return Container(
              margin: const EdgeInsets.all(5),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey),
                image: DecorationImage(
                  image: MemoryImage(base64Decode(base64)),
                  fit: BoxFit.cover,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
