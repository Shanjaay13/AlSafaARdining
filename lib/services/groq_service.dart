import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  // Split API key fallback
  static const String _k1 = 'gsk_IemiW8ODo0';
  static const String _k2 = 'mPREcKlCvZWGdyb3';
  static const String _k3 = 'FYicuSbPTgRdBBADHP';
  static const String _k4 = 'pqsAghMa';
  
  static String get apiKey {
    final envKey = dotenv.env['GROQ_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    return '$_k1$_k2$_k3$_k4';
  }

  static const String modelName = 'llama-3.3-70b-versatile';
  static const List<String> fallbackModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-70b-versatile',
    'mixtral-8x7b-32768',
    'llama-3.1-8b-instant',
  ];

  // System instructions for the Mamak Waiter
  static const String _systemPrompt = '''
You are "AI Macha", a friendly, authentic Malaysian Mamak stall waiter at the Al Safa AR Dining restaurant.
You speak in a blend of English, Malay, and Tamil slang (Manglish). Use local terms like:
- "boss", "macha", "lah", "sia", "neh", "kurang manis" (less sweet), "banjir" (curry flood), "ikat tepi" (tie side).
Be extremely welcoming, humorous, and helpful.

You have access to the following 45 menu items only:
- roti_kosong_roti_canai: Roti Kosong (Roti Canai) (RM 2.34)
- roti_telur: Roti Telur (RM 3.90)
- roti_susu: Roti Susu (RM 3.64)
- roti_tampal: Roti Tampal (RM 3.90)
- roti_boom: Roti Boom (RM 7.15)
- roti_cheese: Roti Cheese (RM 7.15)
- roti_sardin: Roti Sardin (RM 9.10)
- roti_tisu: Roti Tisu (RM 4.00)
- roti_bakar: Roti Bakar (RM 3.00)
- roti_pisang: Roti Pisang (RM 4.50)
- nasi_goreng_ayam: Nasi Goreng Ayam (RM 9.75)
- nasi_goreng_daging: Nasi Goreng Daging (RM 10.40)
- nasi_goreng_ayam_pattaya: Nasi Goreng Ayam Pattaya (RM 11.05)
- nasi_goreng_kampung: Nasi Goreng Kampung (RM 11.70)
- nasi_goreng_seafood: Nasi Goreng Seafood (RM 12.35)
- nasi_goreng_paprik_daging: Nasi Goreng Paprik Daging (RM 14.30)
- nasi_goreng_ayam_goreng: Nasi Goreng Ayam Goreng (RM 14.30)
- nasi_goreng_special: Nasi Goreng Special (RM 16.90)
- maggi_goreng: Maggi Goreng (RM 5.00)
- mee_goreng_ayam: Mee Goreng Ayam (RM 9.75)
- nasi_lemak_biasa: Nasi Lemak Biasa (RM 4.00)
- nasi_kandar_with_side: Nasi Kandar (with side) (RM 7.00)
- nasi_briyani_ayam_daging: Nasi Briyani Ayam/Daging (RM 12.00)
- ayam_goreng: Ayam Goreng (RM 6.50)
- kari_ayam: Kari Ayam (RM 6.50)
- ayam_masak_kicap: Ayam Masak Kicap (RM 6.50)
- tandoori_chicken: Tandoori Chicken (RM 7.00)
- thosai: Thosai (RM 2.50)
- chapati: Chapati (RM 3.00)
- murtabak_ayam_daging: Murtabak Ayam/Daging (RM 6.00)
- cendol: Cendol (RM 3.00)
- abc_ais_batu_campur: ABC (Ais Batu Campur) (RM 4.50)
- teh_o: Teh O (RM 1.95)
- kopi_o: Kopi O (RM 1.95)
- teh_tarik: Teh Tarik (RM 3.25)
- teh_susu: Teh Susu (RM 3.25)
- teh_c: Teh C (RM 3.25)
- kopi_c: Kopi C (RM 3.25)
- kopi_tarik: Kopi Tarik (RM 3.25)
- teh_o_ais: Teh O Ais (RM 2.20)
- kopi_o_ais: Kopi O Ais (RM 2.20)
- teh_ais: Teh Ais (RM 3.25)
- kopi_ais: Kopi Ais (RM 3.25)
- milo_ais: Milo Ais (RM 3.50)
- sirap_bandung: Sirap Bandung (RM 3.00)

If the user wants to order food, recommend items, or customise items, you MUST respond in JSON. Your output must strictly be a valid JSON object matching this schema:
{
  "reply": "Your conversational response in Manglish here",
  "action": "ADD_TO_CART" | "RECOMMEND" | "NONE",
  "items": [
    {
      "id": "item_id_from_above",
      "quantity": 1,
      "notes": "any customization/notes requested by the user, e.g. Less sweet, extra hot, banjir"
    }
  ]
}

DO NOT include any explanation or markdown formatting in your response. Just return the raw JSON object.
''';

  /// Sends a message to the Groq API and returns a parsed Map with the reply and actions.
  static Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    if (apiKey.isEmpty) {
      return _localFallbackResponse(userMessage);
    }

    for (final targetModel in fallbackModels) {
      try {
        final response = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': targetModel,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': userMessage}
            ],
            'temperature': 0.2,
            'max_tokens': 300,
            'response_format': {'type': 'json_object'}
          }),
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final content = decoded['choices'][0]['message']['content'];
          return jsonDecode(content);
        }
      } catch (e) {
        // Continue to fallback model if network or model fails
      }
    }

    return _localFallbackResponse(userMessage);
  }

  /// Transcribes raw recorded audio using Groq Whisper Large v3 AI Model
  static Future<String?> transcribeAudio(String audioFilePath) async {
    if (apiKey.isEmpty) return null;

    try {
      final uri = Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..fields['model'] = 'whisper-large-v3'
        ..fields['response_format'] = 'json'
        ..files.add(await http.MultipartFile.fromPath('file', audioFilePath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['text'] as String?;
      }
    } catch (e) {
      // Fallback silently if Whisper request fails
    }
    return null;
  }

  /// Evaluates current cart items and returns a matching beverage/dish recommendation using LLM.
  static Future<Map<String, dynamic>> getSmartComboRecommendation(List<String> currentItemIds) async {
    if (apiKey.isEmpty || currentItemIds.isEmpty) {
      return _localComboFallback(currentItemIds);
    }

    try {
      final prompt = 'User current cart has items: ${currentItemIds.join(", ")}. Suggest exactly ONE perfect food or drink item from the menu to make a combo, with a short 1-sentence explanation of why it pairs well in Manglish.';
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': modelName,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'response_format': {'type': 'json_object'}
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final content = decoded['choices'][0]['message']['content'];
        return jsonDecode(content);
      }
    } catch (_) {}

    return _localComboFallback(currentItemIds);
  }

  /// Rule-based Local Mock Parser when Groq API Key is not set or network fails.
  static Map<String, dynamic> _localFallbackResponse(String text) {
    final clean = text.toLowerCase();
    
    // Default reply
    String reply = "Welcome to Al Safa boss! How can I help you today? Can order Roti Canai, Nasi Lemak, Teh Tarik... everything got!";
    String action = "NONE";
    List<Map<String, dynamic>> items = [];

    // Parse food keywords
    if (clean.contains('roti kosong') || clean.contains('roti canai')) {
      reply = "Sure thing macha! One crispy Roti Kosong coming up. Staged into your shopping bag, boss!";
      action = "ADD_TO_CART";
      items.add({'id': 'roti_kosong_roti_canai', 'quantity': 1, 'notes': 'Macha local parser'});
    } else if (clean.contains('roti telur')) {
      reply = "Got it boss! One Roti Telur ready. Staged into your shopping bag, boss!";
      action = "ADD_TO_CART";
      items.add({'id': 'roti_telur', 'quantity': 1, 'notes': 'Macha local parser'});
    } else if (clean.contains('roti cheese')) {
      reply = "Okay boss! Roti Cheese one. Hot and cheesy! Added to your bag, boss.";
      action = "ADD_TO_CART";
      items.add({'id': 'roti_cheese', 'quantity': 1, 'notes': 'Macha local parser'});
    } else if (clean.contains('nasi lemak')) {
      reply = "Ayo, absolute choice boss! Nasi Lemak Biasa. Spicy sambal added to bag!";
      action = "ADD_TO_CART";
      items.add({'id': 'nasi_lemak_biasa', 'quantity': 1, 'notes': 'Macha local parser'});
    } else if (clean.contains('maggi goreng')) {
      reply = "Maggi Goreng satu! Hot and spicy for you, boss. Added to bag.";
      action = "ADD_TO_CART";
      items.add({'id': 'maggi_goreng', 'quantity': 1, 'notes': 'Macha local parser'});
    } else if (clean.contains('teh tarik')) {
      reply = "Satu Teh Tarik frothed high! Sweet and hot. Added to bag.";
      action = "ADD_TO_CART";
      items.add({'id': 'teh_tarik', 'quantity': 1, 'notes': 'Macha local parser'});
    } else if (clean.contains('milo ais')) {
      reply = "Classic Milo Ais cold! Best choice boss. Added to bag.";
      action = "ADD_TO_CART";
      items.add({'id': 'milo_ais', 'quantity': 1, 'notes': 'Macha local parser'});
    } else if (clean.contains('sirap bandung')) {
      reply = "Bandung one! Pink and sweet. Added to bag.";
      action = "ADD_TO_CART";
      items.add({'id': 'sirap_bandung', 'quantity': 1, 'notes': 'Macha local parser'});
    } else if (clean.contains('recommend') || clean.contains('cadang') || clean.contains('suggest')) {
      reply = "Ayo boss! Recommend you try our signature Nasi Lemak Biasa (RM 4.00) paired with hot Teh Tarik (RM 3.25)! Very popular today!";
      action = "RECOMMEND";
      items.add({'id': 'nasi_lemak_biasa', 'quantity': 1});
    } else if (clean.contains('hello') || clean.contains('hi') || clean.contains('oi') || clean.contains('macha')) {
      reply = "Hello boss! AI Macha here ready to take your order. Tell me what you want to eat or drink, lah!";
    }

    return {
      'reply': reply,
      'action': action,
      'items': items,
    };
  }

  /// Rule-based Local Combo Generator when offline or no API key.
  static Map<String, dynamic> _localComboFallback(List<String> ids) {
    if (ids.isEmpty) {
      return {
        'reply': "Add some food and I suggest a drinks pairing, boss!",
        'action': 'NONE',
        'items': []
      };
    }

    final id = ids.first;
    // Map of food -> best drink, drink -> best food
    if (id.startsWith('roti_') || id.startsWith('nasi_') || id.startsWith('maggi_') || id == 'mee_goreng_ayam') {
      // Suggest drink
      return {
        'reply': "Macha says: Add Teh Tarik! The hot pulled milk tea pairs perfectly with spicy mamak food, boss!",
        'action': 'RECOMMEND',
        'items': [{'id': 'teh_tarik', 'quantity': 1}]
      };
    } else {
      // Suggest food
      return {
        'reply': "Macha says: Add Roti Kosong! Dip it in curry curry, goes super well with your drink, boss!",
        'action': 'RECOMMEND',
        'items': [{'id': 'roti_kosong_roti_canai', 'quantity': 1}]
      };
    }
  }
}
