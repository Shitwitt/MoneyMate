/* ============================================================
   Lightweight, persisted multi-language engine.
   35+ selectable languages with translated core navigation,
   greetings and headers. Untranslated UI strings fall back to
   English rather than breaking the layout.
   ============================================================ */

export const CORE_KEYS = [
  'home', 'accounts', 'reports', 'search', 'budgets', 'loans', 'goals', 'assets',
  'settings', 'profile', 'greeting', 'totalBalance', 'income', 'expense', 'new',
];

const META = [
  ['en', 'English', 'English', '🇺🇸', 'EN', 'ltr'],
  ['es', 'Spanish', 'Español', '🇪🇸', 'ES', 'ltr'],
  ['fr', 'French', 'Français', '🇫🇷', 'FR', 'ltr'],
  ['de', 'German', 'Deutsch', '🇩🇪', 'DE', 'ltr'],
  ['zh', 'Chinese', '中文', '🇨🇳', 'ZH', 'ltr'],
  ['ja', 'Japanese', '日本語', '🇯🇵', 'JA', 'ltr'],
  ['hi', 'Hindi', 'हिन्दी', '🇮🇳', 'HI', 'ltr'],
  ['ar', 'Arabic', 'العربية', '🇸🇦', 'AR', 'rtl'],
  ['pt', 'Portuguese', 'Português', '🇵🇹', 'PT', 'ltr'],
  ['ru', 'Russian', 'Русский', '🇷🇺', 'RU', 'ltr'],
  ['it', 'Italian', 'Italiano', '🇮🇹', 'IT', 'ltr'],
  ['ko', 'Korean', '한국어', '🇰🇷', 'KO', 'ltr'],
  ['tr', 'Turkish', 'Türkçe', '🇹🇷', 'TR', 'ltr'],
  ['nl', 'Dutch', 'Nederlands', '🇳🇱', 'NL', 'ltr'],
  ['pl', 'Polish', 'Polski', '🇵🇱', 'PL', 'ltr'],
  ['bn', 'Bengali', 'বাংলা', '🇧🇩', 'BN', 'ltr'],
  ['ta', 'Tamil', 'தமிழ்', '🇮🇳', 'TA', 'ltr'],
  ['te', 'Telugu', 'తెలుగు', '🇮🇳', 'TE', 'ltr'],
  ['mr', 'Marathi', 'मराठी', '🇮🇳', 'MR', 'ltr'],
  ['gu', 'Gujarati', 'ગુજરાતી', '🇮🇳', 'GU', 'ltr'],
  ['pa', 'Punjabi', 'ਪੰਜਾਬੀ', '🇮🇳', 'PA', 'ltr'],
  ['ur', 'Urdu', 'اردو', '🇵🇰', 'UR', 'rtl'],
  ['kn', 'Kannada', 'ಕನ್ನಡ', '🇮🇳', 'KN', 'ltr'],
  ['ml', 'Malayalam', 'മലയാളം', '🇮🇳', 'ML', 'ltr'],
  ['or', 'Odia', 'ଓଡ଼ିଆ', '🇮🇳', 'OR', 'ltr'],
  ['as', 'Assamese', 'অসমীয়া', '🇮🇳', 'AS', 'ltr'],
  ['id', 'Indonesian', 'Bahasa Indonesia', '🇮🇩', 'ID', 'ltr'],
  ['vi', 'Vietnamese', 'Tiếng Việt', '🇻🇳', 'VI', 'ltr'],
  ['th', 'Thai', 'ไทย', '🇹🇭', 'TH', 'ltr'],
  ['sv', 'Swedish', 'Svenska', '🇸🇪', 'SV', 'ltr'],
  ['no', 'Norwegian', 'Norsk', '🇳🇴', 'NO', 'ltr'],
  ['da', 'Danish', 'Dansk', '🇩🇰', 'DA', 'ltr'],
  ['fi', 'Finnish', 'Suomi', '🇫🇮', 'FI', 'ltr'],
  ['el', 'Greek', 'Ελληνικά', '🇬🇷', 'EL', 'ltr'],
  ['he', 'Hebrew', 'עברית', '🇮🇱', 'HE', 'rtl'],
];

const ROWS = {
  en: ['Home', 'Accounts', 'Reports', 'Search', 'Budgets', 'Loans', 'Goals', 'Assets', 'Settings', 'Profile', 'Good late night', 'Total balance', 'Income', 'Expense', 'New'],
  es: ['Inicio', 'Cuentas', 'Informes', 'Buscar', 'Presupuestos', 'Préstamos', 'Metas', 'Activos', 'Ajustes', 'Perfil', 'Buenas noches', 'Saldo total', 'Ingresos', 'Gastos', 'Nuevo'],
  fr: ['Accueil', 'Comptes', 'Rapports', 'Rechercher', 'Budgets', 'Prêts', 'Objectifs', 'Actifs', 'Paramètres', 'Profil', 'Bonne nuit', 'Solde total', 'Revenus', 'Dépenses', 'Nouveau'],
  de: ['Start', 'Konten', 'Berichte', 'Suchen', 'Budgets', 'Kredite', 'Ziele', 'Vermögen', 'Einstellungen', 'Profil', 'Gute späte Nacht', 'Gesamtsaldo', 'Einnahmen', 'Ausgaben', 'Neu'],
  zh: ['首页', '账户', '报表', '搜索', '预算', '贷款', '目标', '资产', '设置', '个人资料', '夜深了', '总余额', '收入', '支出', '新建'],
  ja: ['ホーム', '口座', 'レポート', '検索', '予算', 'ローン', '目標', '資産', '設定', 'プロフィール', '深夜おはよう', '残高合計', '収入', '支出', '新規'],
  hi: ['होम', 'खाते', 'रिपोर्ट', 'खोजें', 'बजट', 'ऋण', 'लक्ष्य', 'संपत्तियाँ', 'सेटिंग्स', 'प्रोफ़ाइल', 'देर रात शुभकामनाएँ', 'कुल शेष', 'आय', 'व्यय', 'नया'],
  ar: ['الرئيسية', 'الحسابات', 'التقارير', 'بحث', 'الميزانيات', 'القروض', 'الأهداف', 'الأصول', 'الإعدادات', 'الملف الشخصي', 'ليلة سعيدة', 'الرصيد الإجمالي', 'الدخل', 'المصروفات', 'جديد'],
  pt: ['Início', 'Contas', 'Relatórios', 'Pesquisar', 'Orçamentos', 'Empréstimos', 'Metas', 'Ativos', 'Configurações', 'Perfil', 'Boa noite', 'Saldo total', 'Receitas', 'Despesas', 'Novo'],
  ru: ['Главная', 'Счета', 'Отчёты', 'Поиск', 'Бюджеты', 'Кредиты', 'Цели', 'Активы', 'Настройки', 'Профиль', 'Доброй ночи', 'Общий баланс', 'Доходы', 'Расходы', 'Новый'],
  it: ['Home', 'Conti', 'Report', 'Cerca', 'Budget', 'Prestiti', 'Obiettivi', 'Attività', 'Impostazioni', 'Profilo', 'Buonanotte', 'Saldo totale', 'Entrate', 'Uscite', 'Nuovo'],
  ko: ['홈', '계정', '보고서', '검색', '예산', '대출', '목표', '자산', '설정', '프로필', '좋은 밤입니다', '총 잔액', '수입', '지출', '새로 만들기'],
  tr: ['Ana sayfa', 'Hesaplar', 'Raporlar', 'Ara', 'Bütçeler', 'Krediler', 'Hedefler', 'Varlıklar', 'Ayarlar', 'Profil', 'İyi geceler', 'Toplam bakiye', 'Gelir', 'Gider', 'Yeni'],
  nl: ['Start', 'Rekeningen', 'Rapporten', 'Zoeken', 'Budgetten', 'Leningen', 'Doelen', 'Bezittingen', 'Instellingen', 'Profiel', 'Goedenavond', 'Totaalsaldo', 'Inkomsten', 'Uitgaven', 'Nieuw'],
  pl: ['Start', 'Konta', 'Raporty', 'Szukaj', 'Budżety', 'Pożyczki', 'Cele', 'Aktywa', 'Ustawienia', 'Profil', 'Dobranoc', 'Saldo całkowite', 'Przychody', 'Wydatki', 'Nowy'],
  bn: ['হোম', 'অ্যাকাউন্ট', 'রিপোর্ট', 'খুঁজুন', 'বাজেট', 'ঋণ', 'লক্ষ্য', 'সম্পদ', 'সেটিংস', 'প্রোফাইল', 'শুভ রাত্রি', 'মোট ব্যালেন্স', 'আয়', 'ব্যয়', 'নতুন'],
  ta: ['முகப்பு', 'கணக்குகள்', 'அறிக்கைகள்', 'தேடல்', 'பட்ஜெட்டுகள்', 'கடன்கள்', 'இலக்குகள்', 'சொத்துகள்', 'அமைப்புகள்', 'சுயவிவரம்', 'வணக்கம்', 'மொத்த இருப்பு', 'வருமானம்', 'செலவு', 'புதியது'],
  te: ['హోమ్', 'ఖాతాలు', 'నివేదికలు', 'శోధన', 'బడ్జెట్లు', 'రుణాలు', 'లక్ష్యాలు', 'ఆస్తులు', 'సెట్టింగ్\u200cలు', 'ప్రొఫైల్', 'శుభ రాత్రి', 'మొత్తం బ్యాలెన్స్', 'ఆదాయం', 'ఖర్చు', 'కొత్తది'],
  mr: ['मुख्यपृष्ठ', 'खाती', 'अहवाल', 'शोधा', 'बजेट', 'कर्ज', 'उद्दिष्टे', 'मालमत्ता', 'सेटिंग्ज', 'प्रोफाइल', 'शुभ रात्र', 'एकूण शिल्लक', 'उत्पन्न', 'खर्च', 'नवीन'],
  gu: ['હોમ', 'ખાતાં', 'રિપોર્ટ', 'શોધો', 'બજેટ', 'લોન', 'લક્ષ્યો', 'સંપત્તિ', 'સેટિંગ્સ', 'પ્રોફાઇલ', 'શુભ રાત્રિ', 'કુલ બેલેન્સ', 'આવક', 'ખર્ચ', 'નવું'],
  pa: ['ਘਰ', 'ਖਾਤੇ', 'ਰਿਪੋਰਟਾਂ', 'ਖੋਜੋ', 'ਬਜਟ', 'ਕਰਜ਼ੇ', 'ਟੀਚੇ', 'ਸੰਪਤੀਆਂ', 'ਸੈਟਿੰਗਾਂ', 'ਪ੍ਰੋਫ਼ਾਈਲ', 'ਸ਼ੁਭ ਰਾਤ', 'ਕੁੱਲ ਬਕਾਇਆ', 'ਆਮਦਨ', 'ਖਰਚ', 'ਨਵਾਂ'],
  ur: ['ہوم', 'اکاؤنٹس', 'رپورٹس', 'تلاش', 'بجٹ', 'قرضے', 'اہداف', 'اثاثے', 'ترتیبات', 'پروفائل', 'شب بخیر', 'کل بیلنس', 'آمدنی', 'اخراجات', 'نیا'],
  kn: ['ಮುಖಪುಟ', 'ಖಾತೆಗಳು', 'ವರದಿಗಳು', 'ಹುಡುಕಿ', 'ಬಜೆಟ್\u200cಗಳು', 'ಸಾಲಗಳು', 'ಗುರಿಗಳು', 'ಆಸ್ತಿಗಳು', 'ಸೆಟ್ಟಿಂಗ್\u200cಗಳು', 'ಪ್ರೊಫೈಲ್', 'ಶುಭ ರಾತ್ರಿ', 'ಒಟ್ಟು ಬಾಕಿ', 'ಆದಾಯ', 'ಖರ್ಚು', 'ಹೊಸದು'],
  ml: ['ഹോം', 'അക്കൗണ്ടുകൾ', 'റിപ്പോർട്ടുകൾ', 'തിരയുക', 'ബഡ്ജറ്റുകൾ', 'വായ്പകൾ', 'ലക്ഷ്യങ്ങൾ', 'ആസ്തികൾ', 'ക്രമീകരണങ്ങൾ', 'പ്രൊഫൈൽ', 'ശുഭരാത്രി', 'മൊത്തം ബാലൻസ്', 'വരുമാനം', 'ചെലവ്', 'പുതിയത്'],
  or: ['ହୋମ', 'ଖାତା', 'ରିପୋର୍ଟ', 'ଖୋଜନ୍ତୁ', 'ବଜେଟ', 'ଋଣ', 'ଲକ୍ଷ୍ୟ', 'ସମ୍ପତ୍ତି', 'ସେଟିଂସ', 'ପ୍ରୋଫାଇଲ', 'ଶୁଭ ରାତ୍ରି', 'ମୋଟ ବାଲାନ୍ସ', 'ଆୟ', 'ଖର୍ଚ୍ଚ', 'ନୂଆ'],
  as: ['ঘৰ', 'একাউণ্ট', 'ৰিপ\'ৰ্ট', 'সন্ধান কৰক', 'বাজেট', 'ঋণ', 'লক্ষ্য', 'সম্পত্তি', 'ছেটিংছ', 'প্ৰ\'ফাইল', 'শুভ ৰাত্ৰি', 'মুঠ বেলেঞ্চ', 'আয়', 'ব্যয়', 'নতুন'],
  id: ['Beranda', 'Akun', 'Laporan', 'Cari', 'Anggaran', 'Pinjaman', 'Tujuan', 'Aset', 'Pengaturan', 'Profil', 'Selamat malam', 'Saldo total', 'Pendapatan', 'Pengeluaran', 'Baru'],
  vi: ['Trang chủ', 'Tài khoản', 'Báo cáo', 'Tìm kiếm', 'Ngân sách', 'Khoản vay', 'Mục tiêu', 'Tài sản', 'Cài đặt', 'Hồ sơ', 'Chúc ngủ ngon', 'Số dư tổng', 'Thu nhập', 'Chi tiêu', 'Mới'],
  th: ['หน้าแรก', 'บัญชี', 'รายงาน', 'ค้นหา', 'งบประมาณ', 'เงินกู้', 'เป้าหมาย', 'สินทรัพย์', 'การตั้งค่า', 'โปรไฟล์', 'ราตรีสวัสดิ์', 'ยอดคงเหลือรวม', 'รายได้', 'ค่าใช้จ่าย', 'ใหม่'],
  sv: ['Hem', 'Konton', 'Rapporter', 'Sök', 'Budgetar', 'Lån', 'Mål', 'Tillgångar', 'Inställningar', 'Profil', 'God natt', 'Totalt saldo', 'Inkomster', 'Utgifter', 'Ny'],
  no: ['Hjem', 'Kontoer', 'Rapporter', 'Søk', 'Budsjetter', 'Lån', 'Mål', 'Eiendeler', 'Innstillinger', 'Profil', 'God natt', 'Total saldo', 'Inntekter', 'Utgifter', 'Ny'],
  da: ['Hjem', 'Konti', 'Rapporter', 'Søg', 'Budgetter', 'Lån', 'Mål', 'Aktiver', 'Indstillinger', 'Profil', 'God nat', 'Samlet saldo', 'Indtægter', 'Udgifter', 'Ny'],
  fi: ['Etusivu', 'Tilit', 'Raportit', 'Haku', 'Budjetit', 'Lainat', 'Tavoitteet', 'Varat', 'Asetukset', 'Profiili', 'Hyvää yötä', 'Kokonaissaldo', 'Tulot', 'Menot', 'Uusi'],
  el: ['Αρχική', 'Λογαριασμοί', 'Αναφορές', 'Αναζήτηση', 'Προϋπολογισμοί', 'Δάνεια', 'Στόχοι', 'Περιουσιακά', 'Ρυθμίσεις', 'Προφίλ', 'Καληνύχτα', 'Συνολικό υπόλοιπο', 'Έσοδα', 'Έξοδα', 'Νέο'],
  he: ['בית', 'חשבונות', 'דוחות', 'חיפוש', 'תקציבים', 'הלוואות', 'יעדים', 'נכסים', 'הגדרות', 'פרופיל', 'לילה טוב', 'יתרה כוללת', 'הכנסות', 'הוצאות', 'חדש'],
};

const CORE = Object.fromEntries(Object.entries(ROWS).map(([code, row]) => [
  code,
  Object.fromEntries(CORE_KEYS.map((key, i) => [key, row[i]])),
]));

const EXTRA = {
  en: {
    personalize: 'Personalize your profile', backup: 'Backup', recurring: 'recurring',
    overview: 'Overview', templates: 'Templates', trend: 'Trend', upcoming: 'Upcoming transactions',
    trackBudgets: 'Track budgets', next: 'Next', finishSetup: 'Finish setup',
    whatShouldWeCallYou: 'What should we call you?', selectCurrency: 'Select your currency',
    welcome: 'Welcome to Paisa', language: 'Language', theme: 'Theme', startFresh: 'Start fresh', exportBackup: 'Export local backup',
    restoreBackup: 'Restore local backup', replayTour: 'Replay onboarding tour', resetData: 'Reset app data',
  },
  hi: { personalize: 'अपनी प्रोफ़ाइल निजीकृत करें', backup: 'बैकअप', recurring: 'आवर्ती', overview: 'सारांश', templates: 'टेम्पलेट', trend: 'रुझान', upcoming: 'आगामी लेनदेन', trackBudgets: 'बजट ट्रैक करें', next: 'आगे', finishSetup: 'सेटअप पूरा करें', whatShouldWeCallYou: 'हम आपको क्या कहें?', selectCurrency: 'अपनी मुद्रा चुनें', welcome: 'पैसा में आपका स्वागत है', language: 'भाषा', theme: 'थीम', startFresh: 'नए सिरे से शुरू करें', exportBackup: 'स्थानीय बैकअप निर्यात करें', restoreBackup: 'स्थानीय बैकअप बहाल करें', replayTour: 'ऑनबोर्डिंग टूर दोहराएँ', resetData: 'ऐप डेटा रीसेट करें' },
  pa: { personalize: 'ਆਪਣੀ ਪ੍ਰੋਫ਼ਾਈਲ ਨਿੱਜੀ ਬਣਾਓ', backup: 'ਬੈਕਅੱਪ', recurring: 'ਆਵਰਤੀ', overview: 'ਸਾਰਾਂਸ਼', templates: 'ਟੈਮਪਲੇਟ', trend: 'ਰੁਝਾਨ', upcoming: 'ਆਉਣ ਵਾਲੇ ਲੈਣ-ਦੇਣ', trackBudgets: 'ਬਜਟ ਟਰੈਕ ਕਰੋ', next: 'ਅੱਗੇ', finishSetup: 'ਸੈੱਟਅੱਪ ਪੂਰਾ ਕਰੋ', whatShouldWeCallYou: 'ਅਸੀਂ ਤੁਹਾਨੂੰ ਕੀ ਕਹੀਏ?', selectCurrency: 'ਆਪਣੀ ਮੁਦਰਾ ਚੁਣੋ', welcome: 'ਪੈਸਾ ਵਿੱਚ ਜੀ ਆਇਆਂ ਨੂੰ', language: 'ਭਾਸ਼ਾ', theme: 'ਥੀਮ', startFresh: 'ਨਵੇਂ ਸਿਰੇ ਤੋਂ ਸ਼ੁਰੂ ਕਰੋ', exportBackup: 'ਲੋਕਲ ਬੈਕਅੱਪ ਐਕਸਪੋਰਟ ਕਰੋ', restoreBackup: 'ਲੋਕਲ ਬੈਕਅੱਪ ਬਹਾਲ ਕਰੋ', replayTour: 'ਆਨਬੋਰਡਿੰਗ ਟੂਰ ਦੁਬਾਰਾ ਚਲਾਓ', resetData: 'ਐਪ ਡਾਟਾ ਰੀਸੈੱਟ ਕਰੋ' },
  de: { personalize: 'Profil anpassen', backup: 'Sicherung', recurring: 'wiederkehrend', overview: 'Übersicht', templates: 'Vorlagen', trend: 'Trend', upcoming: 'Anstehende Transaktionen', trackBudgets: 'Budgets verfolgen', next: 'Weiter', finishSetup: 'Einrichtung abschließen', whatShouldWeCallYou: 'Wie sollen wir dich nennen?', selectCurrency: 'Währung auswählen', welcome: 'Willkommen bei Paisa', language: 'Sprache', theme: 'Design', exportBackup: 'Lokale Sicherung exportieren', restoreBackup: 'Lokale Sicherung wiederherstellen', replayTour: 'Einführung erneut ansehen', resetData: 'App-Daten zurücksetzen' },
  es: { personalize: 'Personaliza tu perfil', backup: 'Copia', recurring: 'recurrentes', overview: 'Resumen', templates: 'Plantillas', trend: 'Tendencia', upcoming: 'Próximas transacciones', trackBudgets: 'Seguir presupuestos', next: 'Siguiente', finishSetup: 'Finalizar configuración', whatShouldWeCallYou: '¿Cómo te llamamos?', selectCurrency: 'Selecciona tu moneda', welcome: 'Bienvenido a Paisa', language: 'Idioma', theme: 'Tema', exportBackup: 'Exportar copia local', restoreBackup: 'Restaurar copia local', replayTour: 'Repetir tour inicial', resetData: 'Restablecer datos' },
  fr: { personalize: 'Personnaliser le profil', backup: 'Sauvegarde', recurring: 'récurrents', overview: 'Aperçu', templates: 'Modèles', trend: 'Tendance', upcoming: 'Transactions à venir', trackBudgets: 'Suivre les budgets', next: 'Suivant', finishSetup: 'Terminer la configuration', whatShouldWeCallYou: 'Comment vous appeler ?', selectCurrency: 'Choisir votre devise', welcome: 'Bienvenue sur Paisa', language: 'Langue', theme: 'Thème', exportBackup: 'Exporter la sauvegarde locale', restoreBackup: 'Restaurer la sauvegarde locale', replayTour: 'Revoir la présentation', resetData: 'Réinitialiser les données' },
  ar: { personalize: 'تخصيص ملفك', backup: 'نسخة احتياطية', recurring: 'متكرر', overview: 'نظرة عامة', templates: 'القوالب', trend: 'الاتجاه', upcoming: 'المعاملات القادمة', trackBudgets: 'تتبع الميزانيات', next: 'التالي', finishSetup: 'إنهاء الإعداد', whatShouldWeCallYou: 'ماذا نناديك؟', selectCurrency: 'اختر عملتك', welcome: 'مرحبًا بك في بايسا', language: 'اللغة', theme: 'المظهر', exportBackup: 'تصدير نسخة محلية', restoreBackup: 'استعادة نسخة محلية', replayTour: 'إعادة عرض الجولة', resetData: 'إعادة تعيين البيانات' },
};

const ALIASES = {
  Home: 'home', Accounts: 'accounts', Reports: 'reports', Search: 'search', Budgets: 'budgets',
  Loans: 'loans', Goals: 'goals', Assets: 'assets', Settings: 'settings', Profile: 'profile',
  'Good late night': 'greeting', 'Total balance': 'totalBalance', Income: 'income', Expense: 'expense', New: 'new',
  Overview: 'overview', Templates: 'templates', Trend: 'trend',
  'Upcoming transactions': 'upcoming', 'Track budgets': 'trackBudgets',
  'Personalize your profile': 'personalize', Backup: 'backup', recurring: 'recurring',
  Next: 'next', 'Finish setup': 'finishSetup',
  'What should we call you?': 'whatShouldWeCallYou', 'Select your currency': 'selectCurrency',
  'Welcome to Paisa': 'welcome', Language: 'language', Theme: 'theme',
  'Export local backup': 'exportBackup', 'Restore local backup': 'restoreBackup',
  'Replay onboarding tour': 'replayTour', 'Reset app data': 'resetData',
  'Start fresh': 'startFresh',
};

export const LANGUAGES = META.map(([code, name, native, flag, short, dir]) => ({
  code, name, native, flag, short, dir,
}));

export const LANGUAGE_BY_CODE = Object.fromEntries(LANGUAGES.map((l) => [l.code, l]));
export const FEATURED_LANGUAGE_CODES = ['en', 'es', 'fr', 'de', 'zh', 'ja', 'hi', 'ar', 'pt', 'ru', 'it'];
export const FEATURED_LANGUAGES = FEATURED_LANGUAGE_CODES.map((c) => LANGUAGE_BY_CODE[c]);
export const MORE_LANGUAGES = LANGUAGES.filter((l) => !FEATURED_LANGUAGE_CODES.includes(l.code));

export function languageById(code) {
  return LANGUAGE_BY_CODE[code] || LANGUAGE_BY_CODE.en;
}

export function languageBadge(code = 'en') {
  const l = languageById(code);
  return `${l.flag} ${l.short}`;
}

export function t(key, language = 'en', fallback) {
  const code = LANGUAGE_BY_CODE[language] ? language : 'en';
  const normalized = ALIASES[key] || key;
  const value = EXTRA[code]?.[normalized] || EXTRA.en[normalized]
    || CORE[code]?.[normalized] || CORE.en[normalized];
  return value || fallback || key;
}

export function searchLanguages(query = '') {
  const q = String(query).trim().toLowerCase();
  if (!q) return LANGUAGES;
  return LANGUAGES.filter((l) => [l.name, l.native, l.code, l.short].some((v) => String(v).toLowerCase().includes(q)));
}

export function languageDirection(code = 'en') {
  return languageById(code).dir;
}
