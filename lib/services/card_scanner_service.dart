import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CardScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from image using ML Kit
  Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    return recognizedText.text;
  }

  /// Search for Pokemon card using Pokemon TCG API
  Future<Map<String, dynamic>?> searchPokemonCard(String cardName) async {
    try {
      // Pokemon TCG API endpoint
      final url = Uri.parse(
          'https://api.pokemontcg.io/v2/cards?q=name:"$cardName"&pageSize=1');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          return data['data'][0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Error searching for card: $e');
    }
    return null;
  }

  /// Clean and extract likely card name from OCR text
  String extractCardName(String ocrText) {
    // Split text into lines
    final lines = ocrText.split('\n');

    // Pokemon card names are typically at the top
    // Remove common words and numbers
    for (var line in lines) {
      line = line.trim();
      // Skip empty lines and lines with only numbers
      if (line.isEmpty || RegExp(r'^\d+$').hasMatch(line)) continue;

      // Skip common card text
      if (line.toLowerCase().contains('hp') ||
          line.toLowerCase().contains('pokemon') ||
          line.toLowerCase().contains('lv.')) {
        continue;
      }

      // First substantial line is likely the card name
      if (line.length > 2) {
        return line;
      }
    }

    return ocrText.split('\n').first.trim();
  }

  /// Process scanned card image
  Future<Map<String, dynamic>?> processCardImage(String imagePath) async {
    try {
      // Extract text from image
      final ocrText = await extractTextFromImage(imagePath);
      print('OCR Text: $ocrText');

      // Extract card name
      final cardName = extractCardName(ocrText);
      print('Extracted card name: $cardName');

      // Parse additional likely card parameters from OCR
      final lines = ocrText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      String? hp;
      String? rarity;
      String? number;

      final hpReg = RegExp(r"(\\d{1,3})\\s*HP", caseSensitive: false);
      final hpReg2 = RegExp(r"HP\\s*(\\d{1,3})", caseSensitive: false);
      final rarityReg = RegExp(r"\\b(Common|Uncommon|Rare|Holo|Ultra Rare|Secret Rare|Promo|Rare Holo|Holofoil)\\b",
          caseSensitive: false);
      final numberReg = RegExp(r"\\b(\\d{1,3}/\\d{1,3})\\b");

      for (var line in lines) {
        if (hp == null) {
          final m = hpReg.firstMatch(line) ?? hpReg2.firstMatch(line);
          if (m != null && m.groupCount >= 1) {
            hp = m.group(1);
          }
        }

        if (rarity == null) {
          final m = rarityReg.firstMatch(line);
          if (m != null) {
            rarity = m.group(1);
          }
        }

        if (number == null) {
          final m = numberReg.firstMatch(line);
          if (m != null) {
            number = m.group(1);
          }
        }

        if (hp != null && rarity != null && number != null) break;
      }

      final result = <String, dynamic>{
        'name': cardName,
        'hp': hp,
        'rarity': rarity,
        'number': number,
        'rawText': ocrText,
      };

      return result;
    } catch (e) {
      print('Error processing card: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
