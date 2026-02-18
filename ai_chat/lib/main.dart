import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chatbot',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  bool _isAITyping = false;

  Future<String> _getAIResponse(String userMessage) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$_apiKey',
    );

    String fullPrompt =
        '''Use casual language, you're sarcastic and witty. do not use slang, and don't try to come off like a person. You can use emoticons (eg. :), :p, <3, :D, etc), do not use emojis!! Be enthusiastic but not over-the-top. You are here to help so keep that priority in mind. keep your messages short and effective, start sentences with lowercase letters. KEEP MESSAGES SHORT AND EFFECTIVCE!!

User message: $userMessage''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': fullPrompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      print('Error: ${response.statusCode}');
      print('Response: ${response.body}');
      return 'Sorry, I got an error: ${response.statusCode}';
    }
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _controller.text = '';
      _isAITyping = true;
    });

    String aiResponse = await _getAIResponse(message);
    setState(() {
      _isAITyping = false;
      _messages.add(ChatMessage(text: aiResponse, isUser: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("AI Chatbot"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(child: Text('start chatting !'))
                : ListView.builder(
                    itemCount: _messages.length + (_isAITyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return MessageBubble(
                          message: ChatMessage(text: '...', isUser: false),
                        );
                      }
                      return MessageBubble(message: _messages[index]);
                    },
                  ),
          ),

          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'type a messsage...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    controller: _controller,
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color.fromARGB(255, 120, 67, 211)
              : Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: message.isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
