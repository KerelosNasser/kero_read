import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OcrService extends GetxService {
  final String _apiUrl = 'https://api.ocr.space/parse/image';
  
  Future<String?> performOcr(File file) async {
    int sizeInBytes = await file.length();
    if (sizeInBytes > 1024 * 1024) {
      Get.snackbar('Error', 'File exceeds 1MB limit for OCR.');
      return null;
    }

    try {
      String apiKey = dotenv.env['OCR_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception("OCR API key missing");

      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['apikey'] = apiKey;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        
        if (json['IsErroredOnProcessing'] == true) {
          Get.snackbar('OCR Error', json['ErrorMessage'].toString());
          return null;
        }

        String resultText = '';
        var parsedResults = json['ParsedResults'];
        if (parsedResults != null) {
          for (var result in parsedResults) {
            resultText += result['ParsedText'] + '\n';
          }
        }
        return resultText;
      } else {
        Get.snackbar('Error', 'OCR failed with status ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'OCR Error: $e');
    }
    return null;
  }
}
