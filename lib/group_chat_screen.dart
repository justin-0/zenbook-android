
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
import 'group_members.dart';
import 'view_friends_for_groups.dart';

class MyGroupChatPage extends StatefulWidget {
  final String title;
  final String groupId;

  const MyGroupChatPage({
    super.key,
    required this.title,
    required this.groupId,
  });

  @override
  State<MyGroupChatPage> createState() => _MyGroupChatPageState();
}

class ChatMessage {
  String messageContent;
  String messageType;
  String senderName;
  String? audioUrl;
  bool isToxic;

  ChatMessage({
    required this.messageContent,
    required this.messageType,
    required this.senderName,
    this.audioUrl,
    this.isToxic = false,
  });
}

class _MyGroupChatPageState extends State<MyGroupChatPage> {
  List<ChatMessage> messages = [];
  TextEditingController te_message = TextEditingController();
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late FlutterSoundRecorder _audioRecorder;
  bool _isRecording = false;
  String? _audioPath;
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;
  bool _isRecorderInitialized = false;
  final ScrollController _scrollController = ScrollController(); // Add this

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _initRecorder();
    viewMessages();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      viewMessages();
    });
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start recording. Please check permissions.'))
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to stop recording: $e'))
        );
      }
    }
  }

  Future<void> sendAudioMessage(String audioPath) async {
    try {
      final pref = await SharedPreferences.getInstance();
      String baseUrl = pref.getString("url") ?? "";
      String senderId = pref.getString("lid") ?? "";

      if (widget.groupId.isEmpty || baseUrl.isEmpty) return;

      String url = "$baseUrl/group_chat_send/";

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['group_id'] = widget.groupId;
      request.fields['sender_id'] = senderId;

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
      } else {
        print('Failed to send audio: ${response.statusCode}');
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

    print("Playing audio from URL: $url");

    if (url.isEmpty) return;

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
        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentlyPlayingUrl = null;
            });
          }
        });
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
    } else {
      throw Exception('Failed to download audio');
    }
  }

  Future<void> viewMessages() async {
    try {
      final pref = await SharedPreferences.getInstance();
      String baseUrl = pref.getString('url') ?? "";
      String userId = pref.getString("lid") ?? "";

      if (widget.groupId.isEmpty || baseUrl.isEmpty) return;

      var url = "$baseUrl/group_chat_view/";
      var response = await http.post(Uri.parse(url), body: {
        'group_id': widget.groupId,
      });

      if (response.statusCode == 200) {
        var jsondata = json.decode(response.body);
        var arr = jsondata["messages"] ?? [];

        List<ChatMessage> tempMessages = [];
        for (var msg in arr) {
          String senderId = msg['sender_id'].toString();
          String currentUserId = userId.toString();

          String messageType = (senderId == currentUserId) ? "sender" : "receiver";
          String senderName = msg['sender_name'] ?? "Unknown";

          String rawAudioPath = msg['audio']?.toString() ?? '';
          String audioUrl = '';
          if (rawAudioPath.isNotEmpty) {
            audioUrl = rawAudioPath.startsWith('http')
                ? rawAudioPath
                : '$baseUrl/${rawAudioPath.startsWith('/') ? rawAudioPath.substring(1) : rawAudioPath}';
          }

          bool toxic = msg['toxic'].toString() == "true";

          tempMessages.add(ChatMessage(
            messageContent: msg['message'] ?? "",
            messageType: messageType,
            senderName: senderName,
            audioUrl: audioUrl,
            isToxic: toxic,
          ));
        }

        setState(() {
          messages = tempMessages;
        });

        // Scroll to bottom after messages are updated
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      print("Error fetching messages: $e");
    }
  }

  Future<void> sendMessage() async {
    try {
      final pref = await SharedPreferences.getInstance();
      String baseUrl = pref.getString("url") ?? "";
      String senderId = pref.getString("lid") ?? "";

      if (te_message.text.trim().isEmpty || widget.groupId.isEmpty) return;

      String url = "$baseUrl/group_chat_send/";
      var response = await http.post(Uri.parse(url), body: {
        'group_id': widget.groupId,
        'sender_id': senderId,
        'message': te_message.text.trim(),
      });

      if (response.statusCode == 200) {
        te_message.clear();
        viewMessages();
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    te_message.dispose();
    _audioPlayer.dispose();
    _audioRecorder.closeRecorder();
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.group, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupMembersPage(groupId: widget.groupId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewFriendsPage(groupId: widget.groupId),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          ListView.builder(
            controller: _scrollController, // Add controller here
            itemCount: messages.length,
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            itemBuilder: (context, index) {
              final chat = messages[index];
              final hasAudio = chat.audioUrl != null && chat.audioUrl!.isNotEmpty;
              final isPlayingThis = _isPlaying && _currentlyPlayingUrl == chat.audioUrl;

              return Container(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: (chat.messageType == "receiver"
                      ? Alignment.topLeft
                      : Alignment.topRight),
                  child: Column(
                    crossAxisAlignment: chat.messageType == "receiver"
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      if (chat.messageType == "receiver")
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            chat.senderName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      if (chat.messageContent.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: chat.isToxic
                                ? Colors.red.shade100
                                : (chat.messageType == "receiver"
                                ? Colors.grey.shade200
                                : Colors.blue[200]),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            chat.messageContent,
                            style: TextStyle(
                              fontSize: 15,
                              color: chat.isToxic ? Colors.red.shade900 : Colors.black,
                              fontWeight: chat.isToxic ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      if (hasAudio)
                        Container(
                          margin: EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: chat.isToxic
                                ? Colors.red.shade100
                                : (chat.messageType == "receiver"
                                ? Colors.grey.shade200
                                : Colors.blue[200]),
                          ),
                          padding: EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPlayingThis ? Icons.stop : Icons.play_arrow,
                                  color: chat.isToxic ? Colors.red : Colors.green,
                                ),
                                onPressed: () {
                                  if (chat.audioUrl != null) {
                                    playAudio(chat.audioUrl!);
                                  }
                                },
                              ),
                              Text(
                                "Audio message",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: chat.isToxic ? Colors.red.shade900 : Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.audiotrack,
                                size: 20,
                                color: chat.isToxic ? Colors.red : Colors.black54,
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
                    onPressed: sendMessage,
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