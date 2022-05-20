import 'dart:convert';
import 'package:http/http.dart';
import 'package:xapptor_auth/gak.dart';
import 'package:xapptor_translation/headers_api_request.dart';

Future<Map<String, dynamic>> fetch_translation_from_endpoint({
  required String original_text,
  required String target_language,
  required String source_language,
}) async {
  String ak = await gak(
    n: "translation",
    o: "gcp",
  );

  String url =
      'https://translation.googleapis.com/language/translate/v2?source=$source_language&target=$target_language&key=$ak&q=$original_text&format=text';

  Response response = await get(
    Uri.parse(url),
    headers: await headers_api_request(),
  );
  Map<String, dynamic> reponse_body = jsonDecode(response.body);
  //print("response ${reponse_body}");
  return reponse_body;
}
