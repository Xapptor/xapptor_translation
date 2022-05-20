import 'package:shared_preferences/shared_preferences.dart';

set_local_translated_text({
  required String original_text,
  required String target_language,
  required String value,
  required SharedPreferences prefs,
}) {
  prefs.setString(
      "translated_text_$original_text\_target_$target_language", value);
}
