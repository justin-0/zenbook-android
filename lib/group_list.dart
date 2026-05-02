
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'Group_chat.dart'; // Your CreateGroupPage
import 'group_chat_screen.dart'; // To enter a group chat

class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  List<String> groupNames = [];
  List<String> groupIds = [];
  List<String> createdByNames = [];
  List<String> createdDates = [];

  String? baseUrl;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    loadSharedPrefsAndFetchGroups();
  }

  Future<void> loadSharedPrefsAndFetchGroups() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    baseUrl = sh.getString('url');
    currentUserId = sh.getString('lid');

    if (baseUrl != null && currentUserId != null) {
      await fetchGroups();
    } else {
      Fluttertoast.showToast(msg: 'URL or User ID not found');
    }
  }

  Future<void> fetchGroups() async {
    try {
      var url = '$baseUrl/view_group_list/?user_id=$currentUserId';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsondata = json.decode(response.body);
        if (jsondata['status'] == 'ok') {
          List<String> gNames = [];
          List<String> gIds = [];
          List<String> creators = [];
          List<String> dates = [];

          for (var group in jsondata["groups"]) {
            gNames.add(group['group_name'].toString());
            gIds.add(group['group_id'].toString());
            creators.add(group['created_by'].toString());
            dates.add(group['created_at'].toString());
          }

          setState(() {
            groupNames = gNames;
            groupIds = gIds;
            createdByNames = creators;
            createdDates = dates;
          });
        } else {
          setState(() {
            groupNames = [];
            groupIds = [];
            createdByNames = [];
            createdDates = [];
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching groups: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        backgroundColor: Colors.blueAccent,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchGroups();
        },
        child: groupNames.isEmpty
            ? ListView(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No Groups Found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ),
            ),
          ],
        )
            : ListView.builder(
          itemCount: groupNames.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.group, color: Colors.white),
                ),
                title: Text(
                  groupNames[index],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Created by: ${createdByNames[index]} \nOn: ${createdDates[index]}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyGroupChatPage(
                          title: groupNames[index],
                          groupId: groupIds[index], // Pass group ID here
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupPage()),
          ).then((_) {
            fetchGroups(); // Refresh after creating group
          });
        },
      ),
    );
  }
}
