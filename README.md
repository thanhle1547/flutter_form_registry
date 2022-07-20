## flutter_form_registry

![flutter_form_registry version](https://img.shields.io/badge/flutter_form_registry-v0.0.1-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

A workaround to track some FormFields in the tree.

-----

Do you want functionality like scrolling to the first invalid form after being validated?

You don't want to maintain a list of keys for your form fields by yourself?

Because we cannot access registered FormFieldState in the Form widget by the GlobalKey<FormState> to determine which FormFieldState has validated error. So... To make fields property of FieldState publicity, please give a 👍 to the issue [#67283](https://github.com/flutter/flutter/issues/67283).

In while, may be this workaround will help you. Beside [flutter_form_builder](https://pub.dev/packages/flutter_form_builder), [ready_form](https://pub.dev/packages/ready_form).

## 🔍 Features

* Tracking registered widget.

* Can auto-scroll to the first Form's invalid field.

* Each registered FormField widget contains its key, error text and method to scroll its into view and check is it fully visible.

## 💽 Installation

```
  flutter_form_registry:
      git:
        url: https://github.com/thanhle1547/flutter_form_registry
```

## 📺 Usage

1. Wrap the widget that contains all the form fields by `FormRegistryWidget`.

To access all the registered form fields, give the `FormRegistryWidget` a `GlobalKey<FormRegistryWidgetState>`, or calling `FormRegistryWidgetState.of` static method.

These parameters `defaultAlignment`, `defaultDuration`, `defaultCurve`, `defaultAlignmentPolicy` let you setup the default behavior when scrolling to the error fields.

2. There are two cases about your form field widget that you need to know before continuing setup:

    1. Your customized widget extends FormField.
    2. Otherwise, you are not.

With the first one, you need to:

* Use the `FormFieldRegisteredWidgetMixin` for the class that extends `FormField` and override `fieldName`. This `fieldName` is nullable, so you only need to pass to it the value only when you need to validate.

```dart
class CustomTextFormField extends FormField<String>
    with FormFieldRegisteredWidgetMixin {
  CustomTextFormField({
    Key? key,
    this.fieldName,

    // some code ...

  })

  // some code ...

  @override
  final String? fieldName;
}
```

* Use the `FormFieldStateRegisteredWidgetMixin` for the class that extends `FormFieldState`.

```dart
class _CustomTextFormFieldState extends FormFieldState<String>
    with FormFieldStateRegisteredWidgetMixin {
  // some code ...
}
```

You can also override the default behavior that has been set up in `FormRegistryWidget` when scrolling to your customized widget.

```dart
class _TextFormFieldState extends FormFieldState<String>
    with FormFieldStateRegisteredWidgetMixin {
  @override
  double get alignment => yourAlignment;

  @override
  Duration get duration => yourDuration;

  @override
  Curve get curve => yourCurve;

  @override
  ScrollPositionAlignmentPolicy get alignmentPolicy => yourAlignmentPolicy;

  // some code ...
}
```

With the second one, you need to:

* Wrap the widget that contains the form field by `FormFieldRegisteredWidget` and pass down values to these parameters: `fieldName`, `validator`, and `buidler`. The `buidler` function takes `GlobalKey<FormFieldState<T>>` and `FormFieldValidator<T>` as arguments which you have to pass to the widget that is a form field.

An example with package [`date_field`](https://pub.dev/packages/date_field).

```dart
FormFieldRegisteredWidget(
  fieldName: 'select date',
  validator: (DateTime? value) {
    if (value == null) {
      return "Empty!";
    }

    if (value.isBefore(DateTime.now())) {
      return 'The date must be before today';
    }

    return null;
  },
  buidler: (
    GlobalKey<FormFieldState<DateTime>> formFieldKey,
    String? Function(DateTime?) validator,
  ) {
    return DateTimeFormField(
      key: formFieldKey,
      validator: validator,
      onDateSelected: (value) {
        setState(() {
          selectedDate = value;
        });
      },
      mode: DateTimeFieldPickerMode.date,
      initialValue: selectedDate,
    );
  },
),
```

If your actual form field has `restorationId`, you should be passing it to the `FormFieldRegisteredWidget` as well.

You can also override the default behavior that has been set up in `FormRegistryWidget` when scrolling to this widget.
