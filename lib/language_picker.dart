import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_auth/authentication_needed_alert.dart';
import 'package:xapptor_auth/get_api_key.dart';
import 'package:xapptor_translation/translate.dart';
import 'headers_api_request.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'max_languages_per_day_alert.dart';

// LanguagePicker widget.

class LanguagePicker extends StatefulWidget {
  LanguagePicker({
    required this.translation_stream_list,
    required this.language_picker_items_text_color,
    this.max_languages_translated_per_day = 5,
  });

  final List<TranslationStream> translation_stream_list;
  final Color language_picker_items_text_color;
  int max_languages_translated_per_day;

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

  check_user_translation_limit(
    String new_language,
    BuildContext context,
  ) async {
    User? current_user = FirebaseAuth.instance.currentUser;
    if (current_user != null) {
      var user_snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(current_user.uid)
          .get();
      Map user_data = user_snap.data() as Map;
      Map<String, dynamic>? user_translation_limit =
          user_data["translation_limit"];

      if (user_translation_limit != null) {
        DateTime now = DateTime.now();
        DateTime translation_limit_date =
            (user_translation_limit["date"] as Timestamp).toDate();

        if (now.day != translation_limit_date.day) {
          add_new_language(
              new_language, user_snap, true, user_translation_limit);
        } else {
          if (user_translation_limit["languages"] != null) {
            List translation_limit_languages =
                user_translation_limit["languages"];

            if (translation_limit_languages.contains(new_language)) {
              change_language(new_language);
            } else {
              if (translation_limit_languages.length <
                  widget.max_languages_translated_per_day) {
                add_new_language(
                    new_language, user_snap, false, user_translation_limit);
              } else {
                max_languages_per_day_alert(context: context);
              }
            }
          } else {
            add_new_language(
                new_language, user_snap, false, user_translation_limit);
          }
        }
      } else {
        add_new_language(
            new_language, user_snap, false, user_translation_limit ?? {});
      }
    } else {
      authentication_needed_alert(context: context);
    }
  }

  add_new_language(
    String new_language,
    DocumentSnapshot user_snap,
    bool clean_languages,
    Map<String, dynamic> user_translation_limit,
  ) async {
    user_translation_limit["date"] = Timestamp.now();
    if (clean_languages || user_translation_limit["languages"] == null) {
      user_translation_limit["languages"] = [new_language];
    } else {
      (user_translation_limit["languages"] as List).add(new_language);
    }

    await user_snap.reference.update({
      "translation_limit": user_translation_limit,
    });
    change_language(new_language);
  }

  change_language(String new_language) {
    language_value = new_language;

    target_language = languages_codes[languages_names.indexOf(language_value)];

    prefs.setString('target_language', target_language);
    setState(() {});

    widget.translation_stream_list.forEach((translation_stream) {
      translation_stream.translate();
    });
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
        onChanged: (new_language) {
          if (new_language!.toLowerCase() == "english") {
            change_language(new_language);
          } else {
            check_user_translation_limit(new_language, context);
          }
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
