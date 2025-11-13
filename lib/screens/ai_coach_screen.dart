import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:job_tinder/services/gemini_matching_score.dart';
import 'package:job_tinder/themes/app_theme.dart';

// Helper class to store messages
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  late final ChatSession _chatSession;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = true; // Start in loading state

  @override
  void initState() {
    super.initState();
    _startChat();
  }

  Future<void> _startChat() async {
    // 1. Start the chat session with the general AI Coach prompt
    _chatSession = GeminiMatchingService.startAiCoachChat();
    
    // 2. Send an initial message to get the AI's greeting
    final aiResponse = await GeminiMatchingService.sendChatMessage(
      chat: _chatSession,
      message: "Hello", // This triggers the AI's greeting
    );

    setState(() {
      _messages.add(ChatMessage(text: aiResponse, isUser: false));
      _isLoading = false;
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _textController.text;
    if (messageText.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: messageText, isUser: true));
      _isLoading = true; // AI is "thinking"
    });

    _scrollToBottom();

    // Send to Gemini and get response
    final aiResponse = await GeminiMatchingService.sendChatMessage(
      chat: _chatSession,
      message: messageText,
    );

    setState(() {
      _messages.add(ChatMessage(text: aiResponse, isUser: false));
      _isLoading = false;
    });
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Career Coach'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: LinearProgressIndicator(),
            ),
          _buildChatInput(),
        ],
      ),
    );
  }

  // (This widget is identical to the one in mock_interview_screen.dart)
  Widget _buildMessageBubble(ChatMessage message) {
    final align =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isUser
        ? AppTheme.primaryColor
        : Colors.grey.shade200;
    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 16, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // (This widget is identical to the one in mock_interview_screen.dart)
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask your question...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.primaryColor),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}