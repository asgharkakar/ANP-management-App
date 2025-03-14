import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'FriendListScreen.dart';
import 'NewsFeedScreen.dart';
import 'UserProfileScreen.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  File? _image;
  int _selectedIndex = 1;
  String _userName = "Unknown User";
  Uint8List? _profilePicBytes;
  Map<String, String?> profilePicCache = {}; // Profile picture cache
  Stream<QuerySnapshot>? _postsStream;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _initializePostStream();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      var userData = await fetchUserData(user.uid);
      if (userData != null) {
        setState(() {
          _userName = userData['name'] ?? "Unknown User";
          if (userData['profilePic'] != null) {
            _profilePicBytes = base64Decode(userData['profilePic']!);
          }
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    List<String> collections = [
      'central_ids', 'provincial_ids', 'district_ids', 'tehsil_ids', 'basicunit_ids'
    ];

    try {
      for (String collection in collections) {
        var snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.first.data();
        }
      }
    } catch (e) {
      print("Error fetching user data from Firestore: $e");
    }
    return null;
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

  void _initializePostStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _postsStream = FirebaseFirestore.instance
            .collection('posts')
            .doc(user.uid)
            .collection("postbyuser")
            .orderBy('timestamp', descending: true)
            .snapshots();
      });
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadPost() async {
    String postText = _postController.text.trim();
    if (postText.isEmpty && _image == null) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? base64Image;
        if (_image != null) {
          List<int> imageBytes = await _image!.readAsBytes();
          base64Image = base64Encode(imageBytes);
        }

        await FirebaseFirestore.instance.collection('posts').doc(user.uid).collection("postbyuser").add({
          'name': _userName,
          'text': postText,
          'imageBase64': base64Image ?? '',
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'likes': 0,
          'likedBy': [],
        });

        _postController.clear();
        setState(() {
          _image = null;
        });
      }
    } catch (e) {
      print("Error uploading post: $e");
    }
  }

  /// 🔹 Fetch profile picture for a given UID
  Future<Uint8List?> fetchProfilePic(String? uid) async {
    if (uid == null) return null;
    if (profilePicCache.containsKey(uid)) {
      return profilePicCache[uid] != null ? base64Decode(profilePicCache[uid]!) : null;
    }

    List<String> collections = ['central_ids', 'provincial_ids', 'district_ids', 'tehsil_ids', 'basicunit_ids'];

    for (String collection in collections) {
      var snapshot = await FirebaseFirestore.instance.collection(collection).where('uid', isEqualTo: uid).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        String? profilePic = data['profilePic'] as String?;
        profilePicCache[uid] = profilePic;
        return profilePic != null ? base64Decode(profilePic) : null;
      }
    }

    profilePicCache[uid] = null;
    return null;
  }

  /// 🔹 Like a post and update Firestore
  Future<void> likePost(DocumentReference postRef, List<dynamic> likedBy) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (likedBy.contains(user.uid)) {
      // User has already liked the post
      return;
    }

    await postRef.update({
      'likes': FieldValue.increment(1),
      'likedBy': FieldValue.arrayUnion([user.uid]),
    });
  }

  /// 🔹 Add a comment to a post
  Future<void> addComment(DocumentReference postRef, String comment) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await postRef.collection('comments').add({
      'userId': user.uid,
      'name': _userName,
      'text': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: uploadPost,
            child: Text('Post', style: TextStyle(color: Colors.blue, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: _profilePicBytes != null
                          ? MemoryImage(_profilePicBytes!)
                          : AssetImage("assets/default_avatar.png") as ImageProvider,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userName, style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                            controller: _postController,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: "What's on your mind?",
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_image != null)
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Image.file(_image!, height: 200, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => setState(() => _image = null),
                        ),
                      ),
                    ],
                  ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.video_call, color: Colors.red),
                      label: Text("Live Video"),
                    ),
                    TextButton.icon(
                      onPressed: pickImage,
                      icon: Icon(Icons.photo_library, color: Colors.green),
                      label: Text("Photo"),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.location_on, color: Colors.blue),
                      label: Text("Check-in"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No posts found."));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    return buildPostItem(snapshot.data!.docs[index]);
                  },
                );
              },
            ),
          ),
        ],
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

  Widget buildPostItem(DocumentSnapshot post) {
    Map<String, dynamic>? postData = post.data() as Map<String, dynamic>?;

    if (postData == null) return SizedBox(); // If data is null, return an empty widget

    String userName = postData['name'] ?? "Unknown User";
    String text = postData['text'] ?? "";
    String? base64Image = postData['imageBase64'];
    Timestamp? timestamp = postData['timestamp'] as Timestamp?;
    int likes = postData['likes'] ?? 0;
    List<dynamic> likedBy = postData['likedBy'] ?? [];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FutureBuilder<Uint8List?>(
                  future: fetchProfilePic(postData['userId'] as String?),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircleAvatar(radius: 20, child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return CircleAvatar(radius: 20, backgroundImage: AssetImage("assets/default_avatar.png"));
                    }

                    return CircleAvatar(radius: 20, backgroundImage: MemoryImage(snapshot.data!));
                  },
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      timestamp != null
                          ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
                          : "Unknown time",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(text, style: TextStyle(fontSize: 16)),
            if (base64Image != null && base64Image.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.memory(base64Decode(base64Image)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.thumb_up_alt_outlined),
                  label: Text("Like ($likes)"),
                  onPressed: () => likePost(post.reference, likedBy),
                ),
                TextButton.icon(
                  icon: Icon(Icons.comment_outlined),
                  label: Text("Comment"),
                  onPressed: () {
                    _showCommentDialog(post.reference);
                  },
                ),
              ],
            ),
            StreamBuilder<QuerySnapshot>(
              stream: post.reference.collection('comments').orderBy('timestamp', descending: true).limit(1).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SizedBox();
                }
                var comment = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                return ListTile(
                  leading: FutureBuilder<Uint8List?>(
                    future: fetchProfilePic(comment['userId'] as String?),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircleAvatar(radius: 20, child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return CircleAvatar(radius: 20, backgroundImage: AssetImage("assets/default_avatar.png"));
                      }

                      return CircleAvatar(radius: 20, backgroundImage: MemoryImage(snapshot.data!));
                    },
                  ),
                  title: Text(comment['name'] ?? 'Unknown User'),
                  subtitle: Text(comment['text'] ?? ''),
                );
              },
            ),
            TextButton(
              onPressed: () {
                _showAllComments(post.reference);
              },
              child: Text("View all comments"),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Show a dialog to add a comment
  void _showCommentDialog(DocumentReference postRef) {
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add a Comment"),
          content: TextField(
            controller: commentController,
            decoration: InputDecoration(hintText: "Write a comment..."),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (commentController.text.isNotEmpty) {
                  await addComment(postRef, commentController.text);
                  Navigator.pop(context);
                }
              },
              child: Text("Post"),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Show all comments for a post
  void _showAllComments(DocumentReference postRef) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: postRef.collection('comments').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No comments yet."));
            }
            return ListView(
              children: snapshot.data!.docs.map((doc) {
                var comment = doc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: FutureBuilder<Uint8List?>(
                    future: fetchProfilePic(comment['userId'] as String?),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircleAvatar(radius: 20, child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return CircleAvatar(radius: 20, backgroundImage: AssetImage("assets/default_avatar.png"));
                      }

                      return CircleAvatar(radius: 20, backgroundImage: MemoryImage(snapshot.data!));
                    },
                  ),
                  title: Text(comment['name'] ?? 'Unknown User'),
                  subtitle: Text(comment['text'] ?? ''),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}