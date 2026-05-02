import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'editprofile1.dart';
void main() {
  runApp(const ViewProfile());
}

class ViewProfile extends StatelessWidget {
  const ViewProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'View Profile',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ViewProfilePage(title: 'View Profile'),
    );
  }
}

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key, required this.title});

  final String title;

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {

  _ViewProfilePageState()
  {
    _send_data();
  }
  @override
  // Your existing variables
  String name_ = "";
  String first_name_="";
  String last_name_="";
  String dob_ = "";
  String gender_ = "";
  String email_ = "";
  String phone_ = "";
  String place_ = "";
  String date_="";
  String photo_ = "";

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async { return true; },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Profile Header Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 40, top: 20),
                child: Column(
                  children: [
                    // Profile Image with enhanced styling
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 75,
                        backgroundColor: Colors.white,
                        child: photo_.isNotEmpty
                            ? ClipOval(
                          child: Image.network(
                            photo_,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                            : const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      name_.isNotEmpty ? name_ : "No Name",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Information Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Information Cards
                    _buildInfoCard(
                      icon: Icons.person_outline,
                      label: " Name",
                      value: first_name_.isNotEmpty ? '$first_name_ $last_name_' : "Not specified",
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.cake_outlined,
                      label: "Date of Birth",
                      value: dob_.isNotEmpty ? dob_ : "Not specified",
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 16),

                    _buildInfoCard(
                      icon: Icons.person_outline,
                      label: "Gender",
                      value: gender_.isNotEmpty ? gender_ : "Not specified",
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),

                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      label: "Email",
                      value: email_.isNotEmpty ? email_ : "Not specified",
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),

                    _buildInfoCard(
                      icon: Icons.phone_outlined,
                      label: "Phone",
                      value: phone_.isNotEmpty ? phone_ : "Not specified",
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),

                    _buildInfoCard(
                      icon: Icons.location_on_outlined,
                      label: "Location",
                      value: place_.isNotEmpty ? place_ : "Not specified",
                      color: Colors.purple,
                    ),
                   

                    const SizedBox(height: 32),

                    // Enhanced Edit Profile Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyEditPage(title: "Edit Profile"),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Edit Profile",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper method to build information cards
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send_data() async{



    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();
    String lid = sh.getString('lid').toString();

    final urls = Uri.parse('$url/viewprofile/');
    try {
      final response = await http.post(urls, body: {
        'lid':lid



      });
      if (response.statusCode == 200) {
        String status = jsonDecode(response.body)['status'];
        if (status=='ok') {
          String name=jsonDecode(response.body)['name'];
          String first_name=jsonDecode(response.body)['first_name'];
          String last_name=jsonDecode(response.body)['last_name'];
          String dob=jsonDecode(response.body)['dob'];
          String gender=jsonDecode(response.body)['gender'];
          String email=jsonDecode(response.body)['email'];
          String phone=jsonDecode(response.body)['phone'];
          String place=jsonDecode(response.body)['place'];
          // String date=jsonDecode(response.body)['date'];
          String photo=url+jsonDecode(response.body)['profile_pic'];

          setState(() {

            name_= name;
            first_name_=first_name;
            last_name_=last_name;
            dob_= dob;
            gender_= gender;
            email_= email;
            phone_= phone;
            place_= place;
            // date_=date;
            photo_= photo;
          });





        }else {
          Fluttertoast.showToast(msg: 'Not Found');
        }
      }
      else {
        Fluttertoast.showToast(msg: 'Network Error');
      }
    }
    catch (e){
      Fluttertoast.showToast(msg: e.toString());
    }
  }
}
