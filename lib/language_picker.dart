// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_api_key/gak.dart';
import 'package:xapptor_logic/date/check_limit_per_date.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_translation/translation_stream.dart';
import 'headers_api_request.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

// LanguagePicker widget.

class LanguagePicker extends StatefulWidget {
  LanguagePicker({
    super.key,
    required this.translation_stream_list,
    required this.language_picker_items_text_color,
    this.selected_text_color,
    this.max_languages_translated_per_day = 5,
    this.source_language_index = 0,
    required this.update_source_language,
    this.enable_initial_translation = true,
    this.show_icon = false,
    this.icon_color,
    this.icon,
  });

  final List<TranslationStream> translation_stream_list;
  final Color language_picker_items_text_color;
  final Color? selected_text_color;
  int max_languages_translated_per_day;
  int source_language_index;
  final Function({required int new_source_language_index}) update_source_language;
  final bool enable_initial_translation;

  /// Whether to show a language icon at the beginning of the picker.
  final bool show_icon;

  /// Color for the language icon. Defaults to selected_text_color if not specified.
  final Color? icon_color;

  /// Custom icon to display. Defaults to FontAwesome language icon.
  final IconData? icon;

  @override
  State<LanguagePicker> createState() => _LanguagePickerState();
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
            .translation_stream_list[0].translation_text_list_array.list[widget.source_language_index].source_language;

    //debugPrint("target_language: " + target_language);

    languages_names.clear();
    languages_codes.clear();

    if (prefs.getStringList("languages_names") != null && prefs.getStringList("languages_codes") != null) {
      //debugPrint("Returning languages from local");

      languages_names = prefs.getStringList("languages_names")!;
      languages_codes = prefs.getStringList("languages_codes")!;
    } else {
      String ak = await gak(n: "translation", o: "gcp");

      String url = "https://translation.googleapis.com/language/translate/v2/languages?key=$ak&target=en";

      Response response = await get(
        Uri.parse(url),
        headers: await headers_api_request(),
      );
      Map<String, dynamic> body = jsonDecode(response.body);
      List<dynamic> languages = body['data']['languages'];

      for (var language in languages) {
        languages_names.add(language['name']);
        languages_codes.add(language['language']);
      }

      languages_names = languages_names.toSet().toList();

      //debugPrint("Returning languages from api");
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

    TranslationTextList? target_language_is_source_language;

    for (var element in widget.translation_stream_list[0].translation_text_list_array.list) {
      if (target_language == element.source_language) {
        target_language_is_source_language = element;
      }
    }

    int new_source_language_index = 0;

    //debugPrint("target_language_is_source_language: " + target_language_is_source_language.first.source_language);

    if (target_language_is_source_language != null) {
      new_source_language_index = widget.translation_stream_list[0].translation_text_list_array.list
          .indexOf(target_language_is_source_language);

      change_language(new_source_language_index);
    } else {
      check_limit_per_date(
        new_value: new_language,
        context: context,
        reached_limit_alert_title: "Max languages translated per day!",
        check_limit_per_date_callback: () {
          change_language(new_source_language_index);
        },
        cache_lifetime_in_seconds: Duration.secondsPerDay * widget.max_languages_translated_per_day,
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
    //debugPrint("set target_language: " + target_language);

    widget.update_source_language(new_source_language_index: new_source_language_index);

    FirebaseAuth.instance.setLanguageCode(target_language);

    setState(() {});

    int total_length = 0;

    for (var translation_stream in widget.translation_stream_list) {
      total_length += translation_stream.translation_text_list_array.list.first.text_list.length;
    }

    for (var translation_stream in widget.translation_stream_list) {
      translation_stream.translate(
        source_language_index: new_source_language_index,
        length: total_length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected_color = widget.selected_text_color ?? Colors.white;
    final icon_color = widget.icon_color ?? selected_color;
    final icon_data = widget.icon ?? FontAwesomeIcons.language;

    final dropdown = DropdownButton<String>(
      isExpanded: true,
      value: language_value,
      iconEnabledColor: selected_color,
      iconSize: 24,
      elevation: 0,
      underline: Container(
        height: 2,
        color: selected_color,
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
                color: selected_color,
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
    );

    if (widget.show_icon) {
      return PointerInterceptor(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Icon(
                icon_data,
                color: icon_color,
                size: 18,
              ),
            ),
            Expanded(child: dropdown),
          ],
        ),
      );
    }

    return PointerInterceptor(child: dropdown);
  }
}
