import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_auth/gak.dart';
import 'package:xapptor_logic/check_limit_per_date.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_translation/translation_stream.dart';
import 'headers_api_request.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

// LanguagePicker widget.

class LanguagePicker extends StatefulWidget {
  LanguagePicker({
    required this.translation_stream_list,
    required this.language_picker_items_text_color,
    this.max_languages_translated_per_day = 5,
    this.source_language_index = 0,
    required this.update_source_language,
    this.enable_initial_translation = true,
  });

  final List<TranslationStream> translation_stream_list;
  final Color language_picker_items_text_color;
  int max_languages_translated_per_day;
  int source_language_index;
  final Function({required int new_source_language_index})
      update_source_language;
  final bool enable_initial_translation;

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

  @override
  void initState() {
    super.initState();
    get_available_languages();
  }

  // Get available languages.

  get_available_languages() async {
    prefs = await SharedPreferences.getInstance();

    target_language = prefs.getString("target_language") ??
        widget
            .translation_stream_list[0]
            .translation_text_list_array
            .translation_text_list_array[widget.source_language_index]
            .source_language;

    //print("target_language: " + target_language);

    languages_names.clear();
    languages_codes.clear();

    if (prefs.getStringList("languages_names") != null &&
        prefs.getStringList("languages_codes") != null) {
      //print("Returning languages from local");

      languages_names = prefs.getStringList("languages_names")!;
      languages_codes = prefs.getStringList("languages_codes")!;
    } else {
      String ak = await gak(n: "translation", o: "gcp");

      String url =
          "https://translation.googleapis.com/language/translate/v2/languages?key=$ak&target=en";

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

    if (widget.enable_initial_translation) {
      check_translation_availability(language_value);
    }
  }

  check_translation_availability(String new_language) {
    language_value = new_language;

    target_language = languages_codes[languages_names.indexOf(language_value)];

    List<TranslationTextList> target_language_is_source_language = widget
        .translation_stream_list[0]
        .translation_text_list_array
        .translation_text_list_array
        .where((element) => target_language == element.source_language)
        .toList();

    int new_source_language_index = 0;

    //print("target_language_is_source_language: " + target_language_is_source_language.first.source_language);

    if (target_language_is_source_language.length > 0) {
      new_source_language_index = widget.translation_stream_list[0]
          .translation_text_list_array.translation_text_list_array
          .indexOf(target_language_is_source_language.first);

      change_language(new_source_language_index);
    } else {
      check_limit_per_date(
        new_value: new_language,
        context: context,
        reached_limit_alert_title: "Max languages translated per day!",
        check_limit_per_date_callback: () {
          change_language(new_source_language_index);
        },
        cache_lifetime_in_seconds:
            Duration.secondsPerDay * widget.max_languages_translated_per_day,
        limit: widget.max_languages_translated_per_day,
        limit_field_name: "translation_limit",
        array_field_name: "languages",
        reach_limit: ReachLimit.by_day,
        save_same_value_multiple_times: false,
      );
    }
  }

  change_language(int new_source_language_index) {
    prefs.setString("target_language", target_language);
    //print("set target_language: " + target_language);

    widget.update_source_language(
        new_source_language_index: new_source_language_index);

    FirebaseAuth.instance.setLanguageCode(target_language);

    setState(() {});

    int total_length = 0;

    widget.translation_stream_list.forEach((translation_stream) {
      total_length += translation_stream.translation_text_list_array
          .translation_text_list_array.first.text_list.length;
    });

    widget.translation_stream_list.forEach((translation_stream) {
      translation_stream.translate(
        source_language_index: new_source_language_index,
        length: total_length,
      );
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
          check_translation_availability(new_language!);
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
