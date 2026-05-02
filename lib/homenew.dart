
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbook_android/view_complaint.dart';
import 'package:zenbook_android/view_friends.dart';
import 'package:zenbook_android/view_post.dart';
import 'package:zenbook_android/view_users.dart';
import 'package:zenbook_android/viewprofile.dart';
import 'Group_chat.dart';
import 'group_list.dart';
import 'addpost.dart';
import 'login.dart';

void main() {
  runApp(const HomeNew());
}

class HomeNew extends StatelessWidget {
  const HomeNew({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Home',
      theme: ThemeData(
        colorScheme:
        ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 9, 231, 112)),
        useMaterial3: true,
      ),
      home: const HomeNewPage(title: 'Home'),
    );
  }
}

class HomeNewPage extends StatefulWidget {
  const HomeNewPage({super.key, required this.title});

  final String title;

  @override
  State<HomeNewPage> createState() => _HomeNewPageState();
}

class _HomeNewPageState extends State<HomeNewPage> {
  // Post lists
  List<String> photos_ = [];
  List<String> ids_ = [];
  List<String> content_ = [];
  List<String> post_date_ = [];
  List<String> names_ = [];
  List<bool> liked_ = []; // track like status
  List<int> likeCount_ = []; // track like counts

  // profile
  String? networkImageUrl;
  String uname_ = "";

  // comment lists used by bottom sheet
  List<String> commentList = [];
  List<String> commentUserList = [];
  List<bool> commentToxicList = []; // Track if comment is toxic
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    viewprofile();
    view_post();
  }

  Future<void> refreshPosts() async {
    await view_post();
  }
  // Fetch profile info
  void viewprofile() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String lid = sh.getString('lid') ?? '';
    String url = sh.getString('url') ?? '';

    final apiUrl = Uri.parse('$url/viewprofile/');

    try {
      final response = await http.post(apiUrl, body: {
        'lid': lid,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          String? photoValue = data['profile_pic'];
          setState(() {
            uname_ = data['name'] ?? '';
            networkImageUrl = (photoValue != null && photoValue != 'null')
                ? '$url/$photoValue'
                : null;
          });
        } else {
          Fluttertoast.showToast(msg: 'Profile not found');
        }
      } else {
        Fluttertoast.showToast(msg: 'Server error');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  // Fetch posts with like info
  Future<void> view_post() async {
    List<String> photos = [];
    List<String> ids = [];
    List<String> content = [];
    List<String> date = [];
    List<String> names = [];
    List<bool> likedStatus = [];
    List<int> likeCounts = [];

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url')!;
      String lid = sh.getString('lid')!;
      String img_url = sh.getString('img_url')!;
      String url = '$urls/view_all_post/';

      var response = await http.post(Uri.parse(url), body: {'lid': lid});
      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        var arr = jsondata["data"];
        for (var post in arr) {
          ids.add(post['id'].toString());
          date.add(post['post_date'].toString());
          content.add(post['content'].toString());
          photos.add(img_url + post['photo'].toString());
          names.add(post['names'].toString());
          likedStatus.add(post['is_liked'] == true);
          likeCounts.add(post['like_count'] ?? 0);
        }

        setState(() {
          ids_ = ids;
          post_date_ = date;
          content_ = content;
          photos_ = photos;
          names_ = names;
          liked_ = likedStatus;
          likeCount_ = likeCounts;
        });

        // Optionally refresh likes again from server if needed
        await fetchLikes();
      } else {
        Fluttertoast.showToast(msg: 'No posts found');
      }
    } catch (e) {
      print("Error: ${e.toString()}");
      Fluttertoast.showToast(msg: "Error fetching posts");
    }
  }

  // Refresh likes from server
  Future<void> fetchLikes() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url')!;
      String lid = sh.getString('lid')!;
      String url = '$urls/view_like/';

      var response = await http.post(
        Uri.parse(url),
        body: {
          'user_id': lid,
        },
      );

      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        List<dynamic> data = jsondata['data'];

        List<bool> newLiked = List.filled(ids_.length, false);
        List<int> newLikeCount = List.filled(ids_.length, 0);

        for (var likeInfo in data) {
          String postIdStr = likeInfo['post_id'].toString();
          int idx = ids_.indexOf(postIdStr);
          if (idx != -1) {
            newLiked[idx] = likeInfo['is_liked'] == true;
            newLikeCount[idx] = likeInfo['like_count'] ?? 0;
          }
        }

        setState(() {
          liked_ = newLiked;
          likeCount_ = newLikeCount;
        });
      } else {
        Fluttertoast.showToast(msg: jsondata['message'] ?? 'Failed to load likes');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching likes');
    }
  }

  // Like/unlike post
  Future<void> toggleLike(int index) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url')!;
      String lid = sh.getString('lid')!;
      String url = '$urls/toggle_like/';

      var response = await http.post(
        Uri.parse(url),
        body: {
          'post_id': ids_[index],
          'user_id': lid,
        },
      );

      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        setState(() {
          liked_[index] = jsondata['liked'] ?? !liked_[index];
          likeCount_[index] = jsondata['like_count'] ?? likeCount_[index];
        });
        Fluttertoast.showToast(msg: "Likes: ${likeCount_[index]}");
      } else {
        Fluttertoast.showToast(msg: jsondata['message'] ?? "Error");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error liking post");
    }
  }

  // Comments: fetch
  Future<void> fetchComments(String postId) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url')!;
      String lid = sh.getString('lid')!;
      String url = '$urls/view_comments/';

      var response = await http.post(Uri.parse(url), body: {
        'lid': lid,
        'pid': postId,
      });

      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        var arr = jsondata["data"];
        List<String> comments = [];
        List<String> users = [];
        List<bool> toxicFlags = [];

        for (var comment in arr) {
          users.add(comment['user'].toString());
          comments.add(comment['comment_text'].toString());
          toxicFlags.add(comment['toxic'] == true);
        }

        setState(() {
          commentList = comments;
          commentUserList = users;
          commentToxicList = toxicFlags;
        });
      } else {
        setState(() {
          commentList = [];
          commentUserList = [];
          commentToxicList = [];
        });
      }
    } catch (e) {
      print("fetchComments Error: ${e.toString()}");
      Fluttertoast.showToast(msg: "Error loading comments");
    }
  }

  // Post comment with toxicity check
  Future<void> postComment(String postId, String commentText) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String url = sh.getString('url').toString();
      String lid = sh.getString('lid').toString();
      final urls = Uri.parse('$url/comment_post/');

      final response = await http.post(urls, body: {
        "comment_text": commentText,
        "post_id": postId,
        "user_id": lid,
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String status = responseData['status'];

        if (status == 'ok') {
          bool isToxic = responseData['toxic'] == true;
          List<dynamic> toxicWords = responseData['toxic_words'] ?? [];
          int warningCount = responseData['warning_count'] ?? 0;

          if (isToxic) {
            // Show warning toast with current warning count
            Fluttertoast.showToast(
              msg: "⚠️ Warning: Your comment contains inappropriate content. "
                  "You have $warningCount/3 warnings.",
              backgroundColor: Colors.orange,
              textColor: Colors.white,
              toastLength: Toast.LENGTH_LONG,
            );
          } else {
            Fluttertoast.showToast(
              msg: 'Comment posted successfully',
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          }

          commentController.clear();
          await fetchComments(postId);
        }
        else if (status == 'blocked') {
          // User is blocked due to 3 warnings
          // Fluttertoast.showToast(
          //   msg: "🚫 Your account has been blocked for repeated violations.",
          //   backgroundColor: Colors.red,
          //   textColor: Colors.white,
          //   toastLength: Toast.LENGTH_LONG,
          // );
          // Navigator.push(context, MaterialPageRoute(builder: (context)=>MyLoginPage(title: '',)));

          Fluttertoast.showToast(
            msg: "🚫 Your account has been blocked for repeated violations.",
            backgroundColor: Colors.red,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_LONG,
          );

         // Clear any saved login/session data
          SharedPreferences.getInstance().then((prefs) {
            prefs.clear();

            // Navigate to login page and remove all previous routes
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MyLoginPage(title: '')),
                  (Route<dynamic> route) => false,
            );
          });


        } else {
          Fluttertoast.showToast(
            msg: 'Failed to post comment',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Network Error',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Show comments bottom sheet
  void openCommentsSheet(String postId) async {
    commentController.clear();
    await fetchComments(postId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          void refreshModal() {
            setModalState(() {});
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Comments",
                        style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: commentList.isEmpty
                        ? const Center(child: Text("No comments yet"))
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: commentList.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 0.8,
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: commentToxicList[index]
                              ? Colors.red[50] // Red background for toxic comments
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  commentUserList[index],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: commentToxicList[index]
                                          ? Colors.red // Red text for toxic comments
                                          : Colors.black),
                                ),
                                if (commentToxicList[index])
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4.0, bottom: 6.0),
                                    child: Text(
                                      "⚠️ Inappropriate content detected",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  commentList[index],
                                  style: TextStyle(
                                    color: commentToxicList[index]
                                        ? Colors.red // Red text for toxic comments
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SafeArea(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: "Add a comment...",
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF6C5CE7), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              String text = commentController.text.trim();
                              if (text.isEmpty) return;
                              await postComment(postId, text);
                              refreshModal();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                            ),
                            child:
                            const Text("Send", style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }


  void showNotifications() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url')!;
      String lid = sh.getString('lid')!;
      String url = '$urls/view_notifications/';

      var response = await http.post(Uri.parse(url), body: {'lid': lid});
      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        List<dynamic> data = jsondata['data'];

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF121212), // Dark background
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Notifications",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White text
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.grey),
                    Expanded(
                      child: data.isEmpty
                          ? const Center(
                        child: Text(
                          "No notifications yet",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                          : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: data.length,
                        separatorBuilder: (context, index) =>
                        const Divider(indent: 16, endIndent: 16, color: Colors.grey, height: 1),
                        itemBuilder: (context, index) {
                          var n = data[index];
                          String text = n['text'].toString();
                          String date = n['date'].toString();

                          return ListTile(
                            tileColor: const Color(0xFF1E1E1E), // Dark card background
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.redAccent,
                              child: const Icon(Icons.notifications, color: Colors.white),
                            ),
                            title: Text(
                              text,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white),
                            ),
                            subtitle: Text(
                              date,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                            ),
                            onTap: () {
                              // Optional: Handle click on individual notification
                              Fluttertoast.showToast(msg: text);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        Fluttertoast.showToast(msg: 'No notifications found');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }
  }



  // UI: posts list with like/unlike
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 18, 82, 98),
          title: const Text('Home'),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_active, // ringing bell icon
                color: Colors.red,          // red color
              ),
              onPressed: () {
                showNotifications(); // call your function
              },
            ),
          ],
        ),

        body: ListView.builder(
          itemCount: ids_.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    child: Image.network(
                      photos_[index],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.image_not_supported)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(content_[index],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(names_[index],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(post_date_[index],
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            toggleLike(index);
                          },
                          icon: Icon(
                            liked_[index] ? Icons.favorite : Icons.favorite_border,
                          ),
                          color: Colors.redAccent,
                        ),
                        Text('${likeCount_[index]} likes'),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            openCommentsSheet(ids_[index]);
                          },
                          icon: const Icon(Icons.comment, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),

        // Dark Mode Drawer
        drawer: Drawer(
          backgroundColor: const Color(0xFF1F1F1F), // dark background
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.white, // profile area white
                ),
                child: Column(
                  children: [
                    const Text('ZenBook',
                        style: TextStyle(fontSize: 20, color: Colors.black)),
                    const SizedBox(height: 8),
                    CircleAvatar(
                      radius: 29,
                      backgroundImage: networkImageUrl != null
                          ? NetworkImage(networkImageUrl!)
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    const SizedBox(height: 8),
                    Text(uname_, style: const TextStyle(color: Colors.black)),
                  ],
                ),
              ),
              drawerTile(Icons.home, 'Home', () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const HomeNewPage(title: '')));
              }),
              drawerTile(Icons.person_pin, 'View Profile', () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const ViewProfilePage(title: '')));
              }),
              drawerTile(Icons.image_outlined, 'Add Post', () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const Addpostpage(title: "Add post")));
              }),
              drawerTile(Icons.book_outlined, 'View Post', () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const ViewPostPage(title: "view post")));
              }),
              drawerTile(Icons.report, 'Complaints', () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const ComplaintPage(title: 'Complaints')));
              }),
              drawerTile(Icons.verified_user, 'Users', () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const FriendsAndUsersPage()));
              }),
              drawerTile(Icons.verified_user, 'Friends', () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const FriendsPage()));
              }),
              // drawerTile(Icons.logout, 'Logout', () {
              //   Navigator.push(
              //       context, MaterialPageRoute(builder: (context) => const MyLoginPage(title: '')));
              // }),

              drawerTile(Icons.logout, 'Logout', () async {
                // Clear saved login info if using SharedPreferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // removes all saved keys like 'lid', 'url', etc.

                // Navigate to login page and remove all previous routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MyLoginPage(title: '')),
                      (Route<dynamic> route) => false, // remove all previous routes
                );
              }),

            ],
          ),
        ),

        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chat',
            ),
          ],
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GroupListPage(),
                ),
              );
            }
          },
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
        ),
      ),
    );
  }

// Helper method for drawer tiles
  Widget drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

}