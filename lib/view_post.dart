import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'homenew.dart';
import 'login.dart'; // Make sure to import your login page

void main() {
  runApp(const ViewPost());
}

class ViewPost extends StatelessWidget {
  const ViewPost({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'View Post',
      theme: ThemeData(
        colorScheme:
        ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 18, 82, 98)),
        useMaterial3: true,
      ),
      home: const ViewPostPage(title: 'My Posts'),
    );
  }
}

class ViewPostPage extends StatefulWidget {
  const ViewPostPage({super.key, required this.title});
  final String title;

  @override
  State<ViewPostPage> createState() => _ViewPostPageState();
}

class _ViewPostPageState extends State<ViewPostPage> {
  List<String> photo_ = [];
  List<String> id_ = [];
  List<String> content_ = [];
  List<String> post_date_ = [];
  List<bool> liked_ = []; // track like status for each post
  List<int> likeCount_ = []; // track like count for each post

  _ViewPostPageState() {
    view_post();
  }

  Future<void> view_post() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url')!;
      String lid = sh.getString('lid')!;
      String img_url = sh.getString('img_url')!;
      String url = '$urls/view_post/';

      var response = await http.post(Uri.parse(url), body: {'lid': lid});
      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        List<String> id = [];
        List<String> date = [];
        List<String> content = [];
        List<String> photo = [];
        List<bool> likedStatus = [];
        List<int> likeCounts = [];

        var arr = jsondata["data"];
        for (var post in arr) {
          id.add(post['id'].toString());
          date.add(post['post_date'].toString());
          content.add(post['content'].toString());
          photo.add(img_url + post['photo'].toString());
          likedStatus.add(post['is_liked'] == true);
          likeCounts.add(post['like_count'] ?? 0);
        }

        setState(() {
          id_ = id;
          post_date_ = date;
          content_ = content;
          photo_ = photo;
          liked_ = likedStatus;
          likeCount_ = likeCounts;
        });

        // Refresh likes to be extra sure they're accurate
        await fetchLikes();
      } else {
        Fluttertoast.showToast(msg: 'No posts found');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

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

        List<bool> newLiked = List.filled(id_.length, false);
        List<int> newLikeCount = List.filled(id_.length, 0);

        for (var likeInfo in data) {
          String postIdStr = likeInfo['post_id'].toString();
          int idx = id_.indexOf(postIdStr);
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

  Future<void> toggleLike(int index) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url')!;
      String lid = sh.getString('lid')!;
      String url = '$urls/toggle_like/';

      var response = await http.post(
        Uri.parse(url),
        body: {
          'post_id': id_[index],
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

  void deletepost(String postId) async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();
    final Url = Uri.parse('$url/deletepost/');

    try {
      final response = await http.post(Url, body: {
        'id': postId,
      });
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'ok') {
          Fluttertoast.showToast(msg: "Deleted Successfully!");
          view_post();
        } else {
          Fluttertoast.showToast(msg: 'Post not found');
        }
      } else {
        Fluttertoast.showToast(msg: "Network Error");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<List<Map<String, String>>> fetchComments(String postId) async {
    List<Map<String, String>> comments = [];
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url')!;
      String url = '$urls/view_comments/';
      String img_url = sh.getString('img_url')!;

      var response = await http.post(Uri.parse(url), body: {'pid': postId});
      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        var arr = jsondata["data"];
        for (var c in arr) {
          comments.add({
            'username': c['user'].toString(),
            'comment': c['comment_text'].toString(),
            'photo': img_url + c['photo'].toString(),
            'toxic': (c['toxic'] == true).toString(), // Add toxic flag
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading comments");
    }
    return comments;
  }

  Future<void> postComment(String postId, String commentText) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String url = sh.getString('url').toString();
      String lid = sh.getString('lid').toString();
      final urls = Uri.parse('$url/user_comment_post/');

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
        }
        else if (status == 'blocked') {
          // User is blocked due to 3 warnings
          Fluttertoast.showToast(
            msg: "🚫 Your account has been blocked for repeated violations.",
            backgroundColor: Colors.red,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_LONG,
          );

          // Redirect to login page
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyLoginPage(title: ''))
          );
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

  void showComments(BuildContext context, String postId) {
    TextEditingController commentController = TextEditingController();
    List<Map<String, String>> commentsList = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          Future<void> loadComments() async {
            commentsList = await fetchComments(postId);
            setModalState(() {});
          }

          loadComments();

          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Comments",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: commentsList.length,
                      itemBuilder: (context, index) {
                        bool isToxic = commentsList[index]['toxic'] == 'true';

                        return Container(
                          color: isToxic ? Colors.red[50] : Colors.transparent,
                          child: ListTile(
                            title: Text(
                              commentsList[index]['username']!,
                              style: TextStyle(
                                color: isToxic ? Colors.red : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isToxic)
                                  Text(
                                    "⚠️ Inappropriate content detected",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                Text(
                                  commentsList[index]['comment']!,
                                  style: TextStyle(
                                    color: isToxic ? Colors.red : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: "Write a comment...",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () async {
                          if (commentController.text.trim().isNotEmpty) {
                            await postComment(postId, commentController.text.trim());
                            commentController.clear();
                            await loadComments();
                          }
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeNewPage(title: '')),
            );
          }),
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(widget.title),
        ),
        body: ListView.builder(
          itemCount: id_.length,
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
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Image.network(
                      photo_[index],
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      content_[index],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      post_date_[index],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
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
                            showComments(context, id_[index]);
                          },
                          icon: const Icon(Icons.comment_outlined),
                          color: Colors.blueAccent,
                        ),
                        IconButton(
                          onPressed: () {
                            deletepost(id_[index]);
                          },
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.grey,
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
      ),
    );
  }
}