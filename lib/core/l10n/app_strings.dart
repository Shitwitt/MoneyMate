import 'package:flutter/material.dart';

/// A shipped UI language.
@immutable
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.icon,
  });

  /// BCP-47 primary subtag, e.g. `hi`.
  final String code;

  /// English label, e.g. `Hindi`.
  final String englishName;

  /// Native label shown in the picker, e.g. `हिन्दी`.
  final String nativeName;

  /// Flag-ish glyph used in the selector (an emoji, never an asset).
  final String icon;

  static const List<AppLanguage> all = <AppLanguage>[
    AppLanguage(code: 'en', englishName: 'English', nativeName: 'English', icon: '🇬🇧'),
    AppLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी', icon: '🇮🇳'),
    AppLanguage(code: 'de', englishName: 'German', nativeName: 'Deutsch', icon: '🇩🇪'),
    AppLanguage(code: 'es', englishName: 'Spanish', nativeName: 'Español', icon: '🇪🇸'),
    AppLanguage(code: 'fr', englishName: 'French', nativeName: 'Français', icon: '🇫🇷'),
  ];

  static AppLanguage byCode(String? code) {
    if (code == null) return all.first;
    for (final AppLanguage language in all) {
      if (language.code == code) return language;
    }
    return all.first;
  }

  /// The locale handed to `MaterialApp` (and therefore to `intl`).
  Locale get locale => Locale(code);
}

/// A tiny, dependency-free localized string table.
///
/// Paisa ships five languages for the onboarding/intro surface and the app's
/// core vocabulary. Unknown keys fall back to English, and unknown languages
/// fall back to the English value too, so the UI can never render `null` or a
/// raw key.
class AppStrings {
  const AppStrings._();

  static const Map<String, Map<String, String>> _table =
      <String, Map<String, String>>{
    // ---------------------------------------------------------------
    // English (also the fallback for every missing key)
    // ---------------------------------------------------------------
    'en': <String, String>{
      'appTitle': 'MoneyMate',
      'onboardingSkip': 'Skip',
      'onboardingNext': 'Continue',
      'onboardingBack': 'Back',
      'onboardingDone': 'Get started',
      'welcomeTitle': 'Know where every rupee goes',
      'welcomeSubtitle':
          'Track spending, plan budgets and stay on top of loans — all offline, all private.',
      'chooseLanguage': 'Choose your language',
      'featureOffline': 'Works fully offline',
      'featurePrivate': 'No account, no tracking',
      'featureInsights': 'Budgets & clear insights',
      'profileTitle': 'What should we call you?',
      'profileName': 'Your name',
      'profileNameHint': 'e.g. Hemanth',
      'chooseAvatar': 'Pick an avatar',
      'choosePhoto': 'Use a photo',
      'removePhoto': 'Remove photo',
      'accountsTitle': 'Add your accounts',
      'accountsSubtitle':
          'Tap the ones you use. You can add more any time.',
      'accountCash': 'Cash Wallet',
      'accountBank': 'Bank Account',
      'accountCard': 'Credit Card',
      'accountInitial': 'Opening balance',
      'categoriesTitle': 'What do you spend on?',
      'categoriesSubtitle': 'Pick the categories you want on your home screen.',
      'currencyTitle': 'Choose your currency',
      'currencySearch': 'Search 40+ currencies',
      'currencyFooter':
          'You can change this later in Settings.',
      'continueToApp': 'Open MoneyMate',
      'skipForNow': 'Skip for now',
      'step': 'Step',
      'of': 'of',
      'nameRequired': 'Please enter your name',
      'nameTooLong': 'Name is too long',
      'accountRequired': 'Select at least one account',
      'categoryRequired': 'Select at least one category',
      'done': 'Done',
      'cancel': 'Cancel',
      'today': 'Today',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'thisYear': 'This Year',
      'allTime': 'All Time',
      'income': 'Income',
      'expense': 'Expense',
      'transfer': 'Transfer',
      'balance': 'Balance',
      'budget': 'Budget',
      'remaining': 'Remaining',
    },

    // ---------------------------------------------------------------
    // हिन्दी
    // ---------------------------------------------------------------
    'hi': <String, String>{
      'appTitle': 'मनीमेट',
      'onboardingSkip': 'छोड़ें',
      'onboardingNext': 'आगे बढ़ें',
      'onboardingBack': 'वापस',
      'onboardingDone': 'शुरू करें',
      'welcomeTitle': 'हर रुपये का हिसाब',
      'welcomeSubtitle':
          'खर्च ट्रैक करें, बजट बनाएँ और कर्ज़ पर नियंत्रण रखें — पूरी तरह ऑफ़लाइन।',
      'chooseLanguage': 'अपनी भाषा चुनें',
      'featureOffline': 'पूरी तरह ऑफ़लाइन',
      'featurePrivate': 'कोई अकाउंट नहीं, कोई ट्रैकिंग नहीं',
      'featureInsights': 'बजट और स्पष्ट जानकारी',
      'profileTitle': 'हम आपको क्या कहें?',
      'profileName': 'आपका नाम',
      'profileNameHint': 'जैसे हेमंत',
      'chooseAvatar': 'अवतार चुनें',
      'choosePhoto': 'फ़ोटो लगाएँ',
      'removePhoto': 'फ़ोटो हटाएँ',
      'accountsTitle': 'अपने अकाउंट जोड़ें',
      'accountsSubtitle': 'जो इस्तेमाल करते हैं उन्हें चुनें। बाद में जोड़ सकते हैं।',
      'accountCash': 'नकद वॉलेट',
      'accountBank': 'बैंक खाता',
      'accountCard': 'क्रेडिट कार्ड',
      'accountInitial': 'शुरुआती बैलेंस',
      'categoriesTitle': 'आप किन चीज़ों पर खर्च करते हैं?',
      'categoriesSubtitle': 'जो श्रेणियाँ होम स्क्रीन पर चाहिए उन्हें चुनें।',
      'currencyTitle': 'अपनी मुद्रा चुनें',
      'currencySearch': '40+ मुद्राएँ खोजें',
      'currencyFooter': 'इसे बाद में सेटिंग्स में बदल सकते हैं।',
      'continueToApp': 'मनीमेट खोलें',
      'skipForNow': 'अभी छोड़ें',
      'step': 'चरण',
      'of': 'में से',
      'nameRequired': 'कृपया अपना नाम दर्ज करें',
      'nameTooLong': 'नाम बहुत लंबा है',
      'accountRequired': 'कम से कम एक अकाउंट चुनें',
      'categoryRequired': 'कम से कम एक श्रेणी चुनें',
      'done': 'हो गया',
      'cancel': 'रद्द करें',
      'today': 'आज',
      'thisWeek': 'इस सप्ताह',
      'thisMonth': 'इस महीने',
      'thisYear': 'इस वर्ष',
      'allTime': 'सभी समय',
      'income': 'आय',
      'expense': 'खर्च',
      'transfer': 'स्थानांतरण',
      'balance': 'बैलेंस',
      'budget': 'बजट',
      'remaining': 'शेष',
    },

    // ---------------------------------------------------------------
    // Deutsch
    // ---------------------------------------------------------------
    'de': <String, String>{
      'appTitle': 'MoneyMate',
      'onboardingSkip': 'Überspringen',
      'onboardingNext': 'Weiter',
      'onboardingBack': 'Zurück',
      'onboardingDone': 'Los geht’s',
      'welcomeTitle': 'Wisse, wohin jeder Euro fließt',
      'welcomeSubtitle':
          'Ausgaben verfolgen, Budgets planen und Kredite im Blick behalten — komplett offline.',
      'chooseLanguage': 'Sprache wählen',
      'featureOffline': 'Vollständig offline',
      'featurePrivate': 'Kein Konto, kein Tracking',
      'featureInsights': 'Budgets & klare Einblicke',
      'profileTitle': 'Wie sollen wir dich nennen?',
      'profileName': 'Dein Name',
      'profileNameHint': 'z. B. Hemanth',
      'chooseAvatar': 'Avatar wählen',
      'choosePhoto': 'Foto verwenden',
      'removePhoto': 'Foto entfernen',
      'accountsTitle': 'Konten hinzufügen',
      'accountsSubtitle': 'Tippe die genutzten an. Weitere sind jederzeit möglich.',
      'accountCash': 'Bargeld',
      'accountBank': 'Bankkonto',
      'accountCard': 'Kreditkarte',
      'accountInitial': 'Anfangssaldo',
      'categoriesTitle': 'Wofür gibst du Geld aus?',
      'categoriesSubtitle': 'Wähle die Kategorien für deinen Startbildschirm.',
      'currencyTitle': 'Währung wählen',
      'currencySearch': 'Über 40 Währungen durchsuchen',
      'currencyFooter': 'Du kannst das später in den Einstellungen ändern.',
      'continueToApp': 'MoneyMate öffnen',
      'skipForNow': 'Vorerst überspringen',
      'step': 'Schritt',
      'of': 'von',
      'nameRequired': 'Bitte gib deinen Namen ein',
      'nameTooLong': 'Name ist zu lang',
      'accountRequired': 'Wähle mindestens ein Konto',
      'categoryRequired': 'Wähle mindestens eine Kategorie',
      'done': 'Fertig',
      'cancel': 'Abbrechen',
      'today': 'Heute',
      'thisWeek': 'Diese Woche',
      'thisMonth': 'Dieser Monat',
      'thisYear': 'Dieses Jahr',
      'allTime': 'Gesamt',
      'income': 'Einnahmen',
      'expense': 'Ausgaben',
      'transfer': 'Übertrag',
      'balance': 'Saldo',
      'budget': 'Budget',
      'remaining': 'Verbleibend',
    },

    // ---------------------------------------------------------------
    // Español
    // ---------------------------------------------------------------
    'es': <String, String>{
      'appTitle': 'MoneyMate',
      'onboardingSkip': 'Omitir',
      'onboardingNext': 'Continuar',
      'onboardingBack': 'Atrás',
      'onboardingDone': 'Empezar',
      'welcomeTitle': 'Sabes a dónde va cada euro',
      'welcomeSubtitle':
          'Controla gastos, planifica presupuestos y vigila tus préstamos — todo sin conexión.',
      'chooseLanguage': 'Elige tu idioma',
      'featureOffline': 'Funciona sin conexión',
      'featurePrivate': 'Sin cuenta, sin rastreo',
      'featureInsights': 'Presupuestos e información clara',
      'profileTitle': '¿Cómo te llamamos?',
      'profileName': 'Tu nombre',
      'profileNameHint': 'p. ej. Hemanth',
      'chooseAvatar': 'Elige un avatar',
      'choosePhoto': 'Usar una foto',
      'removePhoto': 'Quitar foto',
      'accountsTitle': 'Añade tus cuentas',
      'accountsSubtitle': 'Toca las que uses. Puedes añadir más cuando quieras.',
      'accountCash': 'Efectivo',
      'accountBank': 'Cuenta bancaria',
      'accountCard': 'Tarjeta de crédito',
      'accountInitial': 'Saldo inicial',
      'categoriesTitle': '¿En qué gastas?',
      'categoriesSubtitle': 'Elige las categorías para tu pantalla de inicio.',
      'currencyTitle': 'Elige tu moneda',
      'currencySearch': 'Buscar entre más de 40 monedas',
      'currencyFooter': 'Puedes cambiarlo luego en Ajustes.',
      'continueToApp': 'Abrir MoneyMate',
      'skipForNow': 'Omitir por ahora',
      'step': 'Paso',
      'of': 'de',
      'nameRequired': 'Introduce tu nombre',
      'nameTooLong': 'El nombre es demasiado largo',
      'accountRequired': 'Selecciona al menos una cuenta',
      'categoryRequired': 'Selecciona al menos una categoría',
      'done': 'Listo',
      'cancel': 'Cancelar',
      'today': 'Hoy',
      'thisWeek': 'Esta semana',
      'thisMonth': 'Este mes',
      'thisYear': 'Este año',
      'allTime': 'Todo',
      'income': 'Ingresos',
      'expense': 'Gastos',
      'transfer': 'Transferencia',
      'balance': 'Saldo',
      'budget': 'Presupuesto',
      'remaining': 'Restante',
    },

    // ---------------------------------------------------------------
    // Français
    // ---------------------------------------------------------------
    'fr': <String, String>{
      'appTitle': 'MoneyMate',
      'onboardingSkip': 'Passer',
      'onboardingNext': 'Continuer',
      'onboardingBack': 'Retour',
      'onboardingDone': 'Commencer',
      'welcomeTitle': 'Sachez où va chaque euro',
      'welcomeSubtitle':
          'Suivez vos dépenses, planifiez vos budgets et gardez un œil sur vos prêts — hors ligne.',
      'chooseLanguage': 'Choisissez votre langue',
      'featureOffline': 'Fonctionne hors ligne',
      'featurePrivate': 'Sans compte, sans pistage',
      'featureInsights': 'Budgets et analyses claires',
      'profileTitle': 'Comment vous appelez-vous ?',
      'profileName': 'Votre nom',
      'profileNameHint': 'ex. Hemanth',
      'chooseAvatar': 'Choisissez un avatar',
      'choosePhoto': 'Utiliser une photo',
      'removePhoto': 'Retirer la photo',
      'accountsTitle': 'Ajoutez vos comptes',
      'accountsSubtitle': 'Touchez ceux que vous utilisez. Vous pourrez en ajouter.',
      'accountCash': 'Espèces',
      'accountBank': 'Compte bancaire',
      'accountCard': 'Carte de crédit',
      'accountInitial': 'Solde initial',
      'categoriesTitle': 'Pour quoi dépensez-vous ?',
      'categoriesSubtitle': 'Choisissez les catégories de votre écran d’accueil.',
      'currencyTitle': 'Choisissez votre devise',
      'currencySearch': 'Rechercher parmi plus de 40 devises',
      'currencyFooter': 'Vous pourrez le changer dans les Réglages.',
      'continueToApp': 'Ouvrir MoneyMate',
      'skipForNow': 'Passer pour l’instant',
      'step': 'Étape',
      'of': 'sur',
      'nameRequired': 'Veuillez saisir votre nom',
      'nameTooLong': 'Le nom est trop long',
      'accountRequired': 'Sélectionnez au moins un compte',
      'categoryRequired': 'Sélectionnez au moins une catégorie',
      'done': 'Terminé',
      'cancel': 'Annuler',
      'today': 'Aujourd’hui',
      'thisWeek': 'Cette semaine',
      'thisMonth': 'Ce mois',
      'thisYear': 'Cette année',
      'allTime': 'Tout',
      'income': 'Revenus',
      'expense': 'Dépenses',
      'transfer': 'Virement',
      'balance': 'Solde',
      'budget': 'Budget',
      'remaining': 'Restant',
    },
  };

  /// Resolves [key] for [languageCode], falling back to English.
  static String of(String languageCode, String key) {
    final Map<String, String>? language = _table[languageCode];
    final String? value = language?[key];
    if (value != null) return value;
    return _table['en']![key] ?? key;
  }

  /// Whether a translation exists for [key] in [languageCode].
  static bool has(String languageCode, String key) =>
      _table[languageCode]?.containsKey(key) ?? false;

  /// Every key in the English table (used by tests to assert completeness).
  static List<String> get keys => _table['en']!.keys.toList(growable: false);

  /// Every shipped language code.
  static List<String> get languageCodes => _table.keys.toList(growable: false);
}

/// Convenience accessor wired through `BuildContext`.
///
/// The active language is pushed down the tree by `MoneyMateApp`, so widgets can
/// simply call `context.tr('welcomeTitle')`.
class TranslationScope extends InheritedWidget {
  const TranslationScope({
    super.key,
    required this.languageCode,
    required super.child,
  });

  final String languageCode;

  static String tr(BuildContext context, String key) {
    final TranslationScope? scope =
        context.dependOnInheritedWidgetOfExactType<TranslationScope>();
    return AppStrings.of(scope?.languageCode ?? 'en', key);
  }

  @override
  bool updateShouldNotify(TranslationScope oldWidget) =>
      oldWidget.languageCode != languageCode;
}

extension TranslationContext on BuildContext {
  /// Localized string for [key] in the active language.
  String tr(String key) => TranslationScope.tr(this, key);
}
