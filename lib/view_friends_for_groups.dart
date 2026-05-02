
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'group_chat_screen.dart';

class ViewFriendsPage extends StatefulWidget {
  final String groupId;

  const ViewFriendsPage({super.key, required this.groupId});

  @override
  State<ViewFriendsPage> createState() => _ViewFriendsPageState();
}

class _ViewFriendsPageState extends State<ViewFriendsPage> {
  // Friend Requests data
  List<String> frFirstNames = [];
  List<String> frLastNames = [];
  List<String> frProfilePics = [];
  List<String> frRequestIds = [];
  List<String> frSenderIds = [];

  String? currentUserId;
  String? baseUrl;
  String imgUrl = '';

  @override
  void initState() {
    super.initState();
    loadSharedPrefsAndFetchData();
  }

  Future<void> loadSharedPrefsAndFetchData() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    baseUrl = sh.getString('url');
    currentUserId = sh.getString('lid');
    imgUrl = sh.getString('img_url') ?? '';

    if (baseUrl != null && currentUserId != null) {
      await fetchFriends();
    } else {
      Fluttertoast.showToast(msg: 'URL or user ID not found');
    }
  }

  Future<void> fetchFriends() async {
    try {
      var url = '$baseUrl/view_friends_for_group/?user_id=$currentUserId';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsondata = json.decode(response.body);
        if (jsondata['status'] == 'ok') {
          List<String> fNames = [];
          List<String> lNames = [];
          List<String> pics = [];
          List<String> reqIds = [];
          List<String> sIds = [];

          for (var fr in jsondata["friend_requests"]) {
            fNames.add(fr['sender_first_name'].toString());
            lNames.add(fr['sender_last_name'].toString());
            pics.add(imgUrl + (fr['profile_pic']?.toString() ?? ''));
            reqIds.add(fr['request_id'].toString());
            sIds.add(fr['sender_id'].toString());
          }

          setState(() {
            frFirstNames = fNames;
            frLastNames = lNames;
            frProfilePics = pics;
            frRequestIds = reqIds;
            frSenderIds = sIds;
          });
        } else {
          setState(() {
            frFirstNames = [];
            frLastNames = [];
            frProfilePics = [];
            frRequestIds = [];
            frSenderIds = [];
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching friend requests: $e");
    }
  }

  // Moved _send_data inside the State class to access context
  void _send_data(String groupId, String userId) async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');

    if (url == null || url.isEmpty) {
      Fluttertoast.showToast(msg: 'Base URL not found');
      return;
    }

    final Uri apiUrl = Uri.parse('$url/add_group_member/');

    try {
      final response = await http.post(apiUrl, body: {
        "group_id": groupId,
        "user_id": userId,
      });

      if (response.statusCode == 200) {
        var jsonResp = jsonDecode(response.body);
        if (jsonResp['status'] == 'ok' || jsonResp['message'] == 'Member added') {
          Fluttertoast.showToast(msg: 'Add Successful');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyGroupChatPage(title: 'Group Chat', groupId: groupId),
            ),
          );
        } else {
          Fluttertoast.showToast(msg: 'Failed to add member');
        }
      } else {
        Fluttertoast.showToast(msg: 'Network Error: ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: const Color.fromARGB(255, 18, 82, 98),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchFriends();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (frFirstNames.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Friend List',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: frFirstNames.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: frProfilePics[index].isNotEmpty
                                ? NetworkImage(frProfilePics[index])
                                : const AssetImage('assets/default_profile.png') as ImageProvider,
                            radius: 25,
                          ),
                          title: Text(
                            '${frFirstNames[index]} ${frLastNames[index]}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add_alt_1, color: Colors.green),
                            tooltip: "Add Friend to Group",
                            onPressed: () {
                              _send_data(widget.groupId, frSenderIds[index]);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No Friends',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
