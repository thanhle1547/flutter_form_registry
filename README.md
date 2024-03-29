## flutter_form_registry

[![Pub Version](https://img.shields.io/pub/v/flutter_form_registry.svg)](https://pub.dev/packages/flutter_form_registry)
![Pub Points](https://img.shields.io/pub/points/flutter_form_registry.svg)
![flutter_form_registry version](https://img.shields.io/badge/flutter_form_registry-v0.6.2-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

A workaround to track some `FormField`s in the tree. Support checking `FormField` is fully visible and scrolling into the view.

![Hashnode](https://cdn.hashnode.com/res/hashnode/image/upload/v1658517803882/gtdYDSGSi.gif?w=1600&h=840&fit=crop&crop=entropy&auto=format,compress&gif-q=60&format=webm)

<p align="center">
  Read my article on
</p>

<p align="center">
  <a href="https://thanhle.hashnode.dev/flutter-scrolling-to-the-first-invalid-form-field">
    <img src="https://img.shields.io/badge/Hashnode-2962FF?style=for-the-badge&logo=hashnode&logoColor=white" alt="Hashnode"></img>
  </a>
</p>


-----

Do you want functionality like scrolling to the first invalid form?

You don't want to maintain a list of keys for your form fields by yourself?

Because we cannot access registered `FormFieldState` in the Form widget by the `GlobalKey<FormState>` to determine which `FormFieldState` has validated error. So... To make fields property of `FieldState` publicity, please give a 👍 to the issue [#67283](https://github.com/flutter/flutter/issues/67283).

In while, maybe this workaround will help you. Beside [flutter_form_builder](https://pub.dev/packages/flutter_form_builder), [ready_form](https://pub.dev/packages/ready_form).

## 🔍 Features

* Tracking registered widget.

* Can auto-scroll to the first Form's invalid field.

* Each registered FormField widget contains its key, error text and method to scroll its into view and check is it fully visible.

## 📦 Dependency

* flutter sdk >=3.0.0

* dart sdk >=2.17.0 <3.0.0

For the older flutter sdk:

* [>=2.5.0 <3.0.0](https://github.com/thanhle1547/flutter_form_registry/tree/flutter_below_3.3.0_above_%3D_2.5.0)

* [<2.5.0](https://github.com/thanhle1547/flutter_form_registry/tree/flutter_below_2.5.0)

## 💽 Installation

```
dependencies:

  flutter_form_registry: ^0.6.2
```

## 📺 Usage

1. Wrap the widget that contains all the form fields by `FormRegistryWidget`.

To access all the registered form fields, give the `FormRegistryWidget` a `GlobalKey<FormRegistryWidgetState>`, or calling `FormRegistryWidgetState.of` static method.

These parameters `defaultAlignment`, `defaultDuration`, `defaultCurve`, `defaultAlignmentPolicy` let you setup the default behavior when scrolling to the error fields.

2. There are two cases regarding your form field widget that you need to know before continuing setup:

    1. You customed the widget that extends FormField.
    2. You are using widgets from the framework or customized widgets from packages.

With the first one, you need to:

* Use the `FormFieldRegistrantMixin` for the class that extends `FormField` and override `registryId` and `lookupPriority`. This `registryId` used to identify other `FormField`s. It is nullable, so you only need to pass the value only when you need to validate. When `FormField` visibility changes (e.g. from invisible to visible), it will be registered as the last one in the set. So when lookup for the first invalid field, which might be this one, but you got another. If you consider this an issue, all you need to do is to set the `lookupPriority` to arrange this `FormField`.

```dart
class CustomTextFormField extends FormField<String>
    with FormFieldRegistrantMixin {
  CustomTextFormField({
    Key? key,
    this.registryId,

    // some code ...

  })

  // some code ...

  @override
  final String? registryId;
}
```

* Use the `FormFieldStateRegistrantMixin` for the class that extends `FormFieldState`.

```dart
class _CustomTextFormFieldState extends FormFieldState<String>
    with FormFieldStateRegistrantMixin {
  // some code ...
}
```

You can also override the default behavior that has been set up in `FormRegistryWidget` when scrolling to your customized widget.

```dart
class _TextFormFieldState extends FormFieldState<String>
    with FormFieldStateRegistrantMixin {
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

* Wrap the widget that contains the form field by `FormFieldRegistrant` and pass down values to these parameters: `registryId`, `validator`, and `builder`. The `builder` function takes `GlobalKey<FormFieldState<T>>` and `FormFieldValidator<T>` as arguments which you have to pass to the widget that is a form field.

An example with package [`date_field`](https://pub.dev/packages/date_field).

```dart
FormFieldRegistrant(
  registryId: 'select date',
  validator: (DateTime? value) {
    if (value == null) {
      return "Empty!";
    }

    if (value.isBefore(DateTime.now())) {
      return 'The date must be before today';
    }

    return null;
  },
  builder: (
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

If your actual form field has `restorationId`, you should be passing it to the `FormFieldRegistrant` as well.

You can also override the default behavior that has been set up in `FormRegistryWidget` when scrolling to this widget.

In case, you have an existing form field key that cannot be removed because you (still) need to access its form field state, ..., pass that key to the `formFieldKey` parameter. 