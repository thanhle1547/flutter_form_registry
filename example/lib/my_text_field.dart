import 'package:flutter/material.dart';

/// This is just a modification of
/// [the example](https://dartpad.dartlang.org/?id=120893372689ce66bbf89e5178848834)
/// from issue [#67283](https://github.com/flutter/flutter/issues/67283).
class MyTextField extends StatelessWidget {
  const MyTextField({
    required this.initial,
    required this.fieldKey,
    this.validator,
  });

  final String initial;
  final GlobalKey fieldKey;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      initialValue: initial,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
    );
  }
}
