import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'CreatePostScreen.dart';
import 'FriendListScreen.dart';
import 'UserProfileScreen.dart';

class NewsFeedScreen extends StatefulWidget {
  @override
  _NewsFeedScreenState createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allPosts = [];
  bool isLoading = false;
  DocumentSnapshot? lastDocument;
  final int pageSize = 10;
  int _selectedIndex = 0;

  // User data
  String? name, bio, about;
  Uint8List? profilePicBytes, coverPicBytes;
  Map<String, String?> profilePicCache = {}; // Profile picture cache

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchPosts();
  }

  /// 🔹 Fetch logged-in user data
  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<String> collections = [
      'general_ids','central_ids', 'provincial_ids', 'district_ids', 'tehsil_ids', 'basicunit_ids'
    ];

    for (String collection in collections) {
      var snapshot = await _firestore
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

  /// 🔹 Fetch news feed posts
  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collectionGroup('postbyuser')
          .orderBy('timestamp', descending: true)
          .limit(pageSize);

      if (!isRefresh && lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      QuerySnapshot<Map<String, dynamic>> postsSnapshot = await query.get();
      if (postsSnapshot.docs.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      List<Map<String, dynamic>> newPosts = postsSnapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'postId': doc.id,
          'reference': doc.reference, // Store reference for likes and comments
        };
      }).toList();

      setState(() {
        if (isRefresh) {
          allPosts = newPosts;
        } else {
          allPosts.addAll(newPosts);
        }
        lastDocument = postsSnapshot.docs.last;
      });
    } catch (e) {
      print("❌ Error fetching posts: $e");
    }
    setState(() => isLoading = false);
  }

  /// 🔹 Fetch profile picture for a given UID (Optimized)
  Future<Uint8List?> fetchProfilePic(String? uid) async {
    if (uid == null) return null;
    if (profilePicCache.containsKey(uid)) {
      return profilePicCache[uid] != null ? base64Decode(profilePicCache[uid]!) : null;
    }

    List<String> collections = ['general_ids','central_ids', 'provincial_ids', 'district_ids', 'tehsil_ids', 'basicunit_ids'];

    for (String collection in collections) {
      var snapshot = await _firestore.collection(collection).where('uid', isEqualTo: uid).limit(1).get();

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

  /// 🔹 Fetch user name for a given UID
  Future<String?> fetchUserName(String? uid) async {
    if (uid == null) return null;

    List<String> collections = ['general_ids','central_ids', 'provincial_ids', 'district_ids', 'tehsil_ids', 'basicunit_ids'];

    for (String collection in collections) {
      var snapshot = await _firestore.collection(collection).where('uid', isEqualTo: uid).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        return data['name'] as String?;
      }
    }

    return null;
  }

  /// 🔹 Like a post and update Firestore
  Future<void> likePost(DocumentReference postRef, List<dynamic> likedBy) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (likedBy.contains(user.uid)) {
      return;
    } else {
      // User hasn't liked the post yet, so add their like
      await postRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  /// 🔹 Add a comment to a post
  Future<void> addComment(DocumentReference postRef, String comment) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await postRef.collection('comments').add({
      'userId': user.uid,
      'name': name ?? 'Unknown User',
      'text': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
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

  /// 🔹 Decode base64 image
  Image? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      Uint8List bytes = base64Decode(base64String);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      print("❌ Error decoding image: $e");
      return null;
    }
  }

  /// 🔹 Show a dialog with the list of users who liked the post
  void _showLikesDialog(List<dynamic> likedBy) async {
    List<Map<String, dynamic>> userDetails = [];

    // Fetch names and profile pictures of all users who liked the post
    for (var uid in likedBy) {
      String? userName = await fetchUserName(uid);
      Uint8List? profilePic = await fetchProfilePic(uid);
      if (userName != null) {
        userDetails.add({
          'name': userName,
          'profilePic': profilePic,
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Liked by", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: userDetails.map((user) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profilePic'] != null
                        ? MemoryImage(user['profilePic']!)
                        : AssetImage("assets/default_avatar.png") as ImageProvider,
                  ),
                  title: Text(user['name'], style: TextStyle(fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("News Feed", style: TextStyle(fontWeight: FontWeight.bold))),
      body: isLoading && allPosts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => fetchPosts(isRefresh: true),
        child: ListView.builder(
          itemCount: allPosts.length + 1,
          itemBuilder: (context, index) {
            if (index == allPosts.length) {
              return lastDocument != null
                  ? Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  : SizedBox();
            }
            var post = allPosts[index];
            Image? postImage = _decodeBase64Image(post['imageBase64'] as String?);
            List<dynamic> likedBy = post['likedBy'] ?? [];
            int likesCount = post['likedBy'].length as int? ?? 0;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FutureBuilder<Uint8List?>(
                          future: fetchProfilePic(post['userId'] as String?),
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
                            Text(
                              post['name'] as String? ?? 'Unknown User',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              _formatTimestamp(post['timestamp']),
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(post['text'] as String? ?? ''),
                    if (postImage != null) postImage,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 18.0, top: 18),
                          child: GestureDetector(
                            onTap: () {
                              if (likedBy.isNotEmpty) {
                                _showLikesDialog(likedBy);
                              }
                            },
                            child: FutureBuilder<String?>(
                              future: fetchUserName(likedBy.isNotEmpty ? likedBy.last : null),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Text("Loading...");
                                }
                                if (!snapshot.hasData || snapshot.data == null) {
                                  return Text("");
                                }
                                String recentLikerName = snapshot.data!;
                                if (likedBy.length == 1) {
                                  return Text("$recentLikerName");
                                } else {
                                  return Text("$recentLikerName and ${likedBy.length - 1} others");
                                }
                              },
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              icon: Icon(Icons.thumb_up_alt_outlined),
                              label: Text("Like ($likesCount)"),
                              onPressed: () => likePost(post['reference'], likedBy),
                            ),
                            StreamBuilder<QuerySnapshot>(
                              stream: post['reference'].collection('comments').snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return TextButton.icon(
                                    icon: Icon(Icons.comment_outlined),
                                    label: Text("Comment"),
                                    onPressed: () {
                                      _showCommentDialog(post['reference']);
                                    },
                                  );
                                }
                                int commentCount = snapshot.data!.docs.length;
                                return TextButton.icon(
                                  icon: Icon(Icons.comment_outlined),
                                  label: Text("Comment $commentCount"),
                                  onPressed: () {
                                    _showCommentDialog(post['reference']);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: post['reference'].collection('comments').orderBy('timestamp', descending: true).limit(1).snapshots(),
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment['text'] ?? ''),
                              Text(
                                _formatTimestamp(comment['timestamp']),
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        _showAllComments(post['reference']);
                      },
                      child: Text("View all comments"),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
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
    );
  }

  /// 🔹 Show a dialog to add a comment
  void _showCommentDialog(DocumentReference postRef) {
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Container(
            width: double.maxFinite, // Ensure the dialog has a maximum width
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6, // Set a maximum height
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ensure the column doesn't expand infinitely
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: postRef.collection('comments').orderBy('timestamp', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("No comments yet."));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var comment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment['text'] ?? ''),
                                Text(
                                  _formatTimestamp(comment['timestamp']),
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: "Write a comment...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (commentController.text.isNotEmpty) {
                          await addComment(postRef, commentController.text);
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
        );
      },
    );
  }

  /// 🔹 Show all comments for a post
  void _showAllComments(DocumentReference postRef) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Text("All Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment['text'] ?? ''),
                              Text(
                                _formatTimestamp(comment['timestamp']),
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 Format timestamp to a readable string
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }
}