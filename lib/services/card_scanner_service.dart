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

      // Search for card in Pokemon TCG API
      final cardData = await searchPokemonCard(cardName);

      return cardData;
    } catch (e) {
      print('Error processing card: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
