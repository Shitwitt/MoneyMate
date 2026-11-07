import 'package:flutter/material.dart';

/// The complete registry of icons Paisa persists.
///
/// Categories and accounts store an icon `codePoint` (an `int`) in Hive because
/// `IconData` — and even `IconData(codePoint, fontFamily: ...)` — cannot be
/// constructed safely in a release build: the icon tree-shaker would drop the
/// glyph. Every icon the app can persist is therefore declared here as an
/// `IconData` constant, and lookups go through [byCodePoint], which resolves to
/// a constant instance. Unresolved values fall back to a generic icon.
class ICONS {
  const ICONS._();

  /// Ordered map of stable keys → icons, used by the icon pickers.
  static const Map<String, IconData> all = <String, IconData>{
    // Food & drink
    'restaurant': Icons.restaurant_rounded,
    'fastfood': Icons.fastfood_rounded,
    'coffee': Icons.local_cafe_rounded,
    'cake': Icons.cake_rounded,
    'icecream': Icons.icecream_rounded,
    'lunch': Icons.lunch_dining_rounded,
    'breakfast': Icons.breakfast_dining_rounded,
    'drink': Icons.local_bar_rounded,
    'grocery': Icons.shopping_basket_rounded,
    'cart': Icons.shopping_cart_rounded,

    // Shopping
    'bag': Icons.shopping_bag_rounded,
    'store': Icons.storefront_rounded,
    'localmall': Icons.local_mall_rounded,
    'discount': Icons.local_offer_rounded,
    'dress': Icons.checkroom_rounded,

    // Transport
    'car': Icons.directions_car_filled_rounded,
    'bike': Icons.two_wheeler_rounded,
    'bus': Icons.directions_bus_rounded,
    'train': Icons.train_rounded,
    'flight': Icons.flight_takeoff_rounded,
    'ship': Icons.directions_boat_filled_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'taxi': Icons.local_taxi_rounded,
    'auto': Icons.electric_rickshaw_rounded,
    'toll': Icons.toll_rounded,
    'parking': Icons.local_parking_rounded,

    // Home & bills
    'home': Icons.home_rounded,
    'apartment': Icons.apartment_rounded,
    'bolt': Icons.bolt_rounded,
    'water': Icons.water_drop_rounded,
    'gas': Icons.propane_tank_rounded,
    'wifi': Icons.wifi_rounded,
    'phone': Icons.phone_android_rounded,
    'receipt': Icons.receipt_long_rounded,
    'receiptalt': Icons.receipt_rounded,
    'calendar': Icons.calendar_month_rounded,
    'tools': Icons.handyman_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'cleaning': Icons.cleaning_services_rounded,

    // Health
    'heart': Icons.favorite_rounded,
    'hospital': Icons.local_hospital_rounded,
    'medicine': Icons.medication_rounded,
    'gym': Icons.fitness_center_rounded,
    'spa': Icons.spa_rounded,
    'doctor': Icons.medical_services_rounded,

    // People & family
    'family': Icons.family_restroom_rounded,
    'baby': Icons.child_friendly_rounded,
    'child': Icons.child_care_rounded,
    'pets': Icons.pets_rounded,
    'people': Icons.people_rounded,
    'person': Icons.person_rounded,
    'group': Icons.groups_rounded,

    // Learning & leisure
    'school': Icons.school_rounded,
    'book': Icons.menu_book_rounded,
    'library': Icons.local_library_rounded,
    'movie': Icons.movie_rounded,
    'music': Icons.music_note_rounded,
    'game': Icons.sports_esports_rounded,
    'sports': Icons.sports_cricket_rounded,
    'travel': Icons.luggage_rounded,
    'party': Icons.celebration_rounded,
    'gift': Icons.card_giftcard_rounded,
    'ticket': Icons.confirmation_number_rounded,

    // Money & finance
    'wallet': Icons.account_balance_wallet_rounded,
    'bank': Icons.account_balance_rounded,
    'card': Icons.credit_card_rounded,
    'cash': Icons.payments_rounded,
    'savings': Icons.savings_rounded,
    'investment': Icons.trending_up_rounded,
    'stocks': Icons.show_chart_rounded,
    'gold': Icons.diamond_rounded,
    'loan': Icons.request_quote_rounded,
    'insurance': Icons.shield_rounded,
    'tax': Icons.percent_rounded,
    'rupee': Icons.currency_rupee_rounded,
    'charity': Icons.volunteer_activism_rounded,
    'work': Icons.work_rounded,
    'salary': Icons.paid_rounded,
    'refund': Icons.replay_rounded,
    'transfer': Icons.swap_horiz_rounded,

    // Misc
    'star': Icons.star_rounded,
    'flag': Icons.flag_rounded,
    'category': Icons.category_rounded,
    'other': Icons.more_horiz_rounded,
  };

  /// Icons shown by default in the category icon picker.
  static const List<String> categoryIconKeys = <String>[
    'restaurant',
    'fastfood',
    'coffee',
    'grocery',
    'cart',
    'bag',
    'dress',
    'car',
    'bike',
    'bus',
    'train',
    'flight',
    'fuel',
    'taxi',
    'home',
    'apartment',
    'bolt',
    'water',
    'gas',
    'wifi',
    'phone',
    'receipt',
    'tools',
    'heart',
    'hospital',
    'medicine',
    'gym',
    'school',
    'book',
    'movie',
    'music',
    'game',
    'sports',
    'travel',
    'party',
    'gift',
    'pets',
    'baby',
    'family',
    'charity',
    'investment',
    'savings',
    'insurance',
    'salary',
    'refund',
    'work',
    'star',
    'other',
  ];

  /// Accounts only ever use these four.
  static const List<String> accountIconKeys = <String>[
    'cash',
    'bank',
    'card',
    'wallet',
  ];

  /// Fallback icon for an unknown code point.
  static const IconData fallback = Icons.category_rounded;

  static final Map<int, IconData> _byCodePoint = <int, IconData>{
    for (final IconData icon in all.values) icon.codePoint: icon,
  };

  static final Map<int, String> _keyByCodePoint = <int, String>{
    for (final MapEntry<String, IconData> entry in all.entries)
      entry.value.codePoint: entry.key,
  };

  /// Resolves a persisted code point to a constant [IconData].
  static IconData byCodePoint(int? codePoint) {
    if (codePoint == null) return fallback;
    return _byCodePoint[codePoint] ?? fallback;
  }

  /// Resolves a persisted code point to its registry key, if known.
  static String? keyForCodePoint(int? codePoint) {
    if (codePoint == null) return null;
    return _keyByCodePoint[codePoint];
  }

  /// Resolves a registry key, defaulting to [fallback].
  static IconData byKey(String? key) => all[key] ?? fallback;

  /// Code point for a registry key, defaulting to [fallback]'s code point.
  static int codePointForKey(String? key) => (all[key] ?? fallback).codePoint;
}
