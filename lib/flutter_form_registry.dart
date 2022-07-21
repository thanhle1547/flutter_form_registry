library flutter_form_registry;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

const double _kAlignment = 0.0;
const Duration _kDuration = Duration.zero;
const Curve _kCurve = Curves.ease;
const ScrollPositionAlignmentPolicy _kAlignmentPolicy =
    ScrollPositionAlignmentPolicy.explicit;

abstract class _ScrollConfiguration {
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

class RegisteredField {
  final Key? key;
  final String? fieldName;

  // ignore: prefer_final_fields
  BuildContext _context;
  BuildContext get context => _context;

  final _ScrollConfiguration _scrollConfiguration;

  RegisteredField._({
    this.key,
    this.fieldName,
    required BuildContext context,
    required _ScrollConfiguration scrollConfiguration,
  })  : _context = context,
        _scrollConfiguration = scrollConfiguration;

  String? _errorText;

  String? get errorText => _errorText;

  bool get hasError => _errorText != null;

  /// Animates the position such that the given object is as visible as possible
  /// by just scrolling this position.
  ///
  /// See also:
  ///
  ///  * [ScrollPositionAlignmentPolicy] for the way in which `alignment` is
  ///    applied, and the way the given `object` is aligned.
  void scrollToIntoView({
    double? alignment,
    Duration? duration,
    Curve? curve,
    ScrollPositionAlignmentPolicy? alignmentPolicy,
  }) {
    Scrollable.ensureVisible(
      context,
      alignment: alignment ?? _scrollConfiguration.alignment,
      duration: duration ?? _scrollConfiguration.duration,
      curve: curve ?? _scrollConfiguration.curve,
      alignmentPolicy: alignmentPolicy ?? _scrollConfiguration.alignmentPolicy,
    );
  }

  /// Check if this field is fully visible.
  ///
  /// To determine an accurate and precise result, [excludeLeading] and
  /// [excludeTrailing] parameters must be provided.
  ///
  /// e.g. When property [Scaffold.extendBodyBehindAppBar] is set to true which
  /// the height of the [body] is extended to include the height of the app bar.
  /// The [excludeLeading] will be equal to the app bar height.
  ///
  /// e.g. When property [Scaffold.extendBody] is set to true, and
  /// [bottomNavigationBar] or [persistentFooterButtons] is specified,
  /// then the [body] extends to the bottom of the Scaffold,
  /// instead of only extending to the top of the [bottomNavigationBar]
  /// or the [persistentFooterButtons]. The [excludeTrailing] will be equal to
  /// [bottomNavigationBar] or [persistentFooterButtons] height.
  ///
  /// **Note:** A long widget (e.g. multiline [TextFormField]) might not be
  /// fully visible.
  bool isFullyVisible({
    double excludeLeading = 0.0,
    double excludeTrailing = 0.0,
  }) {
    assert(!excludeLeading.isNegative && !excludeTrailing.isNegative);

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final viewport = RenderAbstractViewport.of(box);

    if (viewport == null || box == null) {
      return false;
    }

    final reveal = viewport.getOffsetToReveal(box, 0).offset;
    if (!reveal.isFinite) return false;

    final double itemOffset;

    if (viewport is RenderViewport) {
      itemOffset = reveal -
          viewport.offset.pixels +
          viewport.anchor * viewport.size.height;
    } else if (viewport is RenderViewportBase) {
      itemOffset = reveal - viewport.offset.pixels + viewport.size.height;
    } else {
      itemOffset = reveal;
    }

    final ScrollableState? scrollable = Scrollable.of(context);
    assert(scrollable != null);

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
    return other is RegisteredField &&
        other.key == key &&
        other.fieldName == fieldName;
  }

  @override
  int get hashCode => hashValues(key, fieldName);
}

/// A registry to track some [FormField]s in the tree.
///
/// This is **not** the alternative to the [Form] widget.
class FormRegistryWidget extends StatefulWidget {
  const FormRegistryWidget({
    Key? key,
    required this.autoScrollToFirstInvalid,
    this.defaultAlignment = _kAlignment,
    this.defaultDuration = _kDuration,
    this.defaultCurve = _kCurve,
    this.defaultAlignmentPolicy = _kAlignmentPolicy,
    required this.child,
  }) : super(key: key);

  /// Automatically scroll to the first invalid form field.
  final bool autoScrollToFirstInvalid;

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
    return context.findAncestorStateOfType<FormRegistryWidgetState>();
  }

  @override
  State<FormRegistryWidget> createState() => FormRegistryWidgetState();
}

class FormRegistryWidgetState extends State<FormRegistryWidget> {
  final Set<RegisteredField> _registeredFields = {};

  List<RegisteredField> get registeredFields =>
      List.unmodifiable(_registeredFields.toList());

  RegisteredField? get firstError {
    for (final RegisteredField field in _registeredFields) {
      if (field.hasError) return field;
    }

    return null;
  }

  void _register(RegisteredField field) => _registeredFields.add(field);

  void _unregister(RegisteredField? field) => _registeredFields.remove(field);

  @override
  Widget build(BuildContext context) => widget.child;
}

mixin FormFieldRegisteredWidgetMixin<T> on FormField<T> {
  // To identify
  String? get fieldName;
}

mixin FormFieldStateRegisteredWidgetMixin<T> on FormFieldState<T>
    implements _ScrollConfiguration {
  late FormRegistryWidgetState? _registryWidgetState;
  FormRegistryWidget? get _registryWidget => _registryWidgetState?.widget;

  RegisteredField? _registeredField;

  bool get _autoScrollToFirstError =>
      _registryWidget?.autoScrollToFirstInvalid ?? false;

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
    _registryWidgetState =
        context.findAncestorStateOfType<FormRegistryWidgetState>();
    if (_registryWidgetState != null && _registeredField == null) {
      _registeredField = RegisteredField._(
        key: widget.key,
        fieldName: widget is FormFieldRegisteredWidgetMixin
            ? (widget as FormFieldRegisteredWidgetMixin).fieldName
            : null,
        context: context,
        scrollConfiguration: this,
      );

      _registryWidgetState!._register(_registeredField!);
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    super.restoreState(oldBucket, initialRestore);
    _registeredField?._errorText = errorText;
  }

  @override
  void activate() {
    super.activate();
    _registeredField?._context = context;
    _registryWidgetState?._register(_registeredField!);
  }

  @override
  void deactivate() {
    super.deactivate();
    _registryWidgetState?._unregister(_registeredField);
  }

  @override
  void didToggleBucket(RestorationBucket? oldBucket) {
    super.didToggleBucket(oldBucket);
    _registeredField?._errorText = errorText;
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

    _registeredField?._errorText = errorText;

    if (!result &&
        _autoScrollToFirstError &&
        _registryWidgetState?.firstError == _registeredField) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        _registeredField?.scrollToIntoView(
          alignment: alignment,
          duration: duration,
          curve: curve,
          alignmentPolicy: alignmentPolicy,
        );
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final result = super.build(context);

    _registeredField?._errorText = errorText;

    return result;
  }
}

/// To track the [FormField] widget whose state will be updated at its
/// nearest ancestor [FormRegistryWidget].
class FormFieldRegisteredWidget<T> extends StatefulWidget
    implements _ScrollConfiguration {
  /// Creates a [FormFieldRegisteredWidget] widget.
  ///
  /// The [fieldName], [validator] and [buidler] parameters must not be null.
  const FormFieldRegisteredWidget({
    Key? key,
    required this.fieldName,
    this.restorationId,
    required this.validator,
    required this.buidler,
    this.alignment = _kAlignment,
    this.duration = _kDuration,
    this.curve = _kCurve,
    this.alignmentPolicy = _kAlignmentPolicy,
  }) : super(key: key);

  final String fieldName;

  /// Restoration ID to save and restore the state of the form field.
  ///
  /// Setting the restoration ID to a non-null value results in whether or not
  /// the form field validation persists.
  ///
  /// The state of this widget is persisted in a [RestorationBucket] claimed
  /// from the surrounding [RestorationScope] using the provided restoration ID.
  ///
  /// See also:
  ///
  ///  * [RestorationManager], which explains how state restoration works in
  ///    Flutter.
  final String? restorationId;

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

  /// Function that returns the widget representing your form field. It is
  /// passed the form field key as the key must be
  final Widget Function(
    GlobalKey<FormFieldState<T>> formFieldKey,
    FormFieldValidator<T> validator,
  ) buidler;

  /// To decide where to align the visible object
  /// when applying [ScrollPositionAlignmentPolicy.explicit].
  @override
  final double alignment;

  /// The duration to use when applying the `duration` parameter of
  /// [ScrollPosition.ensureVisible].
  @override
  final Duration duration;

  /// The curve to use when applying the `curve` parameter of
  /// [ScrollPosition.ensureVisible].
  @override
  final Curve curve;

  /// The policy to use when applying the `alignment` parameter of
  /// [ScrollPosition.ensureVisible].
  @override
  final ScrollPositionAlignmentPolicy alignmentPolicy;

  @override
  State<FormFieldRegisteredWidget<T>> createState() =>
      _FormFieldRegisteredWidgetState<T>();
}

/// State associated with a [FormFieldRegisteredWidget] widget.
class _FormFieldRegisteredWidgetState<T>
    extends State<FormFieldRegisteredWidget<T>> with RestorationMixin {
  late final GlobalKey<FormFieldState<T>> _key;

  late FormRegistryWidgetState? _registryWidgetState;
  FormRegistryWidget? get _registryWidget => _registryWidgetState?.widget;

  RegisteredField? _registeredField;

  bool get _autoScrollToFirstError =>
      _registryWidget?.autoScrollToFirstInvalid ?? false;

  @override
  void initState() {
    super.initState();

    _key = GlobalKey<FormFieldState<T>>();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.buidler(_key, _validator);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_key.currentContext == null) {
        _registryWidgetState?._unregister(_registeredField);
      } else {
        _registryWidgetState?._register(_registeredField!);
        _registeredField?._context = _key.currentContext!;
        _registeredField?._errorText = _key.currentState?.errorText;
      }
    });

    return result;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registryWidgetState =
        context.findAncestorStateOfType<FormRegistryWidgetState>();
    // _key.currentContext might be equal `null`
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_registryWidgetState != null && _registeredField == null) {
        _registeredField = RegisteredField._(
          key: _key,
          fieldName: widget.fieldName,
          context: _key.currentContext!,
          scrollConfiguration: widget,
        );

        _registryWidgetState!._register(_registeredField!);
      }
    });
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    _registeredField?._errorText = _key.currentState!.errorText;
  }

  @override
  void activate() {
    super.activate();
    _registeredField?._context = _key.currentContext!;
    _registryWidgetState?._register(_registeredField!);
  }

  @override
  void deactivate() {
    super.deactivate();
    _registryWidgetState?._unregister(_registeredField);
  }

  @override
  void didToggleBucket(RestorationBucket? oldBucket) {
    super.didToggleBucket(oldBucket);
    _registeredField?._errorText = _key.currentState!.errorText;
  }

  @override
  void dispose() {
    _registryWidgetState?._unregister(_registeredField);
    _registeredField = null;
    super.dispose();
  }

  String? _validator(T? value) {
    final String? result = widget.validator(value);

    _registeredField?._errorText = result;

    if (result != null &&
        _autoScrollToFirstError &&
        _registryWidgetState?.firstError == _registeredField) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _registeredField?.scrollToIntoView(
          alignment: widget.alignment,
          duration: widget.duration,
          curve: widget.curve,
          alignmentPolicy: widget.alignmentPolicy,
        );
      });
    }

    return result;
  }
}
