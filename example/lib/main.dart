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
                    for (int i = 0; i < 25; i++)
                      CustomTextFormField(
                        fieldName: "No. $i",
                        initialValue: "$i",
                        validator: integerTextFieldValidator,
                      ),
                    CustomTextFormField(
                      fieldName: "No. 25",
                      initialValue: 'thirty',
                      validator: integerTextFieldValidator,
                    ),
                    //
                    for (int i = 26; i < 30; i++)
                      FormFieldRegisteredWidget(
                        fieldName: "No. $i",
                        validator: integerTextFieldValidator,
                        buidler: (
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
                      fieldName: 'No. 30',
                      validator: integerTextFieldValidator,
                      buidler: (
                        GlobalKey<FormFieldState<String>> formFieldKey,
                        String? Function(String?) validator,
                      ) {
                        return MyTextField(
                          initial: '30',
                          fieldKey: formFieldKey,
                          validator: validator,
                        );
                      },
                    ),
                    for (int i = 31; i < 60; i++)
                      FormFieldRegisteredWidget(
                        fieldName: 'No. $i',
                        validator: integerTextFieldValidator,
                        buidler: (
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
            print(_registerdKey.currentState!.firstError?.errorText);
          }
        },
        tooltip: 'Scroll to invalid',
        child: const Icon(Icons.search),
      ),
    );
  }
}
