import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'widgets.dart';

/// Full-page reference editor. Save is pinned, failures keep the draft, and
/// callers retain their controllers until the route's exit has completed.
Future<bool?> showReferenceEditor(
  BuildContext context, {
  required String title,
  required List<Widget> Function(BuildContext, StateSetter) fields,
  required Future<void> Function() onSave,
  required String saveLabel,
  String? description,
}) async {
  final form = GlobalKey<FormState>();
  var busy = false;
  final navigator = Navigator.of(context);
  late MaterialPageRoute<bool> route;
  route = MaterialPageRoute<bool>(
    builder: (_) => StatefulBuilder(
      builder: (context, setLocal) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Form(
          key: form,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (description != null) ...[
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                ],
                ...fields(
                  context,
                  setLocal,
                ).expand((w) => [w, const SizedBox(height: 18)]),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: FilledButton.icon(
            onPressed: busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    form.currentState!.save();
                    setLocal(() => busy = true);
                    final saved = await runSafe(context, onSave);
                    if (!context.mounted || !route.isActive) return;
                    if (saved) {
                      if (route.isCurrent) {
                        navigator.pop(true);
                      } else {
                        navigator.removeRoute(route, true);
                      }
                    } else {
                      setLocal(() => busy = false);
                    }
                  },
            icon: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(saveLabel),
          ),
        ),
      ),
    ),
  );
  final result = await navigator.push(route);
  await route.completed;
  return result;
}

class ReferenceChoices extends StatelessWidget {
  final String title, selected;
  final Map<String, String> choices;
  final ValueChanged<String> onChanged;
  final VoidCallback? onAdd;
  final bool expanded;
  const ReferenceChoices({
    super.key,
    required this.title,
    required this.selected,
    required this.choices,
    required this.onChanged,
    this.onAdd,
    this.expanded = true,
  });
  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: expanded,
    tilePadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(choices[selected] ?? 'None'),
    childrenPadding: const EdgeInsets.only(bottom: 12),
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final choice in choices.entries)
              ChoiceChip(
                label: Text(choice.value),
                selected: selected == choice.key,
                onSelected: (_) => onChanged(choice.key),
              ),
            if (onAdd != null)
              ActionChip(
                avatar: const Icon(Icons.add_circle_outline),
                label: const Text('Add'),
                onPressed: onAdd,
              ),
          ],
        ),
      ),
    ],
  );
}

class ReferenceColorPicker extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const ReferenceColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  @override
  State<ReferenceColorPicker> createState() => _ReferenceColorPickerState();
}

class _ReferenceColorPickerState extends State<ReferenceColorPicker> {
  int page = 0;
  static const colors = <int>[
    0xfff44336,
    0xffe91e63,
    0xff9c27b0,
    0xff673ab7,
    0xff3f51b5,
    0xff2196f3,
    0xff03a9f4,
    0xff00bcd4,
    0xff009688,
    0xff4caf50,
    0xff8bc34a,
    0xffcddc39,
    0xffffeb3b,
    0xffffc107,
    0xffff9800,
    0xffff5722,
    0xff795548,
    0xff607d8b,
    0xff9e9e9e,
  ];
  void choose(Color color) => widget.onChanged(color.toARGB32());
  @override
  Widget build(BuildContext context) {
    final current = Color(widget.value),
        hsl = HSLColor.fromColor(Color(widget.value));
    final shades = List.generate(
      10,
      (i) => hsl.withLightness(.94 - i * .085).toColor().toARGB32(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Colors', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        PillTabs(
          labels: const ['Primary', 'Accent', 'Wheel'],
          selected: page,
          onSelected: (n) => setState(() => page = n),
        ),
        const SizedBox(height: 16),
        if (page != 2)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in page == 0 ? [...colors, ...shades] : shades)
                Semantics(
                  button: true,
                  selected: value == widget.value,
                  label: 'Color ${value.toRadixString(16)}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => widget.onChanged(value),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(value),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: value == widget.value
                          ? Icon(
                              Icons.check,
                              color: Color(value).computeLuminance() > .179
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          )
        else ...[
          Center(
            child: Semantics(
              label:
                  'Hue and saturation wheel. Sliders below provide accessible controls.',
              child: GestureDetector(
                onPanDown: (event) => wheel(event.localPosition),
                onPanUpdate: (event) => wheel(event.localPosition),
                child: CustomPaint(
                  size: const Size(220, 220),
                  painter: _ColorWheel(current),
                ),
              ),
            ),
          ),
          Slider(
            min: 0,
            max: 360,
            value: HSVColor.fromColor(current).hue,
            label: 'Hue',
            semanticFormatterCallback: (n) => 'Hue ${n.round()} degrees',
            onChanged: (n) =>
                choose(HSVColor.fromColor(current).withHue(n).toColor()),
          ),
          Slider(
            value: HSVColor.fromColor(current).saturation,
            label: 'Saturation',
            semanticFormatterCallback: (n) =>
                'Saturation ${(n * 100).round()} percent',
            onChanged: (n) =>
                choose(HSVColor.fromColor(current).withSaturation(n).toColor()),
          ),
          Slider(
            value: HSVColor.fromColor(current).value,
            label: 'Brightness',
            semanticFormatterCallback: (n) =>
                'Brightness ${(n * 100).round()} percent',
            onChanged: (n) =>
                choose(HSVColor.fromColor(current).withValue(n).toColor()),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey(widget.value),
          initialValue:
              '0x${widget.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
          decoration: InputDecoration(
            labelText: 'ARGB color',
            suffixIcon: IconButton(
              tooltip: 'Copy color value',
              icon: const Icon(Icons.copy_outlined),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: '0x${widget.value.toRadixString(16).padLeft(8, '0')}',
                  ),
                );
                if (context.mounted) toast(context, 'Color copied');
              },
            ),
          ),
          onSaved: (text) {
            final raw = (text ?? '').replaceFirst(
              RegExp(r'^(0x|#)', caseSensitive: false),
              '',
            );
            if (RegExp(r'^[a-fA-F0-9]{6}([a-fA-F0-9]{2})?$').hasMatch(raw))
              widget.onChanged(
                int.parse(raw.length == 6 ? 'ff$raw' : raw, radix: 16),
              );
          },
          onFieldSubmitted: (text) {
            final raw = text.replaceFirst(
              RegExp(r'^(0x|#)', caseSensitive: false),
              '',
            );
            if (RegExp(r'^[a-fA-F0-9]{6}([a-fA-F0-9]{2})?$').hasMatch(raw))
              widget.onChanged(
                int.parse(raw.length == 6 ? 'ff$raw' : raw, radix: 16),
              );
          },
          validator: (text) =>
              RegExp(
                r'^(0x|#)?[a-fA-F0-9]{6}([a-fA-F0-9]{2})?$',
                caseSensitive: false,
              ).hasMatch(text ?? '')
              ? null
              : 'Enter a six- or eight-digit hexadecimal color',
        ),
      ],
    );
  }

  void wheel(Offset point) {
    final delta = point - const Offset(110, 110);
    final hue = (math.atan2(delta.dy, delta.dx) * 180 / math.pi + 360) % 360;
    choose(
      HSVColor.fromColor(Color(widget.value))
          .withHue(hue)
          .withSaturation((delta.distance / 110).clamp(0.0, 1.0))
          .toColor(),
    );
  }
}

class _ColorWheel extends CustomPainter {
  final Color selected;
  _ColorWheel(this.selected);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawCircle(
      rect.center,
      size.width / 2,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Colors.red,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
        ).createShader(rect),
    );
    canvas.drawCircle(
      rect.center,
      size.width / 2,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );
    final hsv = HSVColor.fromColor(selected);
    final point =
        rect.center +
        Offset(
              math.cos(hsv.hue * math.pi / 180),
              math.sin(hsv.hue * math.pi / 180),
            ) *
            (hsv.saturation * size.width / 2);
    canvas.drawCircle(
      point,
      8,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      point,
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ColorWheel old) => old.selected != selected;
}

class ReferenceDatePair extends StatelessWidget {
  final DateTime? start;
  final DateTime end;
  final ValueChanged<DateTime> onStart, onEnd;
  const ReferenceDatePair({
    super.key,
    required this.start,
    required this.end,
    required this.onStart,
    required this.onEnd,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns =
          box.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(1) > 1.3
          ? 1
          : 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final first in [true, false])
            SizedBox(
              width: (box.maxWidth - (columns - 1) * 8) / columns,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  title: Text(
                    first ? 'Start date' : 'End date',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  subtitle: Text(
                    first && start == null
                        ? 'Not recorded'
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(first ? start! : end),
                  ),
                  onTap: () async {
                    final chosen = await showDatePicker(
                      context: context,
                      initialDate: (first ? start : end) ?? DateTime.now(),
                      firstDate: DateTime(1970),
                      lastDate: DateTime(2200),
                    );
                    if (chosen != null && context.mounted)
                      (first ? onStart : onEnd)(chosen);
                  },
                ),
              ),
            ),
        ],
      );
    },
  );
}
