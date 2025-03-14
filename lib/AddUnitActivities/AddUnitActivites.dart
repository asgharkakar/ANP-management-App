import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class AddUnitActivites extends StatefulWidget {
  const AddUnitActivites({super.key});

  @override
  State<AddUnitActivites> createState() => _AddUnitActivitesState();
}

class _AddUnitActivitesState extends State<AddUnitActivites> {
  final TextEditingController activityNameController = TextEditingController();
  final TextEditingController activityDescriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> imageBase64List = [];

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.length > 3) {
      pickedFiles = pickedFiles.sublist(0, 3); // Allow max 3 images
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
    String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in"))
      );
      return;
    }

    String unitName = "";
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('basicunit_ids')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        unitName = querySnapshot.docs.first['basicunit'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unit not found"))
        );
        return;
      }
    } catch (e) {
      print("Error fetching unit name: $e");
      return;
    }

    await _firestore.collection("UnitCollection").doc(unitName).collection("Activities").add({
      "activityname": activityNameController.text,
      "activitydiscription": activityDescriptionController.text,
      "pictures": imageBase64List,
      "uid": uid,
      "timestamp": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activity Saved Successfully"))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Unit Activity"),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: activityNameController,
              decoration: InputDecoration(
                labelText: "Activity Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: activityDescriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Activity Description",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            const Text("Upload Activity Pictures (Max: 3)"),
            const SizedBox(height: 5),
            Row(
              children: [
                ElevatedButton(
                  onPressed: pickImages,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text("Pick Images", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              children: imageBase64List.map((base64) {
                return Container(
                  margin: const EdgeInsets.all(5),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(base64)),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: saveActivity,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text("Save Activity", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
