import 'package:shared_preferences/shared_preferences.dart';

String? get_local_translated_text({
  required String original_text,
  required String target_language,
  required SharedPreferences prefs,
}) {
  return prefs
      .getString("translated_text_$original_text\_target_$target_language");
}
