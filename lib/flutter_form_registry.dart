import 'dart:collection';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The default value of [FormRegistryWidget.defaultScrollDelay],
/// [FormFieldStateRegistrantMixin.scrollDelay],
/// [_FormFieldRegistrantState.scrollDelay].
const Duration _kScrollDelay = Duration.zero;

/// The default value of [FormRegistryWidget.defaultAlignment],
/// [FormFieldStateRegistrantMixin.alignment],
/// [_FormFieldRegistrantState.alignment].
const double _kAlignment = 0.0;

/// The default value of [FormRegistryWidget.defaultDuration],
/// [FormFieldStateRegistrantMixin.duration],
/// [_FormFieldRegistrantState.duration].
const Duration _kDuration = Duration.zero;

/// The default value of [FormRegistryWidget.defaultCurve],
/// [FormFieldStateRegistrantMixin.curve],
/// [_FormFieldRegistrantState.curve].
const Curve _kCurve = Curves.ease;

/// The default value of [FormRegistryWidget.defaultAlignmentPolicy],
/// [FormFieldStateRegistrantMixin.alignmentPolicy],
/// [_FormFieldRegistrantState.alignmentPolicy].
const ScrollPositionAlignmentPolicy _kAlignmentPolicy =
    ScrollPositionAlignmentPolicy.explicit;

abstract class _ScrollConfiguration {
  Duration? get scrollDelay;

  /// To decide where to align the visible object
  /// when applying [ScrollPositionAlignmentPolicy.explicit].
  double get alignment;

  /// The duration to use when applying the `duration` parameter of
  /// [ScrollPosition.ensureVisible].
  Duration get duration;

  /// The curve to use when applying the `curve` parameter of
  /// [ScrollPosition.ensureVisible].
  Curve get curve;

  /// The policy to use when applying the `alignment` parameter of
  /// [ScrollPosition.ensureVisible].
  ScrollPositionAlignmentPolicy get alignmentPolicy;
}

/// The default value of [FormFieldRegistrant.lookupPriority],
/// [FormFieldRegistrantMixin.lookupPriority],
/// [RegisteredField._priority].
const int _kLookupPriority = -1;

class RegisteredField<T> {
  Key? _key;
  /// The key of the form field
  Key? get key => _key;

  /// It's registrarId in [FormFieldRegistrantMixin.registrarId]
  /// and [FormFieldRegistrant.registrarId]
  final String? id;

  /// It's registrarType in [FormFieldRegistrantMixin.registrarType]
  /// and [FormFieldRegistrant.registrarType]
  ///
  /// Can be used to filter the form fields.
  final Object? type;

  int _priority;

  final _ScrollConfiguration _scrollConfiguration;

  /// The state of the form field
  final FormFieldState<T> formFieldState;

  /// The type of the value.
  Type get valueType => T;

  /// Calls [FormField.validator] to set the [FormFieldState.errorText].
  /// Returns true if there were no errors.
  ///
  /// See also:
  ///
  ///  * [FormFieldState.isValid], which passively gets the validity
  ///    without setting [FormFieldState.errorText] or [FormFieldState.hasError].
  final bool Function() validate;

  RegisteredField._({
    Key? key,
    this.id,
    this.type,
    int? priority,
    required _ScrollConfiguration scrollConfiguration,
    required this.formFieldState,
    required this.validate,
  })  : _key = key,
        _priority = priority ?? _kLookupPriority,
        _scrollConfiguration = scrollConfiguration;

  /// Animates the position such that the given object is as visible as possible
  /// by just scrolling this position.
  ///
  /// See also:
  ///
  ///  * [ScrollPositionAlignmentPolicy] for the way in which [alignment] is
  ///    applied, and the way the given `object` is aligned.
  void scrollToIntoView({
    Duration? delay,
    double? alignment,
    Duration? duration,
    Curve? curve,
    ScrollPositionAlignmentPolicy? alignmentPolicy,
  }) {
    Future.delayed(
      delay ?? _scrollConfiguration.scrollDelay ?? Duration.zero,
      () {
        Scrollable.ensureVisible(
          formFieldState.context,
          alignment: alignment ?? _scrollConfiguration.alignment,
          duration: duration ?? _scrollConfiguration.duration,
          curve: curve ?? _scrollConfiguration.curve,
          alignmentPolicy:
              alignmentPolicy ?? _scrollConfiguration.alignmentPolicy,
        );
      },
    );
  }

  /// Check if this field is fully visible.
  ///
  /// To determine an accurate and precise result, [excludeLeading] and
  /// [excludeTrailing] parameters need to provide. Because this field
  /// might be obscured by another widget (e.g. AppBar).
  /// (It does not take widget opacity into account)
  ///
  /// e.g. When property [Scaffold.extendBodyBehindAppBar] is set to true which
  /// the height of the [Scaffold.body] is extended to include the height
  /// of the app bar. The [excludeLeading] will be equal to the app bar height.
  ///
  /// e.g. When property [Scaffold.extendBody] is set to true, and
  /// [Scaffold.bottomNavigationBar] or [Scaffold.persistentFooterButtons]
  /// is specified, then the [Scaffold.body] extends to the bottom of
  /// the Scaffold, instead of only extending to the top of
  /// the [Scaffold.bottomNavigationBar] or
  /// the [Scaffold.persistentFooterButtons].
  /// The [excludeTrailing] will be equal to [Scaffold.bottomNavigationBar]
  /// or [Scaffold.persistentFooterButtons] height.
  ///
  /// **Note:** A long widget (e.g. multiline [TextFormField]) might not be
  /// fully visible.
  bool isFullyVisible({
    double excludeLeading = 0.0,
    double excludeTrailing = 0.0,
  }) {
    assert(!excludeLeading.isNegative && !excludeTrailing.isNegative);

    final context = formFieldState.context;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final viewport = RenderAbstractViewport.maybeOf(box);

    if (viewport == null || box == null) {
      return false;
    }

    final reveal = viewport.getOffsetToReveal(box, 0).offset;
    if (!reveal.isFinite) return false;

    final double itemOffset;

    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    assert(scrollable != null);

    if (viewport is RenderViewport) {
      itemOffset = reveal -
          viewport.offset.pixels +
          viewport.anchor * viewport.size.height;
    } else if (viewport is RenderViewportBase) {
      itemOffset = reveal - viewport.offset.pixels + viewport.size.height;
    } else {
      itemOffset = reveal - scrollable!.position.pixels;
    }

    final double leadingEdge = (itemOffset - excludeLeading).round() /
        scrollable!.position.viewportDimension;
    final double trailingEdge =
        (itemOffset + box.size.height + excludeTrailing).round() /
            scrollable.position.viewportDimension;

    return leadingEdge >= 0 && trailingEdge <= 1;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is RegisteredField && other.key == key && other.id == id;
  }

  @override
  int get hashCode => Object.hash(key, id);
}

/// A registry to track some [FormField]s in the tree.
///
/// This is **not** the alternative to the [Form] widget.
class FormRegistryWidget extends StatefulWidget {
  const FormRegistryWidget({
    super.key,
    required this.autoScrollToFirstInvalid,
    this.defaultScrollDelay = _kScrollDelay,
    this.defaultAlignment = _kAlignment,
    this.defaultDuration = _kDuration,
    this.defaultCurve = _kCurve,
    this.defaultAlignmentPolicy = _kAlignmentPolicy,
    required this.child,
  });

  /// Automatically scroll to the first invalid form field.
  final bool autoScrollToFirstInvalid;

  final Duration defaultScrollDelay;

  /// To decide where to align the visible object
  /// when applying [ScrollPositionAlignmentPolicy.explicit].
  final double defaultAlignment;

  /// The duration to use when applying the `duration` parameter of
  /// [ScrollPosition.ensureVisible].
  final Duration defaultDuration;

  /// The curve to use when applying the `curve` parameter of
  /// [ScrollPosition.ensureVisible].
  final Curve defaultCurve;

  /// The policy to use when applying the `alignment` parameter of
  /// [ScrollPosition.ensureVisible].
  final ScrollPositionAlignmentPolicy defaultAlignmentPolicy;

  final Widget child;

  /// Finds the [FormRegistryWidgetState] from the closest instance of this class that
  /// encloses the given context.
  ///
  /// If no instance of this class encloses the given context, will cause an
  /// assert in debug mode, and throw an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// A more efficient solution is to split your build function into several
  /// widgets. This introduces a new context from which you can obtain the
  /// [FormRegistryWidget]. In this solution, you would have an outer widget
  /// that creates the [FormRegistryWidget] populated by instances of your
  /// new inner widgets, and then in these inner widgets you would use
  /// [FormRegistryWidget.of].
  ///
  /// A less elegant but more expedient solution is assign a [GlobalKey] to the
  /// [FormRegistryWidget], then use the `key.currentState` property to obtain
  /// the [FormRegistryWidgetState] rather than using the
  /// [FormRegistryWidget.of] function.
  ///
  /// If there is no [FormRegistryWidget] in scope, then this will throw an
  /// exception.
  /// To return null if there is no [FormRegistryWidget], use [maybeOf] instead.
  static FormRegistryWidgetState of(BuildContext context) {
    final FormRegistryWidgetState? result = FormRegistryWidget.maybeOf(context);
    if (result != null) return result;
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
        'FormRegistryWidget.of() called with a context that does not contain a FormRegistryWidget.',
      ),
      ErrorDescription(
        'No FormRegistryWidget ancestor could be found starting from the context that was passed to FormRegistryWidget.of(). '
        'This usually happens when the context provided is from the same StatefulWidget as that '
        'whose build function actually creates the FormRegistryWidget widget being sought.',
      ),
      ErrorHint(
        'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
        'context that is "under" the FormRegistryWidget. For an example of this, please see the '
        'documentation for Scaffold.of():\n'
        '  https://api.flutter.dev/flutter/material/Scaffold/of.html',
      ),
      ErrorHint(
        'A more efficient solution is to split your build function into several widgets. This '
        'introduces a new context from which you can obtain the FormRegistryWidget. In this solution, '
        'you would have an outer widget that creates the FormRegistryWidget populated by instances of '
        'your new inner widgets, and then in these inner widgets you would use FormRegistryWidget.of().\n'
        'A less elegant but more expedient solution is assign a GlobalKey to the FormRegistryWidget, '
        'then use the key.currentState property to obtain the FormRegistryWidgetState rather than '
        'using the FormRegistryWidget.of() function.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// Finds the [FormRegistryWidgetState] from the closest instance of
  /// this class that encloses the given context.
  ///
  /// If no instance of this class encloses the given context, will return null.
  /// To throw an exception instead, use [of] instead of this function.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// See also:
  ///
  ///  * [of], a similar function to this one that throws if no instance
  ///    encloses the given context. Also includes some sample code in its
  ///    documentation.
  static FormRegistryWidgetState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_FormRegistryWidgetScope>()
        ?._formRegistryWidgetState;
  }

  @override
  State<FormRegistryWidget> createState() => FormRegistryWidgetState();
}

/// State associated with an [FormRegistryWidget] widget.
///
/// Typically obtained using [FormRegistryWidget.of].
class FormRegistryWidgetState extends State<FormRegistryWidget> {
  final List<RegisteredField> _registeredFields = [];
  final Map<int, RegisteredField> _noPriority = {};

  UnmodifiableListView<RegisteredField> get registeredFields =>
      UnmodifiableListView(_registeredFields);

  /// Returns an unmodifiable list of all registered [FormFieldState] instances.
  UnmodifiableListView<FormFieldState> get formFieldStates =>
      UnmodifiableListView(_registeredFields.map((e) => e.formFieldState));

  /// Returns the first [RegisteredField]
  /// for which [FormFieldState.isValid] is false.
  RegisteredField? get firstInvalidField {
    for (final RegisteredField field in _registeredFields) {
      if (!field.formFieldState.isValid) return field;
    }

    return null;
  }

  /// Returns the first [RegisteredField]
  /// for which [FormFieldState.hasError] is true.
  RegisteredField? get firstErrorField {
    for (final RegisteredField field in _registeredFields) {
      if (field.formFieldState.hasError) return field;
    }

    return null;
  }

  /// Returns an unmodifiable list of [RegisteredField]s
  /// whose [FormFieldState.isValid] is false.
  UnmodifiableListView<RegisteredField> get invalidFields => _registeredFields.isEmpty
      ? UnmodifiableListView(const <RegisteredField>[])
      : UnmodifiableListView(_registeredFields.where((e) => e.formFieldState.isValid == false));

  /// Returns an unmodifiable list of [RegisteredField]s
  /// whose [FormFieldState.isValid] is true.
  UnmodifiableListView<RegisteredField> get errorFields => _registeredFields.isEmpty
      ? UnmodifiableListView(const <RegisteredField>[])
      : UnmodifiableListView(_registeredFields.where((e) => e.formFieldState.hasError));

  /// Returns true if every registered [FormFieldState]
  /// has [FormFieldState.isValid] equal to true.
  bool get allAreValid {
    return _registeredFields.every((e) => e.formFieldState.isValid);
  }

  RegisteredField? getFieldBy(String registrarId) {
    return _noPriority[registrarId.hashCode];
  }

  void _register(RegisteredField field) {
    if (_registeredFields.contains(field)) return;

    if (field._priority == -1 || _registeredFields.isEmpty) {
      _registeredFields.add(field);
      _tryAddEntry(field.id, field);
      return;
    }

    for (int i = 0; i < _registeredFields.length; i++) {
      final int current = _registeredFields[i]._priority;
      final int incomming = field._priority;

      if (incomming < current) {
        _registeredFields.insert(i, field);
        _tryAddEntry(field.id, field);
        return;
      }

      if (i + 1 == _registeredFields.length) {
        _registeredFields.add(field);
        _tryAddEntry(field.id, field);
        return;
      }

      final int next = _registeredFields[i + 1]._priority;

      if (incomming >= current && (incomming < next || next == -1)) {
        _registeredFields.insert(i + 1, field);
        _tryAddEntry(field.id, field);
        return;
      }
    }
  }

  void _tryAddEntry(String? id, RegisteredField field) {
    if (id == null) return;

    _noPriority[id.hashCode] = field;
  }

  void _unregister(RegisteredField? field) {
    _registeredFields.remove(field);
    _noPriority.remove(field?.id.hashCode);
  }

  @override
  Widget build(BuildContext context) {
    return _FormRegistryWidgetScope(
      formRegistryWidgetState: this,
      child: widget.child,
    );
  }
}

class _FormRegistryWidgetScope extends InheritedWidget {
  const _FormRegistryWidgetScope({
    required FormRegistryWidgetState formRegistryWidgetState,
    required super.child,
  }) : _formRegistryWidgetState = formRegistryWidgetState;

  final FormRegistryWidgetState _formRegistryWidgetState;

  @override
  bool updateShouldNotify(_FormRegistryWidgetScope oldWidget) {
    return _formRegistryWidgetState != oldWidget._formRegistryWidgetState;
  }
}

mixin FormFieldRegistrantMixin<T> on FormField<T> {
  /// The identifier between other [FormField]s when using [FormRegistryWidget].
  String? get registrarId;

  /// Can be used to filter the form fields in
  /// [FormRegistryWidgetState.registeredFields].
  Object? get registrarType;

  /// When the visibility of a `FormField` changes (e.g. from being invisible
  /// to visible using the [Visibility] widget), or when it is reinserted into
  /// the widget tree (activate) after having been removed (deactivate),
  /// it will be registered as the last one in the set. Consequently,
  /// when looking for the first invalid field, this `FormField`
  /// will not be retrieved, but another one will be.
  /// If you consider this as an issue, all you need to do is to set
  /// the priority to arrange this [FormField].
  ///
  /// Default to `-1` if `null`.
  ///
  /// Helping determines the placement of this widget in a sequence of widgets
  /// by assigning a numerical value.
  ///
  /// Lower values will be lookup first.
  int? get lookupPriority;
}

/// A mixin to auto-register a [RegisteredField] to the [FormRegistryWidget].
///
/// This mixin only registers [RegisteredField] if the
/// [FormRegistryWidget.maybeOf] return [FormRegistryWidgetState].
mixin FormFieldStateRegistrantMixin<T> on FormFieldState<T>
    implements _ScrollConfiguration {
  late FormRegistryWidgetState? _registryWidgetState;
  FormRegistryWidget? get _registryWidget => _registryWidgetState?.widget;

  RegisteredField? _registeredField;

  bool get _autoScrollToFirstError =>
      _registryWidget?.autoScrollToFirstInvalid ?? false;

  @override
  Duration? get scrollDelay =>
      _registryWidget?.defaultDuration ?? _kScrollDelay;

  /// To decide where to align the visible object
  /// when applying [ScrollPositionAlignmentPolicy.explicit].
  @override
  double get alignment => _registryWidget?.defaultAlignment ?? _kAlignment;

  /// The duration to use when applying the `duration` parameter of
  /// [ScrollPosition.ensureVisible].
  @override
  Duration get duration => _registryWidget?.defaultDuration ?? _kDuration;

  /// The curve to use when applying the `curve` parameter of
  /// [ScrollPosition.ensureVisible].
  @override
  Curve get curve => _registryWidget?.defaultCurve ?? _kCurve;

  /// The policy to use when applying the `alignment` parameter of
  /// [ScrollPosition.ensureVisible].
  @override
  ScrollPositionAlignmentPolicy get alignmentPolicy =>
      _registryWidget?.defaultAlignmentPolicy ?? _kAlignmentPolicy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _registryWidgetState = FormRegistryWidget.maybeOf(context);

    if (_registryWidgetState != null && _registeredField == null) {
      assert(widget is FormFieldRegistrantMixin);

      final registryWidgetState = _registryWidgetState;

      if (registryWidgetState == null) return;

      final formMixin = widget as FormFieldRegistrantMixin;

      final newRegisteredField = RegisteredField<T>._(
        key: widget.key,
        id: formMixin.registrarId,
        type: formMixin.registrarType,
        priority: formMixin.lookupPriority,
        scrollConfiguration: this,
        formFieldState: this,
        validate: validate,
      );

      _registeredField = newRegisteredField;

      registryWidgetState._register(newRegisteredField);
    }
  }

  @override
  void activate() {
    super.activate();
    _registryWidgetState?._register(_registeredField!);
  }

  @override
  void deactivate() {
    super.deactivate();
    _registryWidgetState?._unregister(_registeredField);
  }

  @override
  void dispose() {
    _registryWidgetState?._unregister(_registeredField);
    _registeredField = null;
    super.dispose();
  }

  @override
  bool validate() {
    final bool result = super.validate();

    if (!result &&
        _autoScrollToFirstError &&
        _registryWidgetState?.firstErrorField == _registeredField) {
      SchedulerBinding.instance.addPostFrameCallback(
        _maybeScrollToReveal,
        debugLabel: 'FormFieldRegistrant.scrollToReveal',
      );
    }

    return result;
  }

  void _maybeScrollToReveal(Duration _) {
    _registeredField?.scrollToIntoView(
      delay: scrollDelay,
      alignment: alignment,
      duration: duration,
      curve: curve,
      alignmentPolicy: alignmentPolicy,
    );
  }
}

/// To track the [FormField] widget whose state will be updated at its
/// nearest ancestor [FormRegistryWidget].
///
/// If the [FormFieldState] already implements [FormFieldStateRegistrantMixin],
/// it won't be registered again.
class FormFieldRegistrant<T> extends StatefulWidget {
  /// Creates a [FormFieldRegistrant] widget.
  ///
  /// The [validator] and [builder] parameters must not be null.
  const FormFieldRegistrant({
    super.key,
    this.registrarId,
    this.registrarType,
    this.lookupPriority,
    this.formFieldKey,
    required this.validator,
    required this.builder,
    this.scrollDelay,
    this.alignment,
    this.duration,
    this.curve,
    this.alignmentPolicy,
  });

  /// The identifier between other [FormField]s.
  final String? registrarId;

  /// Can be used to filter the form fields in
  /// [FormRegistryWidgetState.registeredFields].
  final Object? registrarType;

  /// When the visibility of a `FormField` changes (e.g. from being invisible
  /// to visible using the [Visibility] widget), or when it is reinserted into
  /// the widget tree (activate) after having been removed (deactivate),
  /// it will be registered as the last one in the set. Consequently,
  /// when looking for the first invalid field, this `FormField`
  /// will not be retrieved, but another one will be.
  /// If you consider this as an issue, all you need to do is to set
  /// the priority to arrange this [FormField].
  ///
  /// Default to `-1` if `null`.
  ///
  /// Helping determines the placement of this widget in a sequence of widgets
  /// by assigning a numerical value.
  ///
  /// Lower values will be lookup first.
  final int? lookupPriority;

  /// The existed form field key
  ///
  /// A new `GlobalKey<FormFieldState<T>>`will be created if [formFieldKey]
  /// changed to `null`.
  final GlobalKey<FormFieldState<T>>? formFieldKey;

  /// An optional method that validates an input. Returns an error string to
  /// display if the input is invalid, or null otherwise.
  ///
  /// The returned value is exposed by the [FormFieldState.errorText] property.
  /// The [TextFormField] uses this to override the [InputDecoration.errorText]
  /// value.
  ///
  /// Alternating between error and normal state can cause the height of the
  /// [TextFormField] to change if no other subtext decoration is set on the
  /// field. To create a field whose height is fixed regardless of whether or
  /// not an error is displayed, either wrap the  [TextFormField] in a fixed
  /// height parent like [SizedBox], or set the [InputDecoration.helperText]
  /// parameter to a space.
  final FormFieldValidator<T> validator;

  /// The function that returns the widget representing your form field. It is
  /// passed the form field key as the key must be (in case there is no existing
  /// form field key, i.e, [formFieldKey] is null).
  final Widget Function(
    GlobalKey<FormFieldState<T>> formFieldKey,
    FormFieldValidator<T> validator,
  ) builder;

  final Duration? scrollDelay;

  /// To decide where to align the visible object
  /// when applying [ScrollPositionAlignmentPolicy.explicit].
  final double? alignment;

  /// The duration to use when applying the `duration` parameter of
  /// [ScrollPosition.ensureVisible].
  final Duration? duration;

  /// The curve to use when applying the `curve` parameter of
  /// [ScrollPosition.ensureVisible].
  final Curve? curve;

  /// The policy to use when applying the `alignment` parameter of
  /// [ScrollPosition.ensureVisible].
  final ScrollPositionAlignmentPolicy? alignmentPolicy;

  @override
  State<FormFieldRegistrant<T>> createState() => _FormFieldRegistrantState<T>();
}

/// State associated with a [FormFieldRegistrant] widget.
class _FormFieldRegistrantState<T> extends State<FormFieldRegistrant<T>>
    with _ScrollConfiguration {
  late GlobalKey<FormFieldState<T>> _key =
      widget.formFieldKey ?? GlobalKey<FormFieldState<T>>();

  late FormRegistryWidgetState? _registryWidgetState;
  FormRegistryWidget? get _registryWidget => _registryWidgetState?.widget;

  RegisteredField? _registeredField;

  bool get _autoScrollToFirstError =>
      _registryWidget?.autoScrollToFirstInvalid ?? false;

  @override
  Duration get scrollDelay =>
      widget.scrollDelay ??
      _registryWidget?.defaultScrollDelay ??
      _kScrollDelay;

  /// To decide where to align the visible object
  /// when applying [ScrollPositionAlignmentPolicy.explicit].
  @override
  double get alignment =>
      widget.alignment ?? _registryWidget?.defaultAlignment ?? _kAlignment;

  /// The duration to use when applying the `duration` parameter of
  /// [ScrollPosition.ensureVisible].
  @override
  Duration get duration =>
      widget.duration ?? _registryWidget?.defaultDuration ?? _kDuration;

  /// The curve to use when applying the `curve` parameter of
  /// [ScrollPosition.ensureVisible].
  @override
  Curve get curve => widget.curve ?? _registryWidget?.defaultCurve ?? _kCurve;

  /// The policy to use when applying the `alignment` parameter of
  /// [ScrollPosition.ensureVisible].
  @override
  ScrollPositionAlignmentPolicy get alignmentPolicy =>
      widget.alignmentPolicy ??
      _registryWidget?.defaultAlignmentPolicy ??
      _kAlignmentPolicy;

  @override
  Widget build(BuildContext context) {
    final result = widget.builder(_key, _validator);

    SchedulerBinding.instance.addPostFrameCallback(_maybeReregister);

    return result;
  }

  void _maybeReregister(Duration _) {
    if (_key.currentContext == null) {
      _registryWidgetState?._unregister(_registeredField);
    } else {
      if (!mounted) return;

      _maybeRegister();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registryWidgetState = FormRegistryWidget.maybeOf(context);

    SchedulerBinding.instance.addPostFrameCallback(_maybeInit);
  }

  void _maybeInit(Duration _) {
    if (!mounted) return;

    final registryWidgetState = _registryWidgetState;

    if (registryWidgetState != null && _registeredField == null) {
      final formFieldState = _key.currentState!;

      if (formFieldState is FormFieldStateRegistrantMixin) {
        // ignore the FormFieldState if it already implements FormFieldStateRegistrantMixin
        return;
      }

      final newRegisteredField = _createRegisteredField(formFieldState);
      _registeredField = newRegisteredField;

      registryWidgetState._register(newRegisteredField);
    }
  }

  @override
  void activate() {
    super.activate();
    _maybeRegister();
  }

  void _maybeRegister() {
    final registeredField = _registeredField;
    if (registeredField != null) {
      _registryWidgetState?._register(registeredField);
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    _registryWidgetState?._unregister(_registeredField);
  }

  @override
  void didUpdateWidget(covariant FormFieldRegistrant<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    _registeredField?._priority = widget.lookupPriority ?? _kLookupPriority;

    final formFieldKey = widget.formFieldKey;

    if (oldWidget.formFieldKey == null) {
      if (formFieldKey == null) return;

      _key = formFieldKey;

      SchedulerBinding.instance.addPostFrameCallback(_updateRegisteredFieldKey);
    } else {
      assert(
        formFieldKey != null,
        'Once the [FormFieldRegistrant.formFieldKey] has a non-null '
        'value, it cannot be changed to null again',
      );

      final formFieldState = formFieldKey?.currentState;
      if (formFieldKey != null && formFieldState != null && _registeredField?.formFieldState != formFieldState) {
        _registryWidgetState?._unregister(_registeredField);

        _key = formFieldKey;

        final newRegisteredField = _createRegisteredField(formFieldState);
        _registeredField = newRegisteredField;

        _registryWidgetState?._register(newRegisteredField);
      }
    }
  }

  void _updateRegisteredFieldKey(Duration _) {
    _registeredField?._key = _key;
  }

  RegisteredField<T> _createRegisteredField(FormFieldState<T> formFieldState) {
    return RegisteredField<T>._(
      key: _key,
      id: widget.registrarId,
      type: widget.registrarType,
      priority: widget.lookupPriority,
      scrollConfiguration: this,
      formFieldState: formFieldState,
      validate: formFieldState.validate,
    );
  }

  @override
  void dispose() {
    _registryWidgetState?._unregister(_registeredField);
    _registeredField = null;
    super.dispose();
  }

  String? _validator(T? value) {
    final String? result = widget.validator(value);

    if (result != null &&
        _autoScrollToFirstError &&
        _registryWidgetState?.firstErrorField == _registeredField) {
      SchedulerBinding.instance.addPostFrameCallback(
        _maybeScrollToReveal,
        debugLabel: 'FormFieldRegistrant.scrollToReveal',
      );
    }

    return result;
  }

  void _maybeScrollToReveal(Duration _) {
    _registeredField?.scrollToIntoView(
      delay: scrollDelay,
      alignment: alignment,
      duration: duration,
      curve: curve,
      alignmentPolicy: alignmentPolicy,
    );
  }
}
