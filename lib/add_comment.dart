import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'login.dart';

void main() {
  runApp(const AddComment());
}

class AddComment extends StatelessWidget {
  const AddComment({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AddComment',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AddCommentPage(title: 'AddComment'),
    );
  }
}

class AddCommentPage extends StatefulWidget {
  const AddCommentPage({super.key, required this.title});

  final String title;

  @override
  State<AddCommentPage> createState() => _AddCommentPageState();
}

class _AddCommentPageState extends State<AddCommentPage> {
  List<String> comment_ = [];
  List<String> user_ = [];
  List<String> id_ = [];

  TextEditingController commentController = TextEditingController();

  _AddCommentPageState() {
    comment_view();
  }

  Future<void> comment_view() async {
    List<String> comment = [];
    List<String> user = [];
    List<String> id = [];

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url')!;
      String lid = sh.getString('lid')!;
      String cid = sh.getString('cid')!;
      String url = '$urls/view_comments/';

      var response = await http.post(Uri.parse(url), body: {
        'lid': lid,
        'pid': cid,
      });

      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        var arr = jsondata["data"];
        for (var post in arr) {
          user.add(post['user'].toString());
          comment.add(post['comment_text'].toString());
          id.add(post['id'].toString());
        }

        setState(() {
          comment_ = comment;
          user_ = user;
          id_ = id;
        });
      } else {
        Fluttertoast.showToast(msg: 'No comments found');
      }
    } catch (e) {
      print("Error: ${e.toString()}");
    }
  }

  void comment_data() async {
    String comment = commentController.text;

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();
    String lid = sh.getString('lid').toString();
    String cid = sh.getString('cid').toString();

    final urls = Uri.parse('$url/comment_post/');
    try {
      final response = await http.post(urls, body: {
        "comment_text": comment,
        "post_id": cid,
        "user_id": lid,
      });

      if (response.statusCode == 200) {
        String status = jsonDecode(response.body)['status'];
        if (status == 'ok') {
          Fluttertoast.showToast(msg: 'Comment posted successfully');
          commentController.clear();
          comment_view(); // refresh comments
        } else {
          Fluttertoast.showToast(msg: 'Failed to post comment');
        }
      } else {
        Fluttertoast.showToast(msg: 'Network Error');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: const Color(0xFF6C5CE7),
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Comments list (scrollable)
            Expanded(
              child: ListView.builder(
                reverse: false,
                itemCount: id_.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 5,
                    margin:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            comment_[index],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            user_[index],
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w400),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Fixed bottom input field + send button
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.grey.shade300),
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
                      onPressed: comment_data,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      child: const Text(
                        "Send",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
