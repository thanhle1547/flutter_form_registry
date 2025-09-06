## 0.8.0

* README API correction.

* Fix Dart SDK do not constraint to `2.19.0` at minimum in README.

* Fix Flutter SDK do not constraint to `3.7.0` at minimum in README.

* Update the upper bound of the SDK constraint to `<4.0.0`.

* New example project using Flutter version 3.19.6

* Make `FormFieldRegistrant.registrarId` nullable.

* Handle `FormFieldRegistrant.formFieldKey` changed or associated `FormField` changed.

* Add timeline events for post frame callbacks.

* `FormFieldRegistrant` will ignore the `FormFieldState` if it already implement `FormFieldStateRegistrantMixin`.

* Uses `MemoryAllocations` to track instances of `RegisteredField`.

* Remove reference to old version in README.

* Update widget documents.

* **Add** `FormRegistryWidgetState.formFieldStates`.
* **Add** `FormRegistryWidgetState.firstInvalidField`.
* **Add** `FormRegistryWidgetState.firstErrorField`.
* **Add** `FormRegistryWidgetState.errorFields`.
* **Add** `FormRegistryWidgetState.allAreValid`.

* **Add** `FormFieldRegistrantProxy`.

* **Add** `RegisteredField.formFieldState`.

* **Breaking:**

  * **Remove** `FormFieldRegistrant.restorationId`.

  * **Remove** `FormRegistryWidgetState.firstInvalid`, use `FormRegistryWidgetState.firstErrorField` instead.

  * **Replace** `RegisteredField.isValid()`, `RegisteredField.errorText`, `RegisteredField.hasError` and `RegisteredField.getValue()` with `RegisteredField.formFieldState`. It's also fix the issue that `RegisteredField.hasError` return true and `RegisteredField.errorText` return old error message after `FormFieldState.reset()` or `FormState.reset()` are called.

    - `RegisteredField.isValid()` ⇒ `RegisteredField.formFieldState.isValid`
    - `RegisteredField.errorText` ⇒ `RegisteredField.formFieldState.errorText`
    - `RegisteredField.hasError` ⇒ `RegisteredField.formFieldState.hasError`
    - `RegisteredField.getValue()` ⇒ `RegisteredField.formFieldState.getValue`

  * `FormRegistryWidgetState.invalidFields` now returns all the `RegisteredField` that the `FormFieldState.isValid` equal to false. Previously, it returns all the `RegisteredField` that the `FormFieldState.hasError` equal to true.

  * **Remove** ability to override the default scrolling behavior

    - ~~FormFieldStateRegistrantMixin.scrollDelay~~
    - ~~FormFieldStateRegistrantMixin.alignment~~
    - ~~FormFieldStateRegistrantMixin.duration~~
    - ~~FormFieldStateRegistrantMixin.curve~~
    - ~~FormFieldStateRegistrantMixin.alignmentPolicy~~

    - ~~FormFieldRegistrant.scrollDelay~~
    - ~~FormFieldRegistrant.alignment~~
    - ~~FormFieldRegistrant.duration~~
    - ~~FormFieldRegistrant.curve~~
    - ~~FormFieldRegistrant.alignmentPolicy~~

* Provide fix suggestions for `dart fix`.


## 0.7.0

* **Add** `RegisteredField.getValue()` methods.
* **Add** `RegisteredField.valueType` getter.
* **Add** `RegisteredField.type`, `FormFieldRegistrantMixin.registrarType` and `FormFieldRegistrant.registrarType`.
* Update docs.
* Update README.


## 0.6.5

* No code changes.
* Bump to version 0.6.5.
* Update README.


## 0.6.4

* Updates minimum supported SDK version to Flutter 3.7/Dart 2.19.


## 0.6.3

* Fix the form field registrant did not fully unregister.
* Change the return type of `FormRegistryWidgetState.registeredFields` and `FormRegistryWidgetState.invalidFields` to `UnmodifiableListView`.
* Add link to repository in pubspec.
* Update docs.
* Update README.


## 0.6.2

* No code changes.
* Bump to version 0.6.2.
* Update pubspec decription.
* Update README.


## 0.6.1

* update docs


## 0.6.0

* **Add** `FormRegistryWidgetState.invalidFields` getter.
* **Add** `FormRegistryWidgetState.getFieldBy()` method.
* **Add** `RegisteredField.isValid()` and `validate()` methods.
* update docs


## 0.5.0

* **Breaking:**

  * Rename `registryId` to `registrarId`

  * rename `*RegisteredWidget` class by `*Registrant`

    * `FormFieldRegisteredWidgetMixin` to `FormFieldRegistrantMixin`

    * `FormFieldStateRegisteredWidgetMixin` to `FormFieldStateRegistrantMixin`

    * `FormFieldRegisteredWidget` to `FormFieldRegistrant`

* improve performance of `FormRegistryWidget.maybeOf` method


## 0.4.3

* update docs
* fix `hashValues` was deprecated


## 0.4.2

* update docs


## 0.4.1

* fix #e761e6d


## 0.4.0

* Give a way to reuse or be capable of using existed form field key on `FormFieldRegisteredWidget` by adding that key to `formFieldKey`


## 0.3.5

* using ! operator


## 0.3.4

* fix: `RegisteredField.isFullyVisible` return false when viewport is `_RenderSingleChildViewport`


## 0.3.3

* using `FormRegistryWidget.maybeOf` instead of calling `findAncestorStateOfType` directly


## 0.3.2

* update FormFieldStateRegisteredWidgetMixin.didChangeDependencies


## 0.3.1

* fix scrollToIntoView did not scroll exactly when using FormFieldRegisteredWidget


## 0.3.0

* Change environmental requirements: minimum flutter version is 3.0.0

* fix typo


## 0.2.0

* **Add** scroll delay.


## 0.1.0

* **Breaking:**

  * Rename `fieldName` to `registryId`

  * Rename `firstError` to `firstInvalid`

* **Add** `lookupPriority` to change the `FormRegistryWidgetState.firstInvalid`

* fix: when using `FormFieldRegisteredWidget`, if the provided key did not pass to the form field, unregister that field.


## 0.0.3

* Change environmental requirements: minimum flutter version is 2.5.0 

* Remove Restoration ID from `RegisteredField`

* rewrite didChangeDependencies


## 0.0.2

* override == operator of `RegisteredField`

* Change the type of variable `FormRegistryWidgetState._registeredFields` to `Set`

* override deactivate method


## 0.0.1

* Initial release contains the following features:

  * Tracking registered widget.

  * Auto-scroll to the first Form's invalid field.

  * Each registered FormField widget contains its key, error text and method to scroll its into view and check is it fully visible.
