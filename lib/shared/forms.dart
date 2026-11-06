import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/utils/constants.dart';
import 'actions.dart';
import 'widgets.dart';

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;
TextFormField formText(
  TextEditingController controller,
  String label, {
  bool required = false,
  bool numeric = false,
  int lines = 1,
  String? hint,
  Widget? suffix,
  Widget? prefix,
  FocusNode? focusNode,
  TextInputAction? textInputAction,
  String? Function(String?)? validator,
}) => TextFormField(
  controller: controller,
  focusNode: focusNode,
  textInputAction: textInputAction,
  decoration: InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffix,
    prefixIcon: prefix,
    alignLabelWithHint: lines > 1,
  ),
  keyboardType: numeric
      ? const TextInputType.numberWithOptions(decimal: true, signed: true)
      : lines > 1
      ? TextInputType.multiline
      : TextInputType.text,
  maxLines: lines,
  validator: validator ?? (required ? requiredText : null),
);
Widget formSelect(
  String label,
  String value,
  List<String> values,
  ValueChanged<String> onChanged, {
  String Function(String)? display,
}) => DropdownButtonFormField<String>(
  initialValue: values.contains(value) ? value : null,
  isExpanded: true,
  decoration: InputDecoration(labelText: label),
  items: values
      .map(
        (value) => DropdownMenuItem(
          value: value,
          child: Text(
            display?.call(value) ?? titleCaseLabel(value),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
      .toList(),
  onChanged: (value) {
    if (value != null) onChanged(value);
  },
  validator: (value) => value == null ? 'Choose one' : null,
);
String titleCaseLabel(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
Widget formDate(
  BuildContext context,
  String title,
  DateTime date,
  ValueChanged<DateTime> onChanged, {
  bool includeTime = false,
}) => ListTile(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  tileColor: Theme.of(context).colorScheme.surfaceContainerHighest
      .withValues(alpha: .45),
  leading: const Icon(Icons.calendar_today_rounded),
  title: Text(title),
  subtitle: Text(
    '${DateFormat.yMMMd().format(date)}${includeTime ? ' · ${DateFormat.jm().format(date)}' : ''}',
  ),
  onTap: () async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(1970),
      lastDate: DateTime(2200),
    );
    if (picked == null || !context.mounted) return;
    if (!includeTime) {
      onChanged(picked);
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );
    if (time != null) {
      onChanged(
        DateTime(picked.year, picked.month, picked.day, time.hour, time.minute),
      );
    }
  },
);
Widget formColors(int value, ValueChanged<int> onChanged) => Wrap(
  spacing: 12,
  runSpacing: 12,
  children: palette
      .map(
        (color) => Semantics(
          label: 'Accent color ${palette.indexOf(color) + 1}',
          selected: color == value,
          button: true,
          child: InkResponse(
            onTap: () => onChanged(color),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(color),
                shape: BoxShape.circle,
                border: color == value
                    ? Border.all(color: const Color(0xff30482b), width: 3)
                    : null,
              ),
              child: color == value
                  ? const Icon(
                      Icons.check_rounded,
                      color: Color(0xff233419),
                      size: 20,
                    )
                  : null,
            ),
          ),
        ),
      )
      .toList(),
);
Widget formIcons(String value, ValueChanged<String> onChanged) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: iconKeys
      .map(
        (key) => IconButton.filledTonal(
          isSelected: value == key,
          onPressed: () => onChanged(key),
          icon: Icon(iconFor(key)),
          tooltip: key,
        ),
      )
      .toList(),
);
Widget formChips(
  String label,
  Map<String, String> options,
  Set<String> selected,
  ValueChanged<Set<String>> changed,
) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Wrap(
      spacing: 6,
      runSpacing: 4,
      children: options.entries
          .map(
            (item) => FilterChip(
              label: Text(item.value),
              selected: selected.contains(item.key),
              onSelected: (value) => changed(
                value ? {...selected, item.key} : {...selected}
                  ..remove(item.key),
              ),
            ),
          )
          .toList(),
    ),
  ],
);

Future<bool?> showEditor(
  BuildContext context, {
  required String title,
  required List<Widget> Function(BuildContext, StateSetter) fields,
  required Future<void> Function() onSave,
  String saveLabel = 'Save',
  String? description,
}) async {
  final formKey = GlobalKey<FormState>();
  var busy = false;
  final navigator = Navigator.of(context);
  late ModalBottomSheetRoute<bool> route;
  route = ModalBottomSheetRoute<bool>(
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setLocal) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cancel editor',
                        onPressed: busy
                            ? null
                            : () {
                                if (!route.isActive) return;
                                if (route.isCurrent) {
                                  navigator.pop(false);
                                } else {
                                  navigator.removeRoute(route, false);
                                }
                              },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ...fields(
                    context,
                    setLocal,
                  ).expand((field) => [field, const SizedBox(height: 16)]),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            formKey.currentState!.save();
                            setLocal(() => busy = true);
                            final saved = await runSafe(context, onSave);
                            if (!context.mounted) return;
                            if (saved && route.isActive) {
                              if (route.isCurrent) {
                                navigator.pop(true);
                              } else {
                                navigator.removeRoute(route, true);
                              }
                            } else {
                              setLocal(() => busy = false);
                            }
                          },
                    child: busy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(saveLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final result = await navigator.push<bool>(route);
  // The pop future resolves BEFORE the exit animation disposes the form.
  // Callers own its controllers, so keep them alive until the route is removed.
  await route.completed;
  return result;
}

Future<String?> askText(
  BuildContext context,
  String title, {
  String initial = '',
  String label = 'Name',
  bool numeric = false,
  bool obscure = false,
}) async {
  final controller = TextEditingController(text: initial);
  String? result;
  await showEditor(
    context,
    title: title,
    fields: (context, setLocal) => [
      TextFormField(
        controller: controller,
        obscureText: obscure,
        enableSuggestions: !obscure,
        decoration: InputDecoration(labelText: label),
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        validator: requiredText,
      ),
    ],
    onSave: () async {
      result = controller.text.trim();
    },
  );
  controller.dispose();
  return result;
}
