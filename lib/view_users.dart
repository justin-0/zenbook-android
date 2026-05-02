import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'homenew.dart';

class FriendsAndUsersPage extends StatefulWidget {
  const FriendsAndUsersPage({super.key});

  @override
  State<FriendsAndUsersPage> createState() => _FriendsAndUsersPageState();
}

class _FriendsAndUsersPageState extends State<FriendsAndUsersPage> {
  // Friend Requests data
  List<String> frFirstNames = [];
  List<String> frLastNames = [];
  List<String> frProfilePics = [];
  List<String> frRequestIds = [];
  List<String> frSenderIds = [];

  // All Users data
  List<String> userFirstNames = [];
  List<String> userLastNames = [];
  List<String> userProfilePics = [];
  List<String> userIds = [];
  List<String> userRequestStatus = [];

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
      await fetchFriendRequests();
      await fetchUsers();
    } else {
      Fluttertoast.showToast(msg: 'URL or user ID not found');
    }
  }

  Future<void> fetchFriendRequests() async {
    try {
      var url = '$baseUrl/view_friend_requests/?user_id=$currentUserId';
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

  Future<void> fetchUsers() async {
    try {
      var url = '$baseUrl/view_all_users/?lid=$currentUserId';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsondata = json.decode(response.body);
        if (jsondata['status'] == 'ok') {
          List<String> fNames = [];
          List<String> lNames = [];
          List<String> pics = [];
          List<String> ids = [];
          List<String> statuses = [];

          for (var user in jsondata["users"]) {
            fNames.add(user['first_name'].toString());
            lNames.add(user['last_name'].toString());
            pics.add(imgUrl + (user['profile_pic']?.toString() ?? ''));
            ids.add(user['id'].toString());
            statuses.add(user['friend_request_status']?.toString() ?? 'none');
          }

          setState(() {
            userFirstNames = fNames;
            userLastNames = lNames;
            userProfilePics = pics;
            userIds = ids;
            userRequestStatus = statuses;
          });
        } else {
          setState(() {
            userFirstNames = [];
            userLastNames = [];
            userProfilePics = [];
            userIds = [];
            userRequestStatus = [];
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching users: $e");
    }
  }

  Future<void> respondToFriendRequest(String requestId, int index, String status) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/respond_friend_request/'),
        body: {
          'request_id': requestId,
          'status': status,
        },
      );
      var jsondata = json.decode(response.body);
      if (jsondata['status'] == 'ok') {
        Fluttertoast.showToast(msg: jsondata['message'] ?? 'Response saved');
        setState(() {
          // Remove from friend requests list after response
          frFirstNames.removeAt(index);
          frLastNames.removeAt(index);
          frProfilePics.removeAt(index);
          frRequestIds.removeAt(index);
          frSenderIds.removeAt(index);
        });
      } else {
        Fluttertoast.showToast(msg: jsondata['message'] ?? 'Failed to respond');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> sendFriendRequest(String receiverId, int index) async {
    try {
      var senderId = currentUserId;
      var response = await http.post(
        Uri.parse('$baseUrl/send_friend_request/'),
        body: {
          'sender_id': senderId,
          'receiver_id': receiverId,
        },
      );
      var jsondata = json.decode(response.body);
      if (jsondata['status'] == 'ok') {
        Fluttertoast.showToast(msg: jsondata['message'] ?? 'Request sent');
        setState(() {
          userRequestStatus[index] = 'pending';
        });
      } else {
        Fluttertoast.showToast(msg: jsondata['message'] ?? 'Failed to send request');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> cancelFriendRequest(String receiverId, int index) async {
    try {
      var senderId = currentUserId;
      var response = await http.post(
        Uri.parse('$baseUrl/cancel_friend_request/'),
        body: {
          'sender_id': senderId,
          'receiver_id': receiverId,
        },
      );
      var jsondata = json.decode(response.body);
      if (jsondata['status'] == 'ok') {
        Fluttertoast.showToast(msg: jsondata['message'] ?? 'Request cancelled');
        setState(() {
          userRequestStatus[index] = 'none';
        });
      } else {
        Fluttertoast.showToast(msg: jsondata['message'] ?? 'Failed to cancel request');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  void onUserRequestPressed(int index) {
    final status = userRequestStatus[index];
    final userId = userIds[index];

    if (status == 'none' || status == 'rejected') {
      sendFriendRequest(userId, index);
    } else if (status == 'pending') {
      cancelFriendRequest(userId, index);
    } else if (status == 'accepted') {
      Fluttertoast.showToast(msg: 'You are already friends');
    }
  }

  void onFriendRequestConfirm(int index) {
    respondToFriendRequest(frRequestIds[index], index, 'accepted');
  }

  void onFriendRequestDelete(int index) {
    respondToFriendRequest(frRequestIds[index], index, 'rejected');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests & Users'),
        backgroundColor: const Color.fromARGB(255, 18, 82, 98),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchFriendRequests();
          await fetchUsers();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Friend Requests Section
                if (frFirstNames.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Friend Requests',
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
                        margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: frProfilePics[index].isNotEmpty
                                ? NetworkImage(frProfilePics[index])
                                : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                            radius: 25,
                          ),
                          title: Text(
                            '${frFirstNames[index]} ${frLastNames[index]}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Status: Pending'),
                          trailing: SizedBox(
                            width: 160,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      onFriendRequestConfirm(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Confirm'),
                                ),
                                const SizedBox(width: 10),

                              ],
                            ),
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
                        'No Friend Requests',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // All Users Section
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'All Users',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                userFirstNames.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No users to show',
                      style: TextStyle(
                          fontSize: 18, color: Colors.grey.shade600),
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userFirstNames.length,
                  itemBuilder: (context, index) {
                    final status = userRequestStatus[index];
                    late final IconData icon;
                    late final String buttonText;
                    late final Color buttonColor;

                    switch (status) {
                      case 'pending':
                        icon = Icons.cancel;
                        buttonText = 'Cancel Request';
                        buttonColor = Colors.orange;
                        break;
                      case 'accepted':
                        icon = Icons.check;
                        buttonText = 'Friends';
                        buttonColor = Colors.green;
                        break;
                      case 'rejected':
                      case 'none':
                      default:
                        icon = Icons.person_add;
                        buttonText = 'Add Friend';
                        buttonColor = Colors.blueAccent;
                    }

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Profile pic + Name in a Column
                            Column(
                              children: [
                                CircleAvatar(
                                  backgroundImage: userProfilePics[index].isNotEmpty
                                      ? NetworkImage(userProfilePics[index])
                                      : const AssetImage('assets/default_profile.png')
                                  as ImageProvider,
                                  radius: 25,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${userFirstNames[index]} ${userLastNames[index]}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // Button at the right side
                            ElevatedButton.icon(
                              onPressed: () => onUserRequestPressed(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: Icon(icon, size: 18),
                              label: Text(buttonText),
                            ),
                          ],
                        ),
                      ),
                    );

                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
