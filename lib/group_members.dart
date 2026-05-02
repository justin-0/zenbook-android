import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GroupMembersPage extends StatefulWidget {
  final String groupId;

  const GroupMembersPage({super.key, required this.groupId});

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  List<String> memberFirstNames = [];
  List<String> memberLastNames = [];
  List<String> memberProfilePics = [];
  List<String> memberIds = [];

  String? baseUrl;
  String imgUrl = '';

  @override
  void initState() {
    super.initState();
    loadSharedPrefsAndFetchMembers();
  }

  Future<void> loadSharedPrefsAndFetchMembers() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    baseUrl = sh.getString('url');
    imgUrl = sh.getString('img_url') ?? '';

    if (baseUrl != null) {
      await fetchGroupMembers();
    } else {
      Fluttertoast.showToast(msg: 'Base URL not found');
    }
  }

  Future<void> fetchGroupMembers() async {
    try {
      var url = '$baseUrl/view_group_members/?group_id=${widget.groupId}';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsondata = json.decode(response.body);
        if (jsondata['status'] == 'ok') {
          List<String> fNames = [];
          List<String> lNames = [];
          List<String> pics = [];
          List<String> ids = [];

          for (var member in jsondata["members"]) {
            fNames.add(member['first_name'].toString());
            lNames.add(member['last_name'].toString());
            String picUrl = member['profile_pic']?.toString() ?? '';
            if (picUrl.isNotEmpty && !picUrl.startsWith('http')) {
              picUrl = imgUrl + picUrl;
            }
            pics.add(picUrl);
            ids.add(member['user_id'].toString());
          }

          setState(() {
            memberFirstNames = fNames;
            memberLastNames = lNames;
            memberProfilePics = pics;
            memberIds = ids;
          });
        } else {
          setState(() {
            memberFirstNames = [];
            memberLastNames = [];
            memberProfilePics = [];
            memberIds = [];
          });
          Fluttertoast.showToast(msg: jsondata['message'] ?? 'Failed to load members');
        }
      } else {
        Fluttertoast.showToast(msg: 'Failed to load members, status code ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching members: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Members'),
        backgroundColor: const Color.fromARGB(255, 18, 82, 98),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchGroupMembers();
        },
        child: memberFirstNames.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No Members',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: memberFirstNames.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: memberProfilePics[index].isNotEmpty
                      ? NetworkImage(memberProfilePics[index])
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                  radius: 25,
                ),
                title: Text(
                  '${memberFirstNames[index]} ${memberLastNames[index]}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
