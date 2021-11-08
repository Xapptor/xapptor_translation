# **Xapptor Translation**
[![pub package](https://img.shields.io/pub/v/xapptor_translation?color=blue)](https://pub.dartlang.org/packages/xapptor_translation)
### Translation module to use Google translation services and save values ​​in local storage.

## **Let's get started**

### **1 - Depend on it**
##### Add it to your package's pubspec.yaml file
```yml
dependencies:
    xapptor_translation: ^0.0.2
```

### **2 - Install it**
##### Install packages from the command line
```sh
flutter pub get
```

### **3 - Learn it like a charm**
### * Set translation_stream and translation_stream_list variables
### * Set text_list with your texts
### * Set your update_text_list function
### * Init translation_stream and translation_stream_list variables
### * Set your TopBar inside your Scaffold (you can include a LanguagePicker)
### * Call the texts translated, for example, text_list[0]
```dart
class ExampleWidget extends StatefulWidget {
  @override
  _ExampleWidgetState createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
    late TranslationStream translation_stream;
    List<TranslationStream> translation_stream_list = [];

    List<String> text_list = [
        "Example text for traduction 1",
        "Example text for traduction 2",
        "Example text for traduction 3",
    ];

    update_text_list({
        required int index,
        required String new_text,
        required int list_index,
    }) {
        text_list[index] = new_text;
        setState(() {});
    }

    @override
    void initState() {
        translation_stream = TranslationStream(
            text_list: text_list,
            update_text_list_function: update_text_list,
            list_index: 0,
            active_translation: true,
        );
        translation_stream_list = [translation_stream];

        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: TopBar(
                background_color: Colors.blue,
                has_back_button: true,
                actions: <Widget>[
                    Container(
                    margin: EdgeInsets.only(right: 20),
                    width: 150,
                    child: LanguagePicker(
                            translation_stream_list: translation_stream_list,
                            language_picker_items_text_color: Colors.cyan,
                        ),
                    ),
                ],
                custom_leading: null,
                logo_path: "assets/images/logo.png",
            ),
            body: Center(
                child: Text(
                    text_list[0],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 40,
                    ),
                ),
            ),
        );
    }
}
```

### **4 - Check Abeinstitute Repo for more examples**
[Abeinstitute Repo](https://github.com/Xapptor/abeinstitute)

[Abeinstitute](https://www.abeinstitute.com)