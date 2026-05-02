import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'group_list.dart';
import 'dart:convert';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> createGroup() async {
    String groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter group name");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url') ?? '';
      String lid = sh.getString('lid') ?? '';
      String url = '$urls/create_group/';

      var response = await http.post(
        Uri.parse(url),
        body: {
          'group_name': groupName,
          'lid': lid, // 🔹 Changed to match Django request.POST['lid']
        },
      );

      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {

        Fluttertoast.showToast(
          msg: "✅ Group created successfully (ID: ${jsondata['group_id']})",

        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GroupListPage()),
        );
        _groupNameController.clear();
      } else {
        Fluttertoast.showToast(
          msg: jsondata['message'] ?? "Failed to create group",
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Group"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter Group Name",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                hintText: "Group name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : createGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blueAccent,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Create Group",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
