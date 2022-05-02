import 'package:cloud_firestore/cloud_firestore.dart';

save_translated_text_in_firestore({
  required String original_text,
  required String target_language,
  required String value,
}) async {
  QuerySnapshot translated_text_query = await FirebaseFirestore.instance
      .collection("translations")
      .where("original_text", isEqualTo: original_text)
      .get();

  if (translated_text_query.docs.length > 0) {
    QueryDocumentSnapshot first_doc = translated_text_query.docs.first;
    var first_doc_data = first_doc.data() as Map<String, dynamic>;
    var first_doc_data_translations =
        first_doc_data["translations"] as Map<String, dynamic>;

    first_doc_data_translations[target_language] = value;

    await FirebaseFirestore.instance
        .collection("translations")
        .doc(first_doc.id)
        .update({
      "last_time_used": Timestamp.now(),
      "translations": first_doc_data_translations,
    });
  } else {
    await FirebaseFirestore.instance.collection("translations").doc().set({
      "last_time_used": Timestamp.now(),
      "original_text": original_text,
      "translations": {
        target_language: value,
      },
    });
  }
}
