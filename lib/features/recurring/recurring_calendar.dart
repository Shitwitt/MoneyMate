import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/data/ledger.dart';
import '../../core/data/recurring_schedule.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../shared/widgets.dart';

class RecurringCalendar extends StatefulWidget {
  final List<Recurring> rules;
  final Ledger ledger;
  final ValueChanged<Recurring> onOpen;
  const RecurringCalendar({
    super.key,
    required this.rules,
    required this.ledger,
    required this.onOpen,
  });
  @override
  State<RecurringCalendar> createState() => _RecurringCalendarState();
}

class _RecurringCalendarState extends State<RecurringCalendar> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selected = dayOnly(DateTime.now());
  void move(int offset) => setState(() {
    month = DateTime(month.year, month.month + offset);
    selected = month;
  });
  @override
  Widget build(BuildContext context) {
    final window = DateWindow(month, DateTime(month.year, month.month + 1));
    final events = <DateTime, List<(Recurring, bool)>>{};
    for (final rule in widget.rules) {
      for (final date in projectedOccurrences(rule, window)) {
        events.putIfAbsent(dayOnly(date), () => []).add((rule, false));
      }
      for (final entry in widget.ledger.data.transactions.where(
        (e) => e.recurringId == rule.id && window.contains(e.date),
      )) {
        events.putIfAbsent(dayOnly(entry.date), () => []).add((rule, true));
      }
    }
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = (month.weekday - DateTime.monday + 7) % 7;
    final cells = ((days + offset) / 7).ceil() * 7;
    final today = dayOnly(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TonalCard(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: month.year <= 1970 && month.month == 1
                        ? null
                        : () => move(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMM().format(month),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: month.year >= 2200 && month.month == 12
                        ? null
                        : () => move(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(336, constraints.maxWidth),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            for (final day in const [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    day,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisExtent:
                                    MediaQuery.textScalerOf(context).scale(18) +
                                    42,
                              ),
                          itemCount: cells,
                          itemBuilder: (context, index) {
                            final number = index - offset + 1;
                            if (number < 1 || number > days)
                              return const SizedBox.shrink();
                            final date = DateTime(
                              month.year,
                              month.month,
                              number,
                            );
                            final dayEvents = events[date] ?? [];
                            final isSelected = date == selected;
                            return Semantics(
                              button: true,
                              selected: isSelected,
                              label:
                                  '${DateFormat.yMMMMEEEEd().format(date)}. ${dayEvents.length} occurrences.',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => setState(() => selected = date),
                                child: AnimatedContainer(
                                  duration: referenceMotion(context, 160),
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Colors.transparent,
                                    border: Border.all(
                                      width: date == today ? 1.5 : 1,
                                      color: date == today
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$number',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                      const SizedBox(height: 5),
                                      SizedBox(
                                        height: 17,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            for (final event in dayEvents.take(
                                              2,
                                            ))
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 1,
                                                    ),
                                                child: _OccurrenceMarker(
                                                  event.$1,
                                                  event.$2,
                                                  widget.ledger,
                                                ),
                                              ),
                                            if (dayEvents.length > 2)
                                              Text(
                                                '+${dayEvents.length - 2}',
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Filled marker: recorded · Outline: upcoming',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          DateFormat.MMMMEEEEd().format(selected),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if ((events[selected] ?? []).isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No recurring occurrences on this day.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final event in events[selected] ?? <(Recurring, bool)>[])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TonalCard(
              onTap: () => widget.onOpen(event.$1),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ColorIcon(
                    widget.ledger.category(event.$1.categoryId)?.icon ??
                        'bills',
                    widget.ledger.category(event.$1.categoryId)?.color ??
                        0xfff6bb96,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.$1.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          event.$2
                              ? 'Recorded payment'
                              : 'Upcoming · ${recurrenceLabel(event.$1)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OccurrenceMarker extends StatelessWidget {
  final Recurring rule;
  final bool recorded;
  final Ledger ledger;
  const _OccurrenceMarker(this.rule, this.recorded, this.ledger);
  @override
  Widget build(BuildContext context) {
    final category = ledger.category(rule.categoryId);
    final color = Color(category?.color ?? 0xfff6bb96);
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: recorded ? color : Colors.transparent,
        border: Border.all(color: color),
      ),
      child: Icon(
        iconFor(category?.icon ?? 'bills'),
        size: 10,
        color: recorded ? AppColors.ink : color,
      ),
    );
  }
}
