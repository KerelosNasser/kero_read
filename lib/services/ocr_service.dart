import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ocr_result_model.dart';

class OcrService extends GetxService {
  final String _apiUrl = 'https://api.ocr.space/parse/image';
  
  Future<OcrResult?> performOcr(File file) async {
    int sizeInBytes = await file.length();
    if (sizeInBytes > 1024 * 1024) {
      throw Exception('File exceeds 1MB limit for OCR.');
    }

    String apiKey = dotenv.env['OCR_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception("OCR API key is missing. Please check your .env file.");
    }

    var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.headers['apikey'] = apiKey;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['isOverlayRequired'] = 'true';
    
    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);
      
      if (json['IsErroredOnProcessing'] == true) {
        throw Exception(json['ErrorMessage'] ?? 'OCR processing error');
      }

      String resultText = '';
      final List<OcrWord> words = [];
      var parsedResults = json['ParsedResults'];
      if (parsedResults != null) {
        for (var result in parsedResults) {
          resultText += '${result['ParsedText']?.toString() ?? ''}\n';
          
          final textOverlay = result['TextOverlay'];
          if (textOverlay != null && textOverlay['Lines'] != null) {
            for (var line in textOverlay['Lines']) {
              final lineWords = line['Words'];
              if (lineWords != null) {
                for (var wordJson in lineWords) {
                  final wordText = wordJson['WordText']?.toString() ?? '';
                  final left = (wordJson['Left'] as num?)?.toDouble() ?? 0.0;
                  final top = (wordJson['Top'] as num?)?.toDouble() ?? 0.0;
                  final width = (wordJson['Width'] as num?)?.toDouble() ?? 0.0;
                  final height = (wordJson['Height'] as num?)?.toDouble() ?? 0.0;
                  
                  words.add(OcrWord(
                    text: wordText,
                    left: left,
                    top: top,
                    width: width,
                    height: height,
                  ));
                }
              }
            }
          }
        }
      }
      return OcrResult(text: resultText, words: words);
    } else {
      throw Exception('OCR failed with status code ${response.statusCode}');
    }
  }
}
