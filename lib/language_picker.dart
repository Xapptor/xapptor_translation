import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_auth/get_api_key.dart';
import 'package:xapptor_translation/translate.dart';
import 'headers_api_request.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

// LanguagePicker widget.

class LanguagePicker extends StatefulWidget {
  const LanguagePicker({
    required this.translation_stream_list,
    required this.language_picker_items_text_color,
  });

  final List<TranslationStream> translation_stream_list;
  final Color language_picker_items_text_color;

  @override
  _LanguagePickerState createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<LanguagePicker> {
  String language_value = 'English';
  List<String> languages_names = [
    'English',
  ];
  List<String> languages_codes = [
    'en',
  ];
  String target_language = "en";
  late SharedPreferences prefs;

  // Get available languages.

  get_available_languages() async {
    prefs = await SharedPreferences.getInstance();

    if (prefs.getString("target_language") != null) {
      target_language = prefs.getString("target_language")!;
    } else {
      target_language = "en";
      prefs.setString("target_language", target_language);
    }

    languages_names.clear();
    languages_codes.clear();

    if (prefs.getStringList("languages_names") != null &&
        prefs.getStringList("languages_codes") != null) {
      //print("Returning languages from local");

      languages_names = prefs.getStringList("languages_names")!;
      languages_codes = prefs.getStringList("languages_codes")!;
    } else {
      String api_key =
          await get_api_key(name: "translation", organization: "gcp");

      String url =
          "https://translation.googleapis.com/language/translate/v2/languages?key=$api_key&target=en";

      Response response = await get(
        Uri.parse(url),
        headers: await headers_api_request(),
      );
      Map<String, dynamic> body = jsonDecode(response.body);
      List<dynamic> languages = body['data']['languages'];

      languages.forEach((language) {
        languages_names.add(language['name']);
        languages_codes.add(language['language']);
      });

      languages_names = languages_names.toSet().toList();

      //print("Returning languages from api");
      prefs.setStringList("languages_names", languages_names);
      prefs.setStringList("languages_codes", languages_codes);
    }
    language_value = languages_names[languages_codes.indexOf(target_language)];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    get_available_languages();
  }

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: DropdownButton<String>(
        isExpanded: true,
        value: language_value,
        iconEnabledColor: Colors.white,
        iconSize: 24,
        elevation: 0,
        underline: Container(
          height: 2,
          color: Colors.white,
        ),
        onChanged: (new_value) {
          language_value = new_value!;

          target_language =
              languages_codes[languages_names.indexOf(language_value)];

          prefs.setString('target_language', target_language);
          setState(() {});

          widget.translation_stream_list.forEach((translation_stream) {
            translation_stream.translate();
          });
        },
        selectedItemBuilder: (BuildContext context) {
          return languages_names.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            );
          }).toList();
        },
        items: languages_names.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: widget.language_picker_items_text_color,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
