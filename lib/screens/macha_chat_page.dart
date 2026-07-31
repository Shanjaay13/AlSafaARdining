import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/groq_service.dart';
import '../providers/cart_provider.dart';
import '../models/menu_data.dart';

class MachaChatPage extends StatefulWidget {
  const MachaChatPage({Key? key}) : super(key: key);

  @override
  State<MachaChatPage> createState() => _MachaChatPageState();
}

class _MachaChatPageState extends State<MachaChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Initial welcome message from Macha
    _messages.add({
      'sender': 'macha',
      'text': "Ayo boss! Welcome to Al Safa! AI Macha here ready to write order, recommend dishes, or just chat lah. Tell me what you want to eat, boss!",
      'time': DateTime.now(),
    });
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

    if (customText == null) {
      _messageController.clear();
    }

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

        // Find the item details from menu database
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

  // Option 2: Simulated voice recognition (vocal speech to text)
  void _simulateVoiceInput() {
    if (_isListening) return;

    setState(() {
      _isListening = true;
    });

    // Selection of realistic Mamak voice orders
    final simulatedOrders = [
      "Bagi saya satu roti telur dan milo ais kurang manis boss",
      "I want to order nasi lemak biasa, one extra chicken, and teh tarik hot",
      "Macha recommended combo set please",
      "One maggi goreng extra pedas and sirap bandung, ikat tepi!",
    ];
    final selectedOrder = (simulatedOrders..shuffle()).first;

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      _handleSendMessage(customText: selectedOrder);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061C14),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFD4A24C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent, color: Color(0xFF121412), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI MACHA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  _isLoading ? 'Macha typing...' : 'Mamak Waiter Online',
                  style: TextStyle(
                    color: _isLoading ? const Color(0xFFD4A24C) : Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          // API Key configuration panel removed as it is now securely integrated in the backend.

          // Message history list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMacha = msg['sender'] == 'macha';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  alignment: isMacha ? Alignment.centerLeft : Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: isMacha ? MainAxisAlignment.start : MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMacha) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 8, top: 4),
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B3D2F),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.restaurant_menu, color: Color(0xFFD4A24C), size: 14),
                          ),
                        ),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isMacha ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMacha ? const Color(0xFF1A2A22) : const Color(0xFFD4A24C),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMacha ? const Radius.circular(0) : const Radius.circular(16),
                                  bottomRight: isMacha ? const Radius.circular(16) : const Radius.circular(0),
                                ),
                                border: isMacha ? Border.all(color: const Color(0xFFD4A24C).withOpacity(0.15)) : null,
                              ),
                              child: Text(
                                msg['text'],
                                style: TextStyle(
                                  color: isMacha ? Colors.white : const Color(0xFF121412),
                                  fontSize: 13.5,
                                  height: 1.3,
                                ),
                              ),
                            ),

                            // Render recommendation cards if available
                            if (isMacha && msg['items'] != null && msg['items'].isNotEmpty) ...[
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

          // Listening overlay
          if (_isListening)
            Container(
              color: Colors.black.withOpacity(0.8),
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic, color: Color(0xFFD4A24C), size: 24),
                  const SizedBox(width: 16),
                  const Text(
                    'Listening (Simulating voice match)...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  _buildAnimatedWaveform(),
                ],
              ),
            ),

          // Input control bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: const Color(0xFF061C14),
            child: Row(
              children: [
                // Simulated voice recognition trigger
                GestureDetector(
                  onTap: _simulateVoiceInput,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isListening ? const Color(0xFFD4A24C) : const Color(0xFF121412),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.mic,
                      color: _isListening ? const Color(0xFF121412) : const Color(0xFFD4A24C),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Text field input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121412),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.15)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Type order or ask Macha...',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFD4A24C)),
                  onPressed: () => _handleSendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCardList(List<dynamic> items) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Column(
      children: items.map((rawItem) {
        final id = rawItem['id'];
        final menuMatch = MenuData.items.firstWhere(
          (m) => m['id'] == id,
          orElse: () => <String, dynamic>{},
        );

        if (menuMatch.isEmpty) return const SizedBox.shrink();

        return Container(
          width: 220,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1D1B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4A24C).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  menuMatch['imagePath'],
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.white10, height: 100),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menuMatch['name'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RM ${menuMatch['price'].toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFFD4A24C), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A24C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          cart.addItem(
                            id: id,
                            name: menuMatch['name'],
                            price: menuMatch['price'],
                            imagePath: menuMatch['imagePath'],
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${menuMatch['name']} to shopping bag!'),
                              backgroundColor: const Color(0xFF0F2A1D),
                            ),
                          );
                        },
                        child: const Text(
                          'ADD TO BAG',
                          style: TextStyle(color: Color(0xFF121412), fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedWaveform() {
    return Row(
      children: List.generate(4, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: 15.0 + (i * 5),
          decoration: BoxDecoration(
            color: const Color(0xFFD4A24C),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
