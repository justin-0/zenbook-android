
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:zenbook_android/view_post.dart';


void main() {
  runApp(const Addpost());
}

class Addpost extends StatelessWidget {
  const Addpost({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const Addpostpage(title: ''),
    );
  }
}

class Addpostpage extends StatefulWidget {
  const Addpostpage({super.key, required this.title});
  final String title;

  @override
  State<Addpostpage> createState() => _AddpostState();
}

class _AddpostState extends State<Addpostpage> {
  File? _selectedImage;
  String? _encodedImage;
  String photo = '';
  bool _isLoading = false;

  TextEditingController contentController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    dateController.text = DateTime.now().toString().split(' ')[0];
  }

  @override
  void dispose() {
    contentController.dispose();
    dateController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_selectedImage == null) {
      Fluttertoast.showToast(
        msg: 'Please select an image',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }
    if (contentController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please add content',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }
    if (dateController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select a date',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }
    return true;
  }

  Future<void> _chooseAndUploadImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Photo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final pickedImage = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (pickedImage != null) {
                          _processSelectedImage(pickedImage);
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Camera', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final pickedImage = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (pickedImage != null) {
                          _processSelectedImage(pickedImage);
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.photo_library,
                              color: Colors.green,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Gallery', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processSelectedImage(XFile pickedImage) {
    setState(() {
      _selectedImage = File(pickedImage.path);
      _encodedImage = base64Encode(_selectedImage!.readAsBytesSync());
      photo = _encodedImage.toString();
    });
  }

  Future<void> _checkPermissionAndChooseImage() async {
    _chooseAndUploadImage();
  }

  // ----------------- Updated sent_data -----------------
  void sent_data() async {
    setState(() {
      _isLoading = true;
    });

    String content = contentController.text.trim();
    String post_date = dateController.text;

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();
    String userId = sh.getString('lid') ?? '';

    final urls = Uri.parse('$url/add_post/');

    try {
      final response = await http.post(urls, body: {
        "user_id": userId,
        "image": photo,
        "content": content,
        "post_date": post_date,
      });

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String status = jsonResponse['status'];

        if (status == 'ok') {
          Fluttertoast.showToast(
            msg: jsonResponse['message'] ?? 'Post shared successfully!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ViewPostPage(title: 'View Post'),
            ),
          );
        } else if (status == 'error') {
          Fluttertoast.showToast(
            msg: jsonResponse['message'] ??
                '🚫 This image contains vulgar content and cannot be posted.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );

          // Clear the selected image
          setState(() {
            _selectedImage = null;
            _encodedImage = null;
            photo = '';
          });
        }
      } else {
        Fluttertoast.showToast(msg: 'Network Error');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  // -----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
              if (_validateForm()) {
                sent_data();
              }
            },
            child: Text(
              'Share',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Image selection area
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                            _encodedImage = null;
                            photo = '';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _checkPermissionAndChooseImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : GestureDetector(
                onTap: _checkPermissionAndChooseImage,
                child: Container(
                  height: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!, width: 2),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share a photo to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Content field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: contentController,
                maxLines: null,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Write your content...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
