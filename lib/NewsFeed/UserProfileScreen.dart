import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../AuthScreens/LoginScreen.dart';
import 'CreatePostScreen.dart';
import 'FriendListScreen.dart';
import 'NewsFeedScreen.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? name, bio, about;
  Uint8List? profilePicBytes, coverPicBytes;

  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }
  Future<void> updateUserCommentsName(String newName) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch all posts
      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('postbyuser')
          .where('userId', isEqualTo: user.uid)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Log the number of posts found
      print("Found ${postsSnapshot.docs.length} posts by user ${user.uid}");

      // Loop through all posts
      for (QueryDocumentSnapshot postDoc in postsSnapshot.docs) {
        // Fetch all comments for the post
        QuerySnapshot commentsSnapshot = await postDoc.reference
            .collection('comments')
            .where('userId', isEqualTo: user.uid)
            .get();

        // Log the number of comments found
        print("Found ${commentsSnapshot.docs.length} comments in post ${postDoc.id}");

        // Update the name in each comment
        for (QueryDocumentSnapshot commentDoc in commentsSnapshot.docs) {
          print("Updating comment ${commentDoc.id} with new name: $newName");
          batch.update(commentDoc.reference, {'name': newName});
        }
      }

      // Commit the batch
      await batch.commit();
      print("Batch commit successful");
    } catch (e) {
      print("Error updating user name in comments: $e");
    }
  }
  Future<void> pickAndUploadImage(String field) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    Uint8List imageBytes = await pickedFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    await updateUserData(field, base64Image);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = NewsFeedScreen();
        break;
      case 1:
        nextScreen = CreatePostScreen();
        break;
      case 2:
        nextScreen = FriendsListScreen();
        break;
      case 3:
        nextScreen = UserProfileScreen();
        break;
      default:
        nextScreen = NewsFeedScreen();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<String> collections = [
      'central_ids', 'provincial_ids', 'district_ids', 'tehsil_ids', 'basicunit_ids'
    ];

    for (String collection in collections) {
      var snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        setState(() {
          name = data['name'] as String?;
          bio = data['bio'] as String?;
          about = data['about'] as String?;

          if (data['profilePic'] != null) {
            profilePicBytes = base64Decode(data['profilePic'] as String);
          }
          if (data['coverPic'] != null) {
            coverPicBytes = base64Decode(data['coverPic'] as String);
          }
        });
        return;
      }
    }
  }

  Future<void> updateUserData(String field, String value) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<String> collections = [
      'central_ids', 'provincial_ids', 'district_ids', 'tehsil_ids', 'basicunit_ids', 'general_ids'
    ];

    for (String collection in collections) {
      var snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(snapshot.docs.first.id)
            .update({field: value});

        if (field == "name") {
          await updateUserPostsName(value); // Update name in posts
          await updateUserCommentsName(value); // Update name in comments
        }

        fetchUserData();
        return;
      }
    }
  }

  Future<void> updateUserPostsName(String newName) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(user.uid)
          .collection('postbyuser')
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (QueryDocumentSnapshot postDoc in postsSnapshot.docs) {
        batch.update(postDoc.reference, {'name': newName});
      }
      await batch.commit();
    } catch (e) {
      print("Error updating user name in posts: $e");
    }
  }

  void showEditDialog(String field, String initialValue) {
    TextEditingController controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $field"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new $field"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              updateUserData(field, controller.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // Logout Function
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved preferences
    await FirebaseAuth.instance.signOut(); // Sign out from Firebase

    // Navigate to LoginScreen
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout, // Call the logout function
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GestureDetector(
                  onTap: () => pickAndUploadImage("coverPic"),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))]),
                    child: coverPicBytes != null
                        ? Image.memory(coverPicBytes!, fit: BoxFit.cover, width: double.infinity, height: 220)
                        : Container(color: Colors.grey[300]),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => pickAndUploadImage("profilePic"),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: profilePicBytes != null ? MemoryImage(profilePicBytes!) : null,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name ?? "Loading...", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.redAccent),
                  onPressed: () => showEditDialog("name", name ?? ""),
                ),
              ],
            ),
            buildInfoCard("Bio", bio, "bio"),
            buildInfoCard("About", about, "about"),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget buildInfoCard(String title, String? value, String field) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        subtitle: Text(value ?? "No $title available", style: TextStyle(fontSize: 16, color: Colors.black54)),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Colors.redAccent),
          onPressed: () => showEditDialog(field, value ?? ""),
        ),
      ),
    );
  }
}