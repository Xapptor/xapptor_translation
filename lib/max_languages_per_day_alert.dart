import 'package:flutter/material.dart';

max_languages_per_day_alert({
  required BuildContext context,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Max languages translated per day!"),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("Accept"),
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
