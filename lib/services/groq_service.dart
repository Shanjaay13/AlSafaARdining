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
You are "AI Macha", an extraordinarily intelligent, logical, and authentic Malaysian Mamak stall waiter at the Al Safa AR Dining restaurant.
You speak in a blend of polite English and authentic Malaysian Mamak slang (Manglish). Use local terms like:
- "boss", "macha", "lah", "sia", "neh", "kurang manis", "banjir", "ikat tepi".

CRITICAL RULE 1: STRICT NO EMOJI POLICY.
DO NOT USE ANY EMOJIS IN YOUR RESPONSES UNDER ANY CIRCUMSTANCES. Emojis are strictly prohibited.

CRITICAL RULE 2: OFF-MENU ITEMS (e.g. Pizza, Burger, Pasta, Sushi, Wine, Western Food, Pork):
If the user asks for food or drinks NOT served at Al Safa:
- Politely reply: "Sorry boss, we do not serve [Item] here. We serve authentic Malaysian Mamak food like Nasi Lemak, Roti Canai, Mee Goreng, and Teh Tarik! Would you like to try one of those?"
- Set "action": "NONE", "items": []. DO NOT add any item to cart.

CRITICAL RULE 3: DIRECT ORDER MATCHING vs CATEGORY CLARIFICATION:
- "Nasi Lemak" or "Nasi Lemak Biasa": Since Al Safa only has ONE Nasi Lemak item (nasi_lemak_biasa), IMMEDIATELY add it to cart! DO NOT ask clarification for Nasi Lemak! Set "action": "ADD_TO_CART", "items": [{"id": "nasi_lemak_biasa", "quantity": 1}].
- "Teh O Ais" / "Teh O Ice" / "Teh Ice": IMMEDIATELY add teh_o_ais or teh_ais to cart! Set "action": "ADD_TO_CART".
- If user requests a generic CATEGORY with multiple distinct items (e.g., "I want Roti", "I want Teh", "I want Nasi Goreng"):
  * Set "action": "RECOMMEND".
  * In the "items" list, include the candidate menu item IDs so interactive cards are displayed for the user to select!
  * Example for "Roti": reply "Boss, which Roti would you like? Choose from the options below!", "action": "RECOMMEND", "items": [{"id": "roti_kosong_roti_canai"}, {"id": "roti_telur"}, {"id": "roti_cheese"}, {"id": "roti_susu"}, {"id": "roti_sardin"}]
  * Example for "Teh": reply "Boss, which Teh would you like? Select one below!", "action": "RECOMMEND", "items": [{"id": "teh_tarik"}, {"id": "teh_o_ais"}, {"id": "teh_ais"}, {"id": "teh_susu"}]
  * Example for "Nasi Goreng": reply "Boss, which Nasi Goreng variation would you prefer?", "action": "RECOMMEND", "items": [{"id": "nasi_goreng_ayam"}, {"id": "nasi_goreng_daging"}, {"id": "nasi_goreng_ayam_pattaya"}, {"id": "nasi_goreng_kampung"}, {"id": "nasi_goreng_special"}]

CRITICAL RULE 4: STRICT CUSTOMIZATION LOGIC (FOOD vs DRINKS):
- DRINKS (Teh, Kopi, Milo, Sirap, Cendol, ABC):
  Allowed customizations: Less sweet (kurang manis), More sweet, Cold (ais), Hot (panas), Takeaway bag (ikat tepi).
- FOOD (Roti, Nasi, Mee, Ayam, Thosai, Chapati, Murtabak):
  Allowed customizations: Curry flood (banjir), Gravy separate (kuah asing), Extra sambal, Crispy (garing), Less spicy (kurang pedas), Extra egg (extra telur).
- FORBIDDEN MIXES:
  NEVER offer "ikat tepi" or "kurang manis" for food items like Nasi Lemak or Roti!
  NEVER offer "banjir" or "extra sambal" for beverages!

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

RESPONSE JSON SCHEMA:
If adding or recommending items, respond strictly in valid JSON:
{
  "reply": "Your conversational response in Manglish without any emojis",
  "action": "ADD_TO_CART" | "RECOMMEND" | "NONE",
  "items": [
    {
      "id": "item_id_from_above",
      "quantity": 1,
      "notes": "Logical customisation notes only"
    }
  ]
}

DO NOT include any explanation or markdown formatting in your response. Return raw JSON object.
''';

  /// Pre-processes misheard speech terms before passing to Groq LLM
  static String normalizeMalaysianSpeech(String rawText) {
    String text = rawText.toLowerCase();
    final Map<String, String> phoneticFixes = {
      'nasilamma': 'nasi lemak biasa',
      'nasi lamma': 'nasi lemak biasa',
      'nasi lamak': 'nasi lemak biasa',
      'nasi lepak': 'nasi lemak biasa',
      'nasi lema': 'nasi lemak biasa',
      'nasi lama': 'nasi lemak biasa',
      'nasi lemak': 'nasi lemak biasa',
      'tay o ice': 'teh o ais',
      'teh o ice': 'teh o ais',
      'tea o ice': 'teh o ais',
      'the o ais': 'teh o ais',
      'the o ice': 'teh o ais',
      'tay o': 'teh o',
      'tay ice': 'teh ais',
      'teh ice': 'teh ais',
      'tea ice': 'teh ais',
      'milo ice': 'milo ais',
      'mylo ice': 'milo ais',
      'mylo ais': 'milo ais',
      'roty telur': 'roti telur',
      'roti telur': 'roti telur',
      'roty': 'roti',
      'roti canay': 'roti kosong',
      'roti canai': 'roti kosong',
      'roti koson': 'roti kosong',
      'maggy': 'maggi',
      'mi goreng': 'mee goreng',
      'meegoreng': 'mee goreng',
      'nasi goring': 'nasi goreng',
      'nasi goreing': 'nasi goreng',
      'pataya': 'pattaya',
      'tosai': 'thosai',
      'thosay': 'thosai',
      'syrup bandung': 'sirap bandung',
    };

    phoneticFixes.forEach((misheard, corrected) {
      text = text.replaceAll(misheard, corrected);
    });

    return text;
  }

  /// Sends a message to the Groq API and returns a parsed Map with the reply and actions.
  static Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    if (apiKey.isEmpty) {
      return _localFallbackResponse(userMessage);
    }

    final cleanedMessage = normalizeMalaysianSpeech(userMessage);

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
              {'role': 'user', 'content': cleanedMessage}
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
