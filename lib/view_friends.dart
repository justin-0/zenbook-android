// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'chatscreen.dart';
// import 'homenew.dart';
//
// class FriendsPage extends StatefulWidget {
//   const FriendsPage({super.key});
//
//   @override
//   State<FriendsPage> createState() => _FriendsPageState();
// }
//
// class _FriendsPageState extends State<FriendsPage> {
//   // Friend Requests data
//   List<String> frFirstNames = [];
//   List<String> id_ = [];
//   List<String> frLastNames = [];
//   List<String> frProfilePics = [];
//   List<String> frRequestIds = [];
//   List<String> frSenderIds = [];
//
//   // All Users data
//   List<String> userFirstNames = [];
//   List<String> userLastNames = [];
//   List<String> userProfilePics = [];
//   List<String> userIds = [];
//   List<String> userRequestStatus = [];
//
//   String? currentUserId;
//   String? baseUrl;
//   String imgUrl = '';
//
//   @override
//   void initState() {
//     super.initState();
//     loadSharedPrefsAndFetchData();
//   }
//
//   Future<void> loadSharedPrefsAndFetchData() async {
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     baseUrl = sh.getString('url');
//     currentUserId = sh.getString('lid');
//     imgUrl = sh.getString('img_url') ?? '';
//
//     if (baseUrl != null && currentUserId != null) {
//       await fetchFriends();
//     } else {
//       Fluttertoast.showToast(msg: 'URL or user ID not found');
//     }
//   }
//
//   Future<void> fetchFriends() async {
//     try {
//       var url = '$baseUrl/view_friend_list/?user_id=$currentUserId';
//       var response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         var jsondata = json.decode(response.body);
//         if (jsondata['status'] == 'ok') {
//           List<String> fNames = [];
//           List<String> id = [];
//           List<String> lNames = [];
//           List<String> pics = [];
//           List<String> reqIds = [];
//           List<String> sIds = [];
//
//           for (var fr in jsondata["friend_requests"]) {
//             fNames.add(fr['sender_first_name'].toString());
//             lNames.add(fr['sender_last_name'].toString());
//             pics.add(imgUrl + (fr['profile_pic']?.toString() ?? ''));
//             reqIds.add(fr['request_id'].toString());
//             sIds.add(fr['sender_id'].toString());
//           }
//
//           setState(() {
//             frFirstNames = fNames;
//             frLastNames = lNames;
//             frProfilePics = pics;
//             frRequestIds = reqIds;
//             frSenderIds = sIds;
//           });
//         } else {
//           setState(() {
//             frFirstNames = [];
//             frLastNames = [];
//             frProfilePics = [];
//             frRequestIds = [];
//             frSenderIds = [];
//           });
//         }
//       }
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error fetching friend requests: $e");
//     }
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Friends'),
//         backgroundColor: const Color.fromARGB(255, 18, 82, 98),
//       ),
//       body: RefreshIndicator(
//         onRefresh: () async {
//           await fetchFriends();
//         },
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Padding(
//             padding: const EdgeInsets.all(8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Friend Requests Section
//                 if (frFirstNames.isNotEmpty) ...[
//                   const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 8),
//                     child: Text(
//                       'Friend List',
//                       style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                   ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: frFirstNames.length,
//                     itemBuilder: (context, index) {
//                       return Card(
//                         elevation: 3,
//                         margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: ListTile(
//                           leading: CircleAvatar(
//                             backgroundImage: frProfilePics[index].isNotEmpty
//                                 ? NetworkImage(frProfilePics[index])
//                                 : const AssetImage('assets/default_profile.png') as ImageProvider,
//                             radius: 25,
//                           ),
//                           title: Text(
//                             '${frFirstNames[index]} ${frLastNames[index]}',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           trailing: IconButton(
//                             icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
//                             onPressed: () async {
//                               SharedPreferences sh = await SharedPreferences.getInstance();
//                               sh.setString('aid', frSenderIds[index]); // friend user id
//                               sh.setString('agrname', '${frFirstNames[index]} ${frLastNames[index]}');
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => MyChatPage(title: ''),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ] else
//                   Center(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 20),
//                       child: Text(
//                         'No Friends',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
// }

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'chatscreen.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<String> friendFirstNames = [];
  List<String> friendLastNames = [];
  List<String> friendProfilePics = [];
  List<String> friendIds = [];

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
      var url = '$baseUrl/view_friend_list/?user_id=$currentUserId';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsondata = json.decode(response.body);
        if (jsondata['status'] == 'ok') {
          List<String> fNames = [];
          List<String> lNames = [];
          List<String> pics = [];
          List<String> ids = [];

          for (var friend in jsondata["friends"]) {
            fNames.add(friend['first_name'].toString());
            lNames.add(friend['last_name'].toString());
            // profile_pic could be relative or empty string, concatenate imgUrl if needed
            var picUrl = friend['profile_pic']?.toString() ?? '';
            if (picUrl.isNotEmpty && !picUrl.startsWith('http')) {
              picUrl = imgUrl + picUrl;
            }
            pics.add(picUrl);
            ids.add(friend['user_id'].toString());
          }

          setState(() {
            friendFirstNames = fNames;
            friendLastNames = lNames;
            friendProfilePics = pics;
            friendIds = ids;
          });
        } else {
          setState(() {
            friendFirstNames = [];
            friendLastNames = [];
            friendProfilePics = [];
            friendIds = [];
          });
          Fluttertoast.showToast(msg: jsondata['message'] ?? 'Failed to load friends');
        }
      } else {
        Fluttertoast.showToast(msg: 'Failed to load friends, status code ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching friends: $e");
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
        child: friendFirstNames.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No Friends',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: friendFirstNames.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: friendProfilePics[index].isNotEmpty
                      ? NetworkImage(friendProfilePics[index])
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                  radius: 25,
                ),
                title: Text(
                  '${friendFirstNames[index]} ${friendLastNames[index]}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  onPressed: () async {
                    SharedPreferences sh = await SharedPreferences.getInstance();
                    await sh.setString('aid', friendIds[index]); // friend user id
                    await sh.setString('agrname', '${friendFirstNames[index]} ${friendLastNames[index]}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyChatPage(title: ''),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

