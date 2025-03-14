import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GenerateTehsilIDScreen extends StatefulWidget {
  const GenerateTehsilIDScreen({super.key});

  @override
  State<GenerateTehsilIDScreen> createState() => _GenerateTehsilIDScreenState();
}

class _GenerateTehsilIDScreenState extends State<GenerateTehsilIDScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tehsilController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String districtName = "";

  @override
  void initState() {
    super.initState();
    fetchDistrictName();
  }

  Future<void> fetchDistrictName() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
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

  Future<void> generateTehsilID() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection("tehsil_ids").add({
          "name": nameController.text.trim(),
          "tehsil": tehsilController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "district": districtName,
          "uid": user.uid,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tehsil ID Generated Successfully!")),
        );

        nameController.clear();
        tehsilController.clear();
        emailController.clear();
        passwordController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Generate Tehsil ID", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
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
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Colors.red),
                    ),
                    const SizedBox(width: 20),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Generate a New ID", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Fill in the details below", style: TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tehsilController,
                decoration: InputDecoration(
                  labelText: "Tehsil",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              districtName.isNotEmpty
                  ? Text("District: $districtName", style: const TextStyle(fontWeight: FontWeight.bold))
                  : const CircularProgressIndicator(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: districtName.isNotEmpty ? generateTehsilID : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Generate ID", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
