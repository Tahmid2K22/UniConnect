import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0E2C),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 0, 0, 36),
          foregroundColor: Colors.white,
          elevation: 10,
          centerTitle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
        ),
      ),
      home: const BasicChat(),
    );
  }
}

class BasicChat extends StatefulWidget {
  const BasicChat({super.key});

  @override
  State<BasicChat> createState() => _BasicChatState();
}

class _BasicChatState extends State<BasicChat> {
  final ChatUser currentUser = ChatUser(id: '1', firstName: 'Tahmid');
  final ChatUser botUser = ChatUser(id: '2', firstName: 'আলাপযন্ত্র');

  List<ChatMessage> messages = [
    ChatMessage(
      text: 'welcome to Alap Zontro for KUET CSE!',
      user: ChatUser(id: '2', firstName: 'আলাপযন্ত্র'),
      createdAt: DateTime.now(),
    ),
  ];

  void _onSend(ChatMessage message) {
    setState(() {
      messages.insert(0, message);
    });

    _getBotResponse(message.text).then((botReply) {
      if (mounted) {
        setState(() {
          messages.insert(
            0,
            ChatMessage(
              text: botReply,
              user: botUser,
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    });
  }

  Future<String> _getBotResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(''),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('আলাপযন্ত্র')),
      body: DashChat(
        currentUser: currentUser,
        onSend: _onSend,
        messages: messages,
        messageOptions: MessageOptions(
          containerColor: const Color.fromARGB(255, 0, 31, 60),
          textColor: Colors.white,
          currentUserContainerColor: const Color.fromARGB(255, 0, 31, 85),
          currentUserTextColor: Color.fromARGB(255, 255, 255, 255),
          borderRadius: 20,
        ),
        inputOptions: InputOptions(
          inputTextStyle: const TextStyle(color: Colors.white),
          inputDecoration: InputDecoration(
            fillColor: const Color(0xFF232659),
            filled: true,
            hintText: 'Type a message...',
            hintStyle: const TextStyle(color: Color(0xFF8B9DC3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          sendButtonBuilder:
              (onSend) => Container(
                margin: const EdgeInsets.only(left: 8),
                child: IconButton(
                  onPressed: onSend,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF00BCD4),
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF232659),
                    shape: const CircleBorder(),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
