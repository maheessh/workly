import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:job_tinder/services/gemini_matching_score.dart';
import 'package:job_tinder/themes/app_theme.dart';

// --- ADDED ---
// Import the new package to render Markdown
import 'package:flutter_markdown/flutter_markdown.dart';

// Helper class
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

class _AiCoachScreenState extends State<AiCoachScreen>
    with TickerProviderStateMixin {
  late final ChatSession _chatSession;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = true;

  late final AnimationController _orbPulseController;

  @override
  void initState() {
    super.initState();

    _orbPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.92,
      upperBound: 1.08,
    )..repeat(reverse: true);

    _startChat();
  }

  @override
  void dispose() {
    _orbPulseController.dispose();
    _textController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _startChat() async {
    try {
      _chatSession = GeminiMatchingService.startAiCoachChat();

      final aiResponse = await GeminiMatchingService.sendChatMessage(
        chat: _chatSession,
        message: "Hello",
      );

      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
        _isLoading = false;
      });

      _scrollChatToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text:
              "Sorry, I couldn't connect to the AI coach. Please check your network.",
          isUser: false,
        ));
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
    });

    _scrollChatToBottom();

    try {
      final aiResponse = await GeminiMatchingService.sendChatMessage(
        chat: _chatSession,
        message: message,
      );

      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
        _isLoading = false;
      });

      _scrollChatToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Oops, I couldn't get a response. Please try again.",
          isUser: false,
        ));
        _isLoading = false;
      });
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- MODIFIED ---
  // This widget is updated to use MarkdownBody instead of Text
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        // Use MarkdownBody to render formatted text
        child: MarkdownBody(
          data: msg.text,
          // Use a stylesheet to make the text look like your original design
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            // This styles the regular paragraph text
            p: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.4,
            ),
            // This styles the bullet points
            listBullet: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.4,
            ),
            // This ensures bold text also gets the right color
            strong: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask me anything about your career...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: Icon(Icons.send,
                  color: _isLoading ? Colors.grey : AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('AI Career Coach'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),

      // ----------------------------------------------------------------------
      // EVERYTHING scrollable EXCEPT bottom chat input
      // ----------------------------------------------------------------------
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              // Allows header + chat to scroll safely without overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------ HEADER SECTION -------------------
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _orbPulseController,
                          child: Container(
                            width: 75,
                            height: 75,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2AB34A),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x992AB34A),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome to AI Career Coach",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Get started by asking anything about your career. Smart tips, resume help, interview practice.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // ---------------- Feature Cards --------------------
                  

                  const SizedBox(height: 16),

                  // ---------------- Chat Messages --------------------
                  ListView.builder(
                    itemCount: _messages.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(_messages[index]),
                  ),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: LinearProgressIndicator(),
                    ),

                  const SizedBox(height: 100), // Space above input
                ],
              ),
            ),
          ),

          // ---------------- Bottom Chat Input --------------------
          _buildChatInput(),
        ],
      ),
    );
  }
}