

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';

void main() {
  runApp(const MyChatApp());
}

class MyChatApp extends StatelessWidget {
  const MyChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Clone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyChatPage(title: 'WhatsApp Clone'),
    );
  }
}

class MyChatPage extends StatefulWidget {
  const MyChatPage({super.key, required this.title});

  final String title;

  @override
  State<MyChatPage> createState() => _MyChatPageState();
}

class ChatMessage {
  String messageContent;
  String messageType;
  String? audioUrl;
  bool isToxic;

  ChatMessage({
    required this.messageContent,
    required this.messageType,
    this.audioUrl,
    this.isToxic = false,
  });
}

class _MyChatPageState extends State<MyChatPage> {
  String name = "";
  final AudioPlayer _audioPlayer = AudioPlayer();
  late FlutterSoundRecorder _audioRecorder;
  bool _isRecording = false;
  String? _audioPath;
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;
  bool _isRecorderInitialized = false;
  Timer? _messageTimer;
  final ScrollController _scrollController = ScrollController(); // Added scroll controller

  List<ChatMessage> messages = [];
  TextEditingController te_message = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _initRecorder();
    _startMessageTimer();
    view_message();
  }

  // Add this method to scroll to bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _startMessageTimer() {
    _messageTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        view_message();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _initRecorder() async {
    try {
      await _requestMicrophonePermission();
      await _audioRecorder.openRecorder();
      setState(() {
        _isRecorderInitialized = true;
      });
    } catch (e) {
      print("Error initializing recorder: $e");
    }
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
    await Permission.storage.request();
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) {
      await _initRecorder();
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/audio_message.aac';
      await _audioRecorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );
      if (mounted) {
        setState(() {
          _isRecording = true;
          _audioPath = path;
        });
      }
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await _audioRecorder.stopRecorder();
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
      if (path != null) {
        await sendAudioMessage(path);
      }
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<void> sendAudioMessage(String audioPath) async {
    try {
      final pref = await SharedPreferences.getInstance();
      String url = '${pref.getString('url')}/user_chat_send/';
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['from_id'] = pref.getString("lid")!;
      request.fields['to_id'] = pref.getString("aid")!;
      request.fields['message'] = '';
      File audioFile = File(audioPath);
      List<int> audioBytes = await audioFile.readAsBytes();
      String extension = audioPath.split('.').last;
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: 'audio_message.$extension',
      ));
      var response = await request.send();
      if (response.statusCode == 200) {
        print('Audio sent successfully');
      }
    } catch (e) {
      print("Error sending audio: $e");
    }
  }

  Future<void> playAudio(String url) async {
    if (_isPlaying && _currentlyPlayingUrl == url) {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingUrl = null;
        });
      }
      return;
    }
    if (_currentlyPlayingUrl != null) {
      await _audioPlayer.stop();
    }
    try {
      await _downloadAndPlayAudio(url);
    } catch (e) {
      print("Download and play failed: $e");
      try {
        await _audioPlayer.play(UrlSource(url));
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _currentlyPlayingUrl = url;
          });
        }
      } catch (e2) {
        print("Direct URL playback failed: $e2");
      }
    }
  }

  Future<void> _downloadAndPlayAudio(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/temp_audio.aac');
      await file.writeAsBytes(response.bodyBytes);
      await _audioPlayer.play(DeviceFileSource(file.path));
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _currentlyPlayingUrl = url;
          _scrollToBottom(); // Scroll to bottom when audio starts playing
        });
      }
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingUrl = null;
          });
        }
        file.delete();
      });
    }
  }

  Future<void> view_message() async {
    if (!mounted) return;
    try {
      final pref = await SharedPreferences.getInstance();
      String currentName = pref.getString("agrname") ?? "";
      String baseUrl = pref.getString('url') ?? "";
      String url = '$baseUrl/chat_view_user/';
      var data = await http.post(Uri.parse(url), body: {
        'from_id': pref.getString("lid") ?? "",
        'to_id': pref.getString("aid") ?? ""
      });
      var jsondata = json.decode(data.body);
      var arr = jsondata["data"];
      List<ChatMessage> newMessages = [];
      for (int i = 0; i < arr.length; i++) {
        String messageType = (pref.getString("lid") == arr[i]['from'].toString())
            ? "sender"
            : "receiver";
        String rawAudioPath = arr[i]['audio']?.toString() ?? '';
        String audioUrl = '';
        if (rawAudioPath.isNotEmpty) {
          if (rawAudioPath.startsWith('http')) {
            audioUrl = rawAudioPath;
          } else {
            String cleanPath = rawAudioPath.startsWith('/')
                ? rawAudioPath.substring(1)
                : rawAudioPath;
            audioUrl = '$baseUrl/$cleanPath';
          }
        }

        // Check toxicity flag from server
        bool isToxic = arr[i]['toxic']?.toString() == "true";

        newMessages.add(ChatMessage(
          messageContent: arr[i]['msg']?.toString() ?? '',
          messageType: messageType,
          audioUrl: audioUrl,
          isToxic: isToxic,
        ));
      }
      if (mounted) {
        setState(() {
          name = currentName;
          messages = newMessages;
        });

        // Scroll to bottom after messages are updated
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      print("Error loading messages: $e");
    }
  }

  Future<void> sendTextMessage() async {
    String message = te_message.text.toString();
    if (message.isEmpty) return;
    try {
      final pref = await SharedPreferences.getInstance();
      String ip = pref.getString("url") ?? "";
      String url = '$ip/user_chat_send/';
      await http.post(Uri.parse(url), body: {
        'message': message,
        'from_id': pref.getString("lid") ?? "",
        'to_id': pref.getString("aid") ?? ""
      });
      te_message.text = "";
      view_message(); // Refresh messages after sending
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.closeRecorder();
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.0,
        leadingWidth: 0.0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              radius: 20.0,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                splashRadius: 1.0,
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 24.0,
                ),
              ),
            ),
            Text(name),
            SizedBox(width: 40.0),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          ListView.builder(
            controller: _scrollController, // Add controller here
            itemCount: messages.length,
            shrinkWrap: true,
            padding: EdgeInsets.only(top: 10, bottom: 80),
            physics: ScrollPhysics(),
            itemBuilder: (context, index) {
              final isSender = messages[index].messageType == "sender";
              final hasAudio = messages[index].audioUrl != null && messages[index].audioUrl!.isNotEmpty;
              final isPlayingThis = _isPlaying && _currentlyPlayingUrl == messages[index].audioUrl;
              final isToxic = messages[index].isToxic;

              return Container(
                padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
                child: Align(
                  alignment: isSender ? Alignment.topRight : Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (messages[index].messageContent.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isToxic
                                ? Colors.red[300]
                                : (isSender ? Colors.blue[200] : Colors.grey.shade200),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Text(
                            messages[index].messageContent,
                            style: TextStyle(
                              fontSize: 15,
                              color: isToxic ? Colors.white : Colors.black,
                              fontWeight: isToxic ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      if (hasAudio)
                        Container(
                          margin: EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isToxic
                                ? Colors.red[300]
                                : (isSender ? Colors.blue[200] : Colors.grey.shade200),
                          ),
                          padding: EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPlayingThis ? Icons.stop : Icons.play_arrow,
                                  color: isToxic ? Colors.white : Colors.green,
                                ),
                                onPressed: () {
                                  if (messages[index].audioUrl != null) {
                                    playAudio(messages[index].audioUrl!);
                                  }
                                },
                              ),
                              Text(
                                "Audio message",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isToxic ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.audiotrack,
                                size: 20,
                                color: isToxic ? Colors.white : Colors.black54,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 80,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: te_message,
                      decoration: InputDecoration(
                          hintText: "Write message...",
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none),
                    ),
                  ),
                  SizedBox(width: 15),
                  IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording ? Colors.red : Colors.cyan,
                    ),
                    onPressed: () async {
                      if (_isRecording) {
                        await stopRecording();
                      } else {
                        await startRecording();
                      }
                    },
                  ),
                  SizedBox(width: 15),
                  FloatingActionButton(
                    onPressed: sendTextMessage,
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                    backgroundColor: Colors.cyan,
                    elevation: 0,
                  ),
                ],
              ),
            ),
          ),
          if (_isRecording)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: stopRecording,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic, color: Colors.white, size: 30),
                        SizedBox(height: 8),
                        Text(
                          "Recording... Tap to stop",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}