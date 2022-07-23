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
