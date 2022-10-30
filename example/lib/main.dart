import 'package:example/my_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_registry/flutter_form_registry.dart';

import 'custom_text_form_field.dart';

/// A modification of
/// [the example (looking up a Form's invalid field)](https://dartpad.dartlang.org/?id=120893372689ce66bbf89e5178848834)
/// from issue [#67283](https://github.com/flutter/flutter/issues/67283).
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo Scroll To Invalid FormField',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Scroll to invalid field'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final GlobalKey<FormRegistryWidgetState> _registerdKey = GlobalKey();

  final List<GlobalKey<FormFieldState<String>>> fieldKeys = [
    for (int i = 21; i < 40; i++) GlobalKey(),
  ];

  String? integerTextFieldValidator(String? value) {
    if (value == null) {
      return 'Null!';
    }
    try {
      int.parse(value);
    } catch (error) {
      return 'Not an integer!';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FormRegistryWidget(
          key: _registerdKey,
          autoScrollToFirstInvalid: true,
          child: Center(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < 15; i++)
                      CustomTextFormField(
                        registrarId: "No. $i",
                        initialValue: "$i",
                        validator: integerTextFieldValidator,
                      ),
                    CustomTextFormField(
                      registrarId: "No. 15",
                      initialValue: 'fifteen',
                      validator: integerTextFieldValidator,
                    ),
                    //
                    for (int i = 16; i < 20; i++)
                      FormFieldRegisteredWidget(
                        registrarId: "No. $i",
                        validator: integerTextFieldValidator,
                        builder: (
                          GlobalKey<FormFieldState<String>> formFieldKey,
                          String? Function(String?) validator,
                        ) {
                          return MyTextField(
                            initial: "$i",
                            fieldKey: formFieldKey,
                            validator: validator,
                          );
                        },
                      ),
                    FormFieldRegisteredWidget(
                      registrarId: 'No. 20',
                      validator: integerTextFieldValidator,
                      builder: (
                        GlobalKey<FormFieldState<String>> formFieldKey,
                        String? Function(String?) validator,
                      ) {
                        return MyTextField(
                          initial: 'twenty',
                          fieldKey: formFieldKey,
                          validator: validator,
                        );
                      },
                    ),
                    //
                    for (int i = 21; i < 25; i++)
                      FormFieldRegisteredWidget(
                        registrarId: 'No. $i',
                        formFieldKey: fieldKeys[i - 21],
                        validator: integerTextFieldValidator,
                        builder: (_, String? Function(String?) validator) {
                          return MyTextField(
                            initial: "$i",
                            fieldKey: fieldKeys[i - 21],
                            validator: validator,
                          );
                        },
                      ),
                    FormFieldRegisteredWidget(
                      registrarId: 'No. 25',
                      formFieldKey: fieldKeys[25 - 21],
                      validator: integerTextFieldValidator,
                      builder: (_, String? Function(String?) validator) {
                        return MyTextField(
                          initial: 'twenty-five',
                          fieldKey: fieldKeys[25 - 21],
                          validator: validator,
                        );
                      },
                    ),
                    //
                    for (int i = 26; i < 40; i++)
                      FormFieldRegisteredWidget(
                        registrarId: 'No. $i',
                        formFieldKey: fieldKeys[i - 21],
                        validator: integerTextFieldValidator,
                        builder: (_, String? Function(String?) validator) {
                          return MyTextField(
                            initial: "$i",
                            fieldKey: fieldKeys[i - 21],
                            validator: validator,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _formKey.currentState?.validate();

          if (kDebugMode) {
            print(_registerdKey.currentState!.firstInvalid?.errorText);
          }
        },
        tooltip: 'Scroll to invalid',
        child: const Icon(Icons.search),
      ),
    );
  }
}
