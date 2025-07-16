import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../navigation/side_navigation.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final ChatUser currentUser = ChatUser(id: '1', firstName: 'You');
  final ChatUser botUser = ChatUser(id: '2', firstName: 'আলাপযন্ত্র');

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  List<ChatMessage> messages = [
    ChatMessage(
      text: 'Welcome to Alap Zontro for KUET CSE!',
      user: ChatUser(id: '2', firstName: 'আলাপযন্ত্র'),
      createdAt: DateTime.now(),
    ),
  ];

  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final backgroundGradient = const LinearGradient(
      colors: [Color(0xFF0e0e2c), Color(0xFF0e0e2c), Color(0xFF0e0e2c)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -10) {
          scaffoldKey.currentState?.openEndDrawer();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        endDrawer: const SideNavigation(),
        backgroundColor: const Color.fromARGB(255, 56, 56, 109),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: const Color.fromARGB(255, 56, 56, 109),
          elevation: 0,
          centerTitle: true,
          title: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 255, 255, 255),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Text(
              'আলাপযন্ত্র',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 25,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Column(
            children: [
              Expanded(
                child: DashChat(
                  currentUser: currentUser,
                  onSend: _onSend,
                  messages: messages,
                  messageOptions: MessageOptions(
                    containerColor: const Color(0xFF232659),
                    textColor: Colors.white,
                    currentUserContainerColor: const Color(0xFF2B175C),
                    currentUserTextColor: Colors.white,
                    borderRadius: 18,
                    messagePadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    showOtherUsersAvatar: true,
                    showCurrentUserAvatar: false,
                    avatarBuilder: (user, onTap, onLongPress) {
                      if (user.id == botUser.id) {
                        return CircleAvatar(
                          backgroundColor: Colors.cyanAccent.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            'আ',
                            style: GoogleFonts.poppins(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return CircleAvatar(
                        backgroundColor: Colors.deepPurpleAccent.withValues(
                          alpha: 0.15,
                        ),
                        child: Icon(Icons.person, color: Colors.white),
                      );
                    },

                    timeFormat: DateFormat('h:mm a'),
                  ),
                  inputOptions: InputOptions(
                    inputTextStyle: GoogleFonts.poppins(color: Colors.white),
                    inputDecoration: InputDecoration(
                      fillColor: const Color(0xFF232659),
                      filled: true,
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF8B9DC3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    sendButtonBuilder: (onSend) => Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        onPressed: _isSending ? null : onSend,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF00FFD0),
                          size: 22,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF232659),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isSending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.cyanAccent,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Bot is typing...",
                        style: GoogleFonts.poppins(
                          color: Colors.cyanAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  // Message send utility
  void _onSend(ChatMessage message) async {
    setState(() {
      messages.insert(0, message);
      _isSending = true;
    });

    final botReply = await _getBotResponse(message.text);

    if (mounted) {
      setState(() {
        messages.insert(
          0,
          ChatMessage(text: botReply, user: botUser, createdAt: DateTime.now()),
        );
        _isSending = false;
      });
    }
  }

  // Get response from AI utility
  Future<String> _getBotResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('https://alap-zontro.onrender.com/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': userMessage}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['response'] ?? 'No response from bot';
      } else {
        return 'Server error: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Connection error: Unable to reach server. Please check your internet connection.';
    }
  }
}
