import 'package:example/my_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_registry/flutter_form_registry.dart';

import 'custom_text_form_field.dart';

/// A modification of
/// [the example (looking up a Form's invalid field)](https://dartpad.dartlang.org/?id=120893372689ce66bbf89e5178848834)
/// from issue [#67283](https://github.com/flutter/flutter/issues/67283).
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo Scroll To Invalid FormField',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage();

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
    final appBarActions = <Widget>[
      Tooltip(
        message: 'Validate form',
        child: InkResponse(
          onTap: () {
            _formKey.currentState?.validate();

            final firstInvalidField = _registerdKey.currentState?.firstErrorField;

            print(firstInvalidField?.formFieldState.value);
            print(firstInvalidField?.formFieldState.errorText);
          },
          radius: 24,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.check,
            ),
          ),
        ),
      ),
      Tooltip(
        message: 'Reset form',
        child: InkResponse(
          onTap: () {
            _formKey.currentState?.reset();
          },
          radius: 24,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.restart_alt,
            ),
          ),
        ),
      ),
    ];

    final children = <Widget>[
      // CustomTextFormField is a FormField
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
      // Example using FormFieldRegistrant
      //
      for (int i = 16; i < 20; i++)
        FormFieldRegistrant(
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
      FormFieldRegistrant(
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
      for (int i = 21; i < 25; i++)
        FormFieldRegistrant(
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
      //
      // Example using FormFieldRegistrant with a list of keys
      //
      FormFieldRegistrant(
        registrarId: 'No. 25',
        formFieldKey: fieldKeys[25 - 21],
        validator: integerTextFieldValidator,
        builder: (_, String? Function(String?) validator) {
          // The widget returned by builder can have a FormField within its widget tree.
          return Container(
            height: 100,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: MyTextField(
              initial: 'twenty-five',
              fieldKey: fieldKeys[25 - 21],
              validator: validator,
            ),
          );
        },
      ),
      for (int i = 26; i < 40; i++)
        FormFieldRegistrant(
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
      //
      // Example using FormFieldRegistrantProxy
      //
      FormFieldRegistrantProxy(
        registrarId: 'No. 40',
        // The child widget must be a FormField.
        child: CustomTextFormField(
          registrarId: "No. 40",
          initialValue: 'forty',
          validator: integerTextFieldValidator,
        ),
      ),
      for (int i = 41; i < 46; i++)
        FormFieldRegistrantProxy(
          registrarId: "No. $i",
          child: CustomTextFormField(
            initialValue: i.toString(),
            validator: integerTextFieldValidator,
          ),
        ),
    ];

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Scroll to invalid field example',
          ),
          actions: appBarActions,
        ),
        body: FormRegistryWidget(
          key: _registerdKey,
          autoScrollToFirstInvalid: true,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: children,
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final firstInvalidField = _registerdKey.currentState?.firstErrorField;
      
            print(firstInvalidField?.formFieldState.value);
            print(firstInvalidField?.formFieldState.errorText);
      
            firstInvalidField?.scrollToIntoView();
          },
          tooltip: 'Scroll to invalid',
          child: const Icon(Icons.search),
        ),
      ),
    );
  }
}
