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

    TranslationValueType current_translation_value_type =
        TranslationValueType.Original;
    String current_text = "";

    if (target_language == "en") {
      current_text = original_text;
    } else {
      if (prefs.getString(
              "translated_text_$original_text\_target_$target_language") !=
          null) {
        current_translation_value_type = TranslationValueType.Local;

        current_text = prefs.getString(
            "translated_text_$original_text\_target_$target_language")!;
      } else {
        try {
          Map<String, dynamic> response = await fetch_translation_from_endpoint(
            original_text,
            target_language,
          );

          if (response["error"] == null) {
            var result = response['data']['translations'][0]['translatedText'];

            prefs.setString(
                "translated_text_$original_text\_target_$target_language",
                result);

            //print("Returning translation from ${TranslationValueType.Api.toShortString()}");
            return result;
          } else {
            current_translation_value_type = TranslationValueType.Original;
            current_text = original_text;
          }
        } catch (error) {
          print(error);
          current_text = original_text;
        }
      }
    }

    //print("Returning translation from ${current_translation_value_type.toShortString()}");
    return current_text;
  }

  Future<Map<String, dynamic>> fetch_translation_from_endpoint(
    String original_text,
    String target_language,
  ) async {
    String api_key = await get_api_key(
      name: "translation",
      organization: "gcp",
    );

    String url =
        'https://translation.googleapis.com/language/translate/v2?source=en&target=$target_language&key=$api_key&q=$original_text&format=text';

    Response response = await get(
      Uri.parse(url),
      headers: await headers_api_request(),
    );
    Map<String, dynamic> reponse_body = jsonDecode(response.body);
    //print("response ${reponse_body}");
    return reponse_body;
  }
}

enum TranslationValueType {
  Api,
  Original,
  Local,
}

extension ParseToString on TranslationValueType {
  String toShortString() {
    return this.toString().toLowerCase().split('.').last;
  }
}
