import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/groq_service.dart';
import '../providers/cart_provider.dart';
import '../models/menu_data.dart';

class MachaChatPage extends StatefulWidget {
  const MachaChatPage({Key? key}) : super(key: key);

  @override
  State<MachaChatPage> createState() => _MachaChatPageState();
}

class _MachaChatPageState extends State<MachaChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  
  late stt.SpeechToText _speech;
  late AnimationController _pulseController;
  
  bool _isLoading = false;
  bool _isListening = false;
  bool _speechInitialized = false;
  String _recognizedWords = '';
  String _speechStatus = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Initial welcome message from Macha
    _messages.add({
      'sender': 'macha',
      'text': "Ayo boss! Welcome to Al Safa! AI Macha here ready to write order, recommend dishes, or just chat lah. Tap the mic button to speak your order, boss!",
      'time': DateTime.now(),
    });
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          setState(() {
            _speechStatus = status;
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
            }
          });
        },
        onError: (errorNotification) {
          setState(() {
            _speechStatus = 'Error: ${errorNotification.errorMsg}';
            _isListening = false;
          });
        },
      );
      setState(() {
        _speechInitialized = available;
      });
    } catch (e) {
      debugPrint('Speech initialization error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _handleSendMessage({String? customText}) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _recognizedWords = '';
    });

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });
    _scrollToBottom();

    // Call GroqService
    final response = await GroqService.sendMessage(text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _messages.add({
        'sender': 'macha',
        'text': response['reply'] ?? "Sorry boss, my server is a bit busy, curry flood in kitchen!",
        'time': DateTime.now(),
        'action': response['action'],
        'items': response['items'],
      });
    });

    // Handle cart actions
    if (response['action'] == 'ADD_TO_CART' && response['items'] != null) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      for (var rawItem in response['items']) {
        final id = rawItem['id'];
        final quantity = rawItem['quantity'] ?? 1;
        final notes = rawItem['notes'];

        final menuMatch = MenuData.items.firstWhere(
          (m) => m['id'] == id,
          orElse: () => <String, dynamic>{},
        );

        if (menuMatch.isNotEmpty) {
          for (int i = 0; i < quantity; i++) {
            cart.addItem(
              id: id,
              name: menuMatch['name'],
              price: menuMatch['price'],
              imagePath: menuMatch['imagePath'],
              notes: notes,
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Macha added ${menuMatch['name']} to your bag!'),
              backgroundColor: const Color(0xFFD4A24C),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
    _scrollToBottom();
  }

  // Toggle real voice recognition with fast streaming dictation
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      if (_recognizedWords.trim().isNotEmpty) {
        final textToSend = _recognizedWords.trim();
        _handleSendMessage(customText: textToSend);
      }
    } else {
      if (!_speechInitialized) {
        await _initSpeech();
      }

      setState(() {
        _isListening = true;
        _recognizedWords = '';
      });

      try {
        // Detect Malaysian speech recognizer locale (ms_MY or en_MY)
        String? selectedLocale;
        final locales = await _speech.locales();
        for (var loc in locales) {
          final id = loc.localeId.toLowerCase();
          if (id.contains('ms_my') || id.contains('ms-my') || id.contains('en_my') || id.contains('en-my')) {
            selectedLocale = loc.localeId;
            break;
          }
        }

        await _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            setState(() {
              _recognizedWords = result.recognizedWords;
              _messageController.text = result.recognizedWords;
            });

            if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
              final finalWords = result.recognizedWords.trim();
              _speech.stop();
              setState(() {
                _isListening = false;
              });
              if (Navigator.canPop(context)) Navigator.pop(context);
              _handleSendMessage(customText: finalWords);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          localeId: selectedLocale,
        );
      } catch (e) {
        debugPrint('Listen error: $e');
      }

      _showLiveVoiceListeningSheet();
    }
  }

  // Live voice listening bottom sheet dialog with waveform and real-time words display
  void _showLiveVoiceListeningSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF142A22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Color(0xFFD4A24C), blurRadius: 16, spreadRadius: -4),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Pulsing Mic Icon
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.all(16 + (_pulseController.value * 8)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A24C).withOpacity(0.2 + (_pulseController.value * 0.3)),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: Color(0xFFD4A24C), size: 40),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'LISTENING TO YOUR VOICE...',
                    style: TextStyle(
                      color: Color(0xFFD4A24C),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedWords.isEmpty
                        ? 'Speak your order now (e.g. "Satu roti telur dan milo ais")...'
                        : '"$_recognizedWords"',
                    style: TextStyle(
                      color: _recognizedWords.isEmpty ? Colors.white54 : Colors.white,
                      fontSize: 15,
                      fontWeight: _recognizedWords.isEmpty ? FontWeight.normal : FontWeight.bold,
                      fontStyle: _recognizedWords.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Quick Sample Voice Chips for immediate voice simulation
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      "Bagi 1 roti telur & milo ais kurang manis",
                      "One nasi goreng ayam extra pedas",
                      "1 Teh tarik hot & roti kosong",
                    ].map((sample) {
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _speech.stop();
                          setState(() {
                            _isListening = false;
                          });
                          _handleSendMessage(customText: sample);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A24C).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
                          ),
                          child: Text(
                            '"$sample"',
                            style: const TextStyle(color: Color(0xFFD4A24C), fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.graphic_eq, color: Color(0xFFD4A24C), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'POWERED BY GROQ LLaMA 3.3 70B AI ENGINE',
                        style: TextStyle(color: Color(0xFFD4A24C), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            _speech.stop();
                            setState(() {
                              _isListening = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A24C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.send, color: Color(0xFF121412), size: 18),
                          label: const Text(
                            'SEND ORDER',
                            style: TextStyle(color: Color(0xFF121412), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: () {
                            _speech.stop();
                            setState(() {
                              _isListening = false;
                            });
                            Navigator.pop(context);
                            if (_recognizedWords.trim().isNotEmpty) {
                              _handleSendMessage(customText: _recognizedWords.trim());
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Backup dictation dialog
  void _showVoiceInputDialog() {
    final TextEditingController voiceTextController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF142A22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A24C).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Color(0xFFD4A24C), size: 36),
              ),
              const SizedBox(height: 12),
              const Text(
                'VOICE ORDER DICTATION',
                style: TextStyle(
                  color: Color(0xFFD4A24C),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dictate or tap a sample order below to test AI Macha',
                style: TextStyle(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: voiceTextController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Speak or type your order here...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black38,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: const Color(0xFFD4A24C).withOpacity(0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: const Color(0xFFD4A24C).withOpacity(0.4)),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  "Bagi 1 roti telur & milo ais kurang manis",
                  "One nasi goreng ayam extra pedas",
                  "1 Teh tarik hot & roti kosong",
                ].map((sample) {
                  return InkWell(
                    onTap: () {
                      voiceTextController.text = sample;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A24C).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
                      ),
                      child: Text(
                        '"$sample"',
                        style: const TextStyle(color: Color(0xFFD4A24C), fontSize: 10.5, fontStyle: FontStyle.italic),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A24C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (voiceTextController.text.trim().isNotEmpty) {
                          _handleSendMessage(customText: voiceTextController.text.trim());
                        }
                      },
                      child: const Text(
                        'SEND ORDER',
                        style: TextStyle(color: Color(0xFF121412), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2A1D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD4A24C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFD4A24C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.face, color: Color(0xFF0F2A1D), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'AI Macha Waiter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online • Groq AI Order Assistant',
                  style: TextStyle(color: Color(0xFFD4A24C), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message Trajectory Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFD4A24C),
                          child: const Icon(Icons.face, color: Color(0xFF0F2A1D), size: 18),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUser ? const Color(0xFFD4A24C) : const Color(0xFF142A22),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 18),
                                ),
                                border: Border.all(
                                  color: isUser ? const Color(0xFFD4A24C) : const Color(0xFFD4A24C).withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                msg['text'],
                                style: TextStyle(
                                  color: isUser ? const Color(0xFF121412) : Colors.white,
                                  fontSize: 14,
                                  fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),

                            // If AI Macha recommends or adds items to cart, render item cards directly in chat
                            if (!isUser && msg['items'] != null && (msg['items'] as List).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildRecommendationCardList(msg['items']),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFD4A24C), strokeWidth: 2))),
            ),

          // Real Voice Listening Bar Overlay
          if (_isListening)
            Container(
              color: Colors.black.withOpacity(0.85),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Color(0xFFD4A24C), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _recognizedWords.isEmpty ? 'Listening to your voice...' : '"$_recognizedWords"',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A24C),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _toggleListening,
                    child: const Text('SEND', style: TextStyle(color: Color(0xFF121412), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Input control bar with glowing Mic Voice trigger
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: const Color(0xFF061C14),
            child: Row(
              children: [
                // Real Voice Recognition Button (Pulsing Gold)
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isListening ? const Color(0xFFD4A24C) : const Color(0xFF142A22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD4A24C).withOpacity(_isListening ? 1.0 : 0.6),
                            width: _isListening ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4A24C).withOpacity(0.3 + (_pulseController.value * 0.3)),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? const Color(0xFF121412) : const Color(0xFFD4A24C),
                          size: 22,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Text field input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121412),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Speak (mic) or type order...',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send Button
                GestureDetector(
                  onTap: () => _handleSendMessage(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4A24C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Color(0xFF121412), size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCardList(List<dynamic> items) {
    return Container(
      height: 135,
      margin: const EdgeInsets.only(top: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, idx) {
          final item = items[idx];
          final String id = item['id'] ?? '';
          final menuMatch = MenuData.items.firstWhere(
            (m) => m['id'] == id,
            orElse: () => <String, dynamic>{},
          );

          if (menuMatch.isEmpty) return const SizedBox();

          return Container(
            width: 210,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2A1D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        menuMatch['imagePath'],
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: const Color(0xFF142A22),
                          child: const Icon(Icons.restaurant, color: Color(0xFFD4A24C), size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menuMatch['name'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'RM ${(menuMatch['price'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(color: Color(0xFFD4A24C), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                            Text(
                              item['notes'],
                              style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A24C),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF121412), size: 14),
                    label: const Text(
                      'ADD TO BAG',
                      style: TextStyle(color: Color(0xFF121412), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                    ),
                    onPressed: () {
                      final cart = Provider.of<CartProvider>(context, listen: false);
                      cart.addItem(
                        id: menuMatch['id'],
                        name: menuMatch['name'],
                        price: menuMatch['price'],
                        imagePath: menuMatch['imagePath'],
                        notes: item['notes'],
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${menuMatch['name']} to your bag!'),
                          backgroundColor: const Color(0xFFD4A24C),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
