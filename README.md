# flutter_form_registry

[![Version](https://img.shields.io/pub/v/flutter_form_registry?include_prereleases)](https://pub.dartlang.org/packages/flutter_form_registry)
[![Pub Points](https://img.shields.io/pub/points/flutter_form_registry)](https://pub.dev/packages/flutter_form_registry/score)
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

## Are you looking for a way to...

* Scroll to the first invalid form field after `FormState.validate()` is called, without having to manually maintain a list of keys for your form fields?

* Get the validity of all form fields without having to call `FormState.validate()`?

* Get dynamic `FormFieldState` instances created from the API without manually managing a `GlobalKey` for each one?

## 🔍 Core Features

* Tracking all registered FormFieldStates via the `FormRegistryWidget`.

* Auto-scroll to the first invalid field when validating.

* Each registered `FormField` widget exposes:
  * `FormFieldState` instance to get its `value`, `errorText`, etc.
  * `FormField.validator` method.
  * Helper method to scroll the registered form field widget into view.
  * Helper method to check if the registered field is fully visible.

## 📦 Requirements

* Flutter SDK `>=3.7.0`

* Dart SDK `>=2.19.0 <3.0.0`

## 💽 Installation

```yaml
dependencies:

  flutter_form_registry: ^0.7.0
```

## 📺 Usage

### 1. Setting up the Registry

First, wrap the widget that contains all your form fields with the `FormRegistryWidget`. This widget is is responsible for tracking all registered fields within its child tree.

You can access the registry and its features by providing a `GlobalKey` or by using the `FormRegistryWidget.of` static method.

**Example:**

```dart
  final GlobalKey<FormRegistryWidgetState> _registerdKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return FormRegistryWidget(
      key: _registerdKey,
      autoScrollToFirstInvalid: true,
      child: Form(
        child: Column(
          children: [
            // ...
          ],
        ),
      ),
    );
  }
```

The `FormRegistryWidget` also allows you to set default behaviors for all fields when you need to scroll to an error field. These behaviors are configured using parameters: `defaultAlignment`, `defaultDuration`, and `defaultCurve` and `defaultAlignmentPolicy`.

### 2. Registering Your Form Fields

There are three methods for registering your form fields with the registry, depending on how your fields are implemented.

#### Method A: For Custom `FormField` Widgets

If you've created your own widget that extends `FormField`, use the provided mixins to enable registry tracking.

##### How to Implement

1. Add the `FormFieldRegistrantMixin` to your custom `FormField` class.

2. Add the `FormFieldStateRegistrantMixin` to your corresponding `FormFieldState` class.

3. Override `registryId`, `registryType` and `lookupPriority` properties to control how your field is identified and prioritized.

**Example:**

```dart
class CustomTextFormField extends FormField<String>
    with FormFieldRegistrantMixin {
  CustomTextFormField({
    Key? key,
    this.registryId,
    this.registryType,
    this.lookupPriority,

    // some code ...

  });

  // some code ...

  @override
  final String? registryId;

  @override
  final Object? registryType;

  @override
  final int? lookupPriority;
}

class _CustomTextFormFieldState extends FormFieldState<String>
    with FormFieldStateRegistrantMixin {
  // some code ...
}
```

In the `FormFieldState`, you can override the default scrolling behavior here.

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

#### Method B: For Existing Widgets (With Scroll-to-Invalid-Field)

If you're using a widget from the Flutter framework (e.g., `TextFormField`) or a third-party package and want to enable the auto-scroll-to-invalid-field feature, you can wrap it with the `FormFieldRegistrant` widget.

##### How to Implement

1. Wrap the form field with the `FormFieldRegistrant` widget.

2. Provide the mandatory parameters: `validator`, and a `builder` function.

3. **Crucially**, pass the `formFieldKey` and `validator` arguments provided by the `builder` function to the widget that represents the form field. The widget returned by the `builder` can be a FormField directly (e.g. `TextFormField`) or have a `FormField` within its widget tree.

Here's an example using the [`date_field`](https://pub.dev/packages/date_field) package. In this case, the widget returned by the `builder` is wrapped with a `Container`.

```dart
FormFieldRegistrant(
  registryId: 'select date',
  registryType: 'date',
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
    return Container(
      height: 100,
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: DateTimeFormField(
        key: formFieldKey,
        validator: validator,
        onDateSelected: (value) {
          setState(() {
            selectedDate = value;
          });
        },
        mode: DateTimeFieldPickerMode.date,
        initialValue: selectedDate,
      ),
    );
  },
),
```

**Note:**

- If you need to manage a specific `FormFieldState` with your own `Key`, you should give that key to the `FormFieldRegistrant` as well.

- `FormFieldRegistrant` will ignore the `FormFieldState` if it already implements `FormFieldStateRegistrantMixin`.

- Fields registered with `FormFieldRegistrant` are not guaranteed to be in the same order as they appear in the widget tree. This is because a `FormFieldRegistrant` can only register a field after the `FormField` has been built and attached to the widget tree, which might not happen in a predictable sequence. You can use the `lookupPriority` property to ensure that fields are validated in a specific order, regardless of when they are registered.

#### Method C: For Existing Widgets (Without Scroll-to-Invalid-Field)

If you don't need the auto-scroll-to-invalid-field feature, you can use the simpler `FormFieldRegistrantProxy` widget. This is a lightweight option for registering your fields with less setup.

##### How to Implement

Simply wrap your `FormField` with the `FormFieldRegistrantProxy` widget. The child widget **must be** a `FormField` itself.

Here's an example using the [`date_field`](https://pub.dev/packages/date_field) package.

```dart
FormFieldRegistrantProxy(
  registryId: 'select date',
  registryType: 'date',
  child: DateTimeFormField(
    key: formFieldKey,
    validator: (DateTime? value) {
      if (value == null) {
        return "Empty!";
      }

      if (value.isBefore(DateTime.now())) {
        return 'The date must be before today';
      }

      return null;
    },
    onDateSelected: (value) {
      setState(() {
        selectedDate = value;
      });
    },
    mode: DateTimeFieldPickerMode.date,
    initialValue: selectedDate,
  ),
),
```

**Note:**

- `FormFieldRegistrantProxy` will ignore the `FormFieldState` if it already implements `FormFieldStateRegistrantMixin`, as the field is already a registrant itself.

### 3. Accessing Registered Fields

Once your fields are registered, you can access them from the `FormRegistryWidgetState` to perform actions like validation, getting `FormFieldState`s, or scrolling to a specific field.

#### To Get a Specific Field

Use the `FormRegistryWidgetState.getFieldBy` method with the field's `registryId` to access its corresponding `RegisteredField` instance. This allows you to validate or get the value of a single, specific form field without iterating through all of them.

```dart
final FormRegistryWidgetState formRegistryWidgetState = FormRegistryWidget.of(context);
final RegisteredField registeredField = formRegistryWidgetState.getFieldBy('your field registry id')!;

// Validate a specific field
final bool result = registeredField.validate();

// Get the FormFieldState and its value
final FormFieldState formFieldState = registeredField.formFieldState;

// Get the current value of the field
final currentValue = formFieldState.value;

// Get the validity of the FormFieldState without running the validator
final bool isValid = formFieldState.isValid;
```

#### To Filter Fields by Type

Use the `FormRegistryWidgetState.registeredFields` property to get an immutable list of all registered fields. You can then use the `registryType` to filter this list and perform actions on a specific group of fields.

```dart
final FormRegistryWidgetState formRegistryWidgetState = FormRegistryWidget.of(context);
final UnmodifiableListView<RegisteredField> registeredFields = formRegistryWidgetState.registeredFields;
for (final field in registeredFields) {
  if (field.type == 'date') {
    // do something...
  }
}
```

**Note on** `lookupPriority`: When a `FormField`'s visibility changes (e.g., it goes from being hidden to visible via a `Visibility` widget), it is re-registered at the end of the list. This means it will no longer be considered the "first invalid field". If you want all your form fields to maintain their position in the validation order, use the `lookupPriority` property. A lower number indicates a higher priority.
