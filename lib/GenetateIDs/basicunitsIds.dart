import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GenerateBasicUnitIDScreen extends StatefulWidget {
  const GenerateBasicUnitIDScreen({super.key});

  @override
  State<GenerateBasicUnitIDScreen> createState() => _GenerateBasicUnitIDScreenState();
}

class _GenerateBasicUnitIDScreenState extends State<GenerateBasicUnitIDScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController basicunitController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String tehsilName = "";

  @override
  void initState() {
    super.initState();
    fetchTehsilName();
  }

  Future<void> fetchTehsilName() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

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
      }
    } catch (e) {
      print("Error fetching tehsil name: $e");
    }
  }

  Future<void> generateBasicUnitID() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection("basicunit_ids").add({
          "name": nameController.text.trim(),
          "basicunit": basicunitController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "tehsil": tehsilName,
          "uid": user.uid,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Basic Unit ID Generated Successfully!")),
        );

        nameController.clear();
        basicunitController.clear();
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
        title: const Text("Generate Basic Unit ID", style: TextStyle(color: Colors.white)),
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
                controller: basicunitController,
                decoration: InputDecoration(
                  labelText: "Basic Unit",
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
              tehsilName.isNotEmpty
                  ? Text("Tehsil: $tehsilName", style: const TextStyle(fontWeight: FontWeight.bold))
                  : const CircularProgressIndicator(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: tehsilName.isNotEmpty ? generateBasicUnitID : null,
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
