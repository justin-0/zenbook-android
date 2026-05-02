import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'homenew.dart';

void main() {
  runApp(const ViewComments());
}

class ViewComments extends StatelessWidget {
  const ViewComments({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'View Comment',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 18, 82, 98)),
        useMaterial3: true,
      ),
      home: const ViewCommentsPage(title: 'My Posts'),
    );
  }
}

class ViewCommentsPage extends StatefulWidget {
  const ViewCommentsPage({super.key, required this.title});
  final String title;

  @override
  State<ViewCommentsPage> createState() => _ViewCommentsPageState();
}

class _ViewCommentsPageState extends State<ViewCommentsPage> {
  // TextEditingController iconController= new TextEditingController();

  List<String> comment_ = [];
  List<String> user_ = [];
  List<String> id_ = [];


  _ViewCommentsPageState() {
    view_comments();
  }

  Future<void> view_comments() async {
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
        body:
        ListView.builder(
          itemCount: id_.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Image

                  const SizedBox(height: 10),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      comment_[index],

                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      user_[index],

                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),



                  const SizedBox(height: 10),

                  // Action Buttons: Like, Comment, Delete

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
