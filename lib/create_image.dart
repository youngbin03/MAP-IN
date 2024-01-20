import 'package:http/http.dart' as http;
import 'package:google_mao/api_key.dart';
import 'dart:convert';

class createImage {
  static final url = Uri.parse("https://api.openai.com/v1/images/generations");

  static final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${OPENAI_API_KEY}"
  };

  static generateImage(String text) async {
    var res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({"prompt": text, "n": 1, "size": "256x256"}),
    );

    if (res.statusCode == 200) {
      var data = jsonDecode(res.body.toString());
      print(data);
      return data['data'][0]['url'] as String? ?? '';
    } else {
      print("Failed to fetch image");
      return '';
    }
  }
}
