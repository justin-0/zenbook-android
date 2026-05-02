import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'homenew.dart';

void main() {
  runApp(const ComplaintScreen());
}

class ComplaintScreen extends StatelessWidget {
  const ComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complaints',
      theme: ThemeData(
        colorScheme:
        ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 18, 82, 98)),
        useMaterial3: true,
      ),
      home: const ComplaintPage(title: 'My Complaints & Send Complaint'),
    );
  }
}

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key, required this.title});
  final String title;

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  List<String> id_ = [];
  List<String> complaint_ = [];
  List<String> complaint_date_ = [];
  List<String> reply_ = [];
  List<String> status_ = [];

  TextEditingController complaintController = TextEditingController();

  @override
  void initState() {
    super.initState();
    view_complaint();
  }

  Future<void> view_complaint() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String urls = sh.getString('url') ?? '';
    String lid = sh.getString('lid') ?? '';

    String url = '$urls/view_complaints/';

    var response = await http.post(Uri.parse(url), body: {'lid': lid});
    var jsondata = json.decode(response.body);

    if (jsondata['status'] == 'ok') {
      List<String> id = [];
      List<String> complaint = [];
      List<String> date = [];
      List<String> reply = [];
      List<String> status = [];

      var arr = jsondata["data"];
      for (var comp in arr) {
        id.add(comp['id'].toString());
        complaint.add(comp['message'].toString());
        date.add(comp['date'].toString());
        reply.add(comp['reply'].toString());
        status.add(comp['status'].toString());
      }

      setState(() {
        id_ = id;
        complaint_ = complaint;
        complaint_date_ = date;
        reply_ = reply;
        status_ = status;
      });
    } else {
      Fluttertoast.showToast(msg: 'No complaints found');
      setState(() {
        id_ = [];
        complaint_ = [];
        complaint_date_ = [];
        reply_ = [];
        status_ = [];
      });
    }
  }

  Future<void> deleteComplaint(String complaintId) async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String urls = sh.getString('url') ?? '';
    String lid = sh.getString('lid') ?? '';

    String url = '$urls/delete_complaint/';

    var response = await http.post(Uri.parse(url), body: {
      'lid': lid,
      'id': complaintId,
    });

    var jsondata = json.decode(response.body);

    if (jsondata['status'] == 'ok') {
      Fluttertoast.showToast(msg: 'Complaint deleted successfully');
      await view_complaint();
    } else {
      Fluttertoast.showToast(msg: jsondata['message'] ?? 'Failed to delete complaint');
    }
  }

  void _sendData() async {
    String complaintText = complaintController.text.trim();
    if (complaintText.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your complaint");
      return;
    }

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');
    String? lid = sh.getString('lid');

    if (url == null) {
      Fluttertoast.showToast(msg: "URL not found in SharedPreferences");
      return;
    }

    Uri apiUrl = Uri.parse('$url/send_complaint/');

    var response = await http.post(apiUrl, body: {
      'complaint': complaintText,
      'lid': lid,
    });

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      if (jsonData['status'] == 'ok') {
        Fluttertoast.showToast(msg: 'Complaint sent successfully');
        complaintController.clear();
        await view_complaint();
      } else {
        Fluttertoast.showToast(msg: jsonData['message'] ?? 'Failed to send complaint');
      }
    } else {
      Fluttertoast.showToast(msg: 'Network Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeNewPage(title: '')),
            );
          }),
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            Expanded(
              child: id_.isEmpty
                  ? const Center(child: Text("No complaints to show"))
                  : ListView.builder(
                itemCount: id_.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint_[index],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Date: ${complaint_date_[index]}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Reply: ${reply_[index].isEmpty ? "No reply yet" : reply_[index]}',
                            style: const TextStyle(
                                fontSize: 14, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Status: ${status_[index]}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                              ),
                              onPressed: () {
                                // Confirm before deleting
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text(
                                        'Are you sure you want to delete this complaint?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          deleteComplaint(id_[index]);
                                        },
                                        child: const Text('Delete',
                                            style: TextStyle(
                                                color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Fixed bottom complaint input & send button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade200,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: complaintController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Write your complaint here...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _sendData,
                      child: const Text("Send"),
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
