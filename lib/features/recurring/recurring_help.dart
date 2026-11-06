import 'package:flutter/material.dart';

import '../../shared/how_it_works_sheet.dart';

const recurringHelpSections = [
  (
    Icons.repeat_rounded,
    'Flexible frequencies',
    'Choose daily, weekly, fortnightly, monthly, quarterly, half-yearly, yearly, or a custom number of days. Month-end dates stay anchored: January 31 becomes February 28, then March 31.',
  ),
  (
    Icons.auto_awesome_outlined,
    'Automatic processing',
    'When enabled, due transactions are created when you open or resume Tink. Nothing is charged and no banking service is contacted. A safety cap limits each catch-up to 1,000 occurrences per schedule.',
  ),
  (
    Icons.bar_chart_rounded,
    'Overview & statistics',
    'See monthly and yearly planning estimates, upcoming payments, recorded occurrences, and actual transaction totals. Projections use your manual currency rates; they are not account balances.',
  ),
  (
    Icons.schedule_rounded,
    'Active & due',
    'Active shows running schedules. Due shows payments whose scheduled time has arrived. Process records exactly one due transaction; Skip advances one occurrence without changing your balance.',
  ),
  (
    Icons.calendar_month_rounded,
    'Calendar view',
    'Browse a Monday-first monthly calendar. Colored icons identify upcoming occurrences and recorded payments. Select a day to see its schedules; skipped dates do not create transactions.',
  ),
  (
    Icons.archive_outlined,
    'Archive & restore',
    'Archive a schedule to stop processing and reminders without deleting its history. You can restore it later. Paused and ended legacy schedules are also available in Archived.',
  ),
  (
    Icons.notifications_none_rounded,
    'Private reminders',
    'Choose an on-date reminder or a lead time of up to 30 days. Enable notifications in Settings and grant device permission. Android and iOS use inexact local scheduling; web reminders are unavailable.',
  ),
  (
    Icons.event_busy_outlined,
    'End dates',
    'Set an optional inclusive end date. After its last occurrence the schedule becomes inactive. Posted transactions remain in your ledger.',
  ),
  (
    Icons.pie_chart_outline_rounded,
    'Link a budget',
    'Expenses can be linked to a budget and are included in that budget’s matching period when processed. Normal category-based budget calculations continue to work.',
  ),
  (
    Icons.sell_outlined,
    'Labels',
    'Attach your existing labels to a schedule. They are copied into every newly processed transaction for filtering and reports.',
  ),
  (
    Icons.place_outlined,
    'Places',
    'Link a place to see where recurring spending happens. The place is copied into newly processed transactions; no location permission or tracking is used.',
  ),
  (
    Icons.people_outline_rounded,
    'People',
    'Link existing people for a clearer private record. People tags are copied into newly processed transactions, without sending anyone a message.',
  ),
];

Future<void> showRecurringHelp(BuildContext context) => showHowItWorks(
  context,
  title: 'How Recurring Works',
  introduction:
      'Recurring transactions help you track subscriptions, bills, and regular payments automatically. They create local records, never bank charges.',
  sections: recurringHelpSections,
);
