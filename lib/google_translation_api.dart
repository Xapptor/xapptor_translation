import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_auth/get_api_key.dart';
import 'headers_api_request.dart';

class GoogleTranslationApi {
  // Call to Google Translation API.

  Future<String> translate(String original_text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString("target_language") == null)
      prefs.setString("target_language", "en");
    String target_language = prefs.getString("target_language") ?? "en";

    if (target_language == "en") {
      print("return translation from original text");
      return original_text;
    } else {
      if (prefs.getString(
              "translated_text_$original_text\_target_$target_language") !=
          null) {
        print("return translation from local storage");
        return prefs.getString(
            "translated_text_$original_text\_target_$target_language")!;
      } else {
        try {
          String api_key =
              await get_api_key(name: "translation", organization: "gcp");

          String url =
              'https://translation.googleapis.com/language/translate/v2?source=en&target=$target_language&key=$api_key&q=$original_text&format=text';

          Response response = await get(
            Uri.parse(url),
            headers: await headers_api_request(),
          );
          Map<String, dynamic> body = jsonDecode(response.body);
          //print("response ${response.body}");

          if (body["error"] == null) {
            var result = body['data']['translations'][0]['translatedText'];

            prefs.setString(
                "translated_text_$original_text\_target_$target_language",
                result);
            print("return translation from api");
            return result;
          } else {
            print("return translation from original text");
            return original_text;
          }
        } catch (error) {
          print(error);
          return original_text;
        }
      }
    }
  }
}
