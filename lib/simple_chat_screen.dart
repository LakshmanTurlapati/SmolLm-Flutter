import 'package:flutter/material.dart';
import 'dart:async';
import 'services/llm_service.dart';
import 'models/chat_models.dart';

class SimpleChatScreen extends StatefulWidget {
  const SimpleChatScreen({super.key});

  @override
  State<SimpleChatScreen> createState() => _SimpleChatScreenState();
}

class _SimpleChatScreenState extends State<SimpleChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();
  final LLMService _llmService = LLMService();
  final ChatConversation _conversation = ChatConversation(
    systemPrompt: 'You are a helpful, friendly AI assistant running on SmolLM2-360M. Keep your responses concise and helpful.',
  );
  
  bool _isProcessing = false;
  bool _isModelLoading = false;
  String _currentAssistantMessage = '';
  late AnimationController _typingAnimationController;
  StreamSubscription<String>? _responseSubscription;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _initializeModel();
  }
  
  Future<void> _initializeModel() async {
    setState(() {
      _isModelLoading = true;
    });
    
    try {
      await _llmService.initialize(
        onProgress: () {
          // Model download progress
          if (mounted) {
            setState(() {});
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Model initialization error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
      
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _responseSubscription?.cancel();
    _typingAnimationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _llmService.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isProcessing || !_llmService.isInitialized) return;

    final userMessage = _controller.text.trim();
    _controller.clear();
    
    // Add user message to UI
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isAssistant: false,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
      _currentAssistantMessage = '';
    });
    
    // Add user message to conversation
    _conversation.addUserMessage(userMessage);

    // Add assistant message placeholder
    setState(() {
      _messages.add(ChatMessage(
        text: '',
        isAssistant: true,
        timestamp: DateTime.now(),
        isComplete: false,
      ));
    });

    _scrollToBottom();

    try {
      // Get messages with system prompt
      final messages = _conversation.getMessagesWithSystem();
      
      // Generate response stream
      final responseStream = _llmService.generateResponse(
        messages: messages,
        maxTokens: 512,
        temperature: 0.7,
      );
      
      String fullResponse = '';
      
      // Listen to response stream
      _responseSubscription = responseStream.listen(
        (token) {
          fullResponse += token;
          setState(() {
            _currentAssistantMessage = fullResponse;
            if (_messages.isNotEmpty && _messages.last.isAssistant) {
              _messages.last.text = _currentAssistantMessage;
            }
          });
          _scrollToBottom();
        },
        onDone: () {
          // Mark as complete and add to conversation
          _conversation.addAssistantMessage(fullResponse);
          setState(() {
            if (_messages.isNotEmpty && _messages.last.isAssistant) {
              _messages.last.isComplete = true;
            }
            _currentAssistantMessage = '';
            _isProcessing = false;
          });
        },
        onError: (error) {
          // Handle error
          setState(() {
            if (_messages.isNotEmpty && _messages.last.isAssistant) {
              _messages.last.text = 'Error: Unable to generate response. Please try again.';
              _messages.last.isComplete = true;
            }
            _currentAssistantMessage = '';
            _isProcessing = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        cancelOnError: true,
      );
    } catch (e) {
      // Handle initialization or other errors
      setState(() {
        if (_messages.isNotEmpty && _messages.last.isAssistant) {
          _messages.last.text = 'Error: Model not ready. Please wait for initialization.';
          _messages.last.isComplete = true;
        }
        _currentAssistantMessage = '';
        _isProcessing = false;
      });
    }
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
      backgroundColor: const Color(0xFF343541),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF202123),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10A37F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'SmolLM Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _isProcessing ? null : () {
              setState(() {
                _messages.clear();
                _currentAssistantMessage = '';
                _conversation.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isModelLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10A37F)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading SmolLM2-360M model...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'First time loading may take a moment\nto download the model (~271MB)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(
                          message: _messages[index],
                          showTyping: !_messages[index].isComplete && _messages[index].isAssistant,
                          typingAnimation: _typingAnimationController,
                        );
                      },
                    ),
            ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF40414F),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Send a message...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: const Color(0xFF343541),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isProcessing && !_isModelLoading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _isProcessing || _controller.text.isEmpty
                          ? const Color(0xFF343541)
                          : const Color(0xFF10A37F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _isProcessing || _isModelLoading || _controller.text.isEmpty
                          ? null
                          : _sendMessage,
                      icon: Icon(
                        Icons.send,
                        color: _isProcessing || _controller.text.isEmpty
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  String text;
  final bool isAssistant;
  final DateTime timestamp;
  bool isComplete;

  ChatMessage({
    required this.text,
    required this.isAssistant,
    required this.timestamp,
    this.isComplete = true,
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTyping;
  final AnimationController? typingAnimation;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTyping = false,
    this.typingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isAssistant 
            ? MainAxisAlignment.start 
            : MainAxisAlignment.end,
        children: [
          if (message.isAssistant) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF10A37F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isAssistant 
                    ? const Color(0xFF444654)
                    : const Color(0xFF343541),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: message.isAssistant
                      ? Colors.transparent
                      : const Color(0xFF565869),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTyping && message.text.isEmpty)
                    AnimatedBuilder(
                      animation: typingAnimation!,
                      builder: (context, child) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (index) {
                            final delayedAnimation = Tween(
                              begin: 0.0,
                              end: 1.0,
                            ).animate(
                              CurvedAnimation(
                                parent: typingAnimation!,
                                curve: Interval(
                                  index * 0.2,
                                  0.6 + index * 0.2,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            );
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: Transform.translate(
                                offset: Offset(0, -4 * delayedAnimation.value),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    )
                  else
                    Text(
                      message.text.isEmpty && !message.isComplete 
                          ? '...' 
                          : message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!message.isAssistant) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6E6E80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}