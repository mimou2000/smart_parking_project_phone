import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ════════════════════════════════════════════
//  AppLocale — إدارة لغة التطبيق
//  يدعم: العربية / الفرنسية / الإنجليزية
// ════════════════════════════════════════════
class AppLocale {
  AppLocale._();

  static const String _prefsKey = 'app_language';

  // اللغات المدعومة
  static const List<Locale> supported = [
    Locale('ar'),
    Locale('fr'),
    Locale('en'),
  ];

  // اللغة الافتراضية
  static const Locale _defaultLocale = Locale('ar');

  // Notifier لإعادة بناء الواجهة عند تغيير اللغة
  static final ValueNotifier<Locale> notifier =
      ValueNotifier<Locale>(_defaultLocale);

  static Locale get current => notifier.value;

  // اتجاه النص بحسب اللغة الحالية
  static TextDirection get textDirection =>
      current.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  static bool get isRtl => current.languageCode == 'ar';

  // تحميل اللغة المحفوظة من التخزين المحلي
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && _isSupported(code)) {
        notifier.value = Locale(code);
      }
    } catch (_) {
      // تجاهل أي خطأ والإبقاء على اللغة الافتراضية
    }
  }

  // تغيير اللغة وحفظها
  static Future<void> setLanguage(String code) async {
    if (!_isSupported(code)) return;
    notifier.value = Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, code);
    } catch (_) {}
  }

  static bool _isSupported(String code) =>
      supported.any((l) => l.languageCode == code);

  // اسم اللغة المعروض
  static String languageName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  // علم اللغة (إيموجي)
  static String languageFlag(String code) {
    switch (code) {
      case 'ar':
        return '🇸🇦';
      case 'fr':
        return '🇫🇷';
      case 'en':
        return '🇬🇧';
      default:
        return '';
    }
  }
}

// ════════════════════════════════════════════
//  دالة الترجمة tr(key)
//  ترجع النص حسب اللغة الحالية
// ════════════════════════════════════════════
String tr(String key) {
  final code = AppLocale.current.languageCode;
  final map = _translations[code] ?? _translations['ar']!;
  return map[key] ?? _translations['ar']?[key] ?? key;
}

// ════════════════════════════════════════════
//  قاموس الترجمات الكامل
// ════════════════════════════════════════════
const Map<String, Map<String, String>> _translations = {
  // ─────────── العربية ───────────
  'ar': {
    // عام
    'app_name': 'SmartParking',
    'app_subtitle': 'نظام الإدارة الذكي',
    'ok': 'موافق',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'edit': 'تعديل الملف الشخصي',
    'delete': 'حذف',
    'confirm': 'تأكيد',
    'yes': 'نعم',
    'no': 'لا',
    'close': 'إغلاق',
    'back': 'رجوع',
    'retry': 'إعادة المحاولة',
    'loading': 'جاري التحميل...',
    'currency': 'دج',
    'verified_account': 'حساب موثّق',

    // التنقل
    'nav_search': 'البحث',
    'nav_bookings': 'الحجوزات',
    'nav_profile': 'الملف',

    // الملف الشخصي
    'profile_title': 'ملفي الشخصي',
    'profile_ratings': 'التقييمات',
    'profile_settings': 'الإعدادات',
    'profile_security': 'الأمان وكلمة المرور',
    'profile_help': 'المساعدة',
    'profile_logout': 'تسجيل الخروج',
    'register_plate': 'تسجيل اللوحة',
    'my_vehicle': 'مركبتي',
    'stat_bookings': 'حجوزات',
    'stat_paid': 'مدفوع',
    'stat_total': 'إجمالي',
    'edit_profile_title': 'تعديل الملف الشخصي',
    'edit_vehicle_title': 'تعديل بيانات المركبة',
    'name_label': 'الاسم',
    'plate_label': 'رقم اللوحة',
    'vehicle_type_label': 'نوع المركبة',
    'help_title': 'مساعدة',
    'help_body':
        'مرحباً بك في SmartParking!\n\n• البحث: ابحث عن أقرب موقف وفلتر النتائج.\n• الحجز: اختر منطقة وموقفاً ونوع الحجز ثم ادفع.\n• الحجوزات: عرض كل حجوزاتك الحالية والسابقة.\n• الإعدادات: غيّر اللغة والإعدادات.\n\nلأي سؤال تواصل مع الدعم.',

    // أنواع المركبات
    'vehicle_standard': 'سيارة عادية',
    'vehicle_vip': 'سيارة فاخرة',
    'vehicle_motorcycle': 'دراجة نارية',
    'vehicle_electric': 'سيارة كهربائية',
    'vehicle_disabled': 'ذوي الاحتياجات الخاصة',

    // تسجيل الدخول
    'login_welcome': 'مرحبا بك',
    'login_subtitle': 'سجّل دخولك للوصول إلى التطبيق',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'forgot_password': 'نسيت كلمة المرور؟',
    'remember_me': 'تذكّرني',
    'login_btn': 'تسجيل الدخول',
    'logging_in': 'جاري التحقق...',
    'demo_fill': 'اضغط لتعبئة بيانات التجربة',
    'signup_link': 'إنشاء حساب جديد',
    'no_account': 'ليس لديك حساب؟',
    'forgot_dialog_title': 'استعادة كلمة المرور',
    'forgot_dialog_hint': 'أدخل بريدك الإلكتروني',
    'send_btn': 'إرسال',
    'reset_sent': 'تم إرسال رابط الاستعادة — تحقق من بريدك',
    'err_fill_all': 'يرجى تعبئة جميع الحقول',
    'err_invalid_creds': 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
    'err_user_not_found': 'لا يوجد حساب بهذا البريد الإلكتروني',
    'err_too_many': 'محاولات كثيرة، حاول لاحقاً',
    'err_network': 'تحقق من اتصالك بالإنترنت',
    'err_generic': 'حدث خطأ، حاول مجدداً',

    // إنشاء حساب
    'register_title': 'إنشاء حساب جديد',
    'register_subtitle': 'أدخل بياناتك للانضمام إلى المنصة',
    'personal_info': 'المعلومات الشخصية',
    'vehicle_info': 'معلومات السيارة',
    'full_name': 'الاسم الكامل',
    'name_hint': 'محمد أحمد',
    'confirm_password': 'تأكيد كلمة المرور',
    'plate_number': 'رقم لوحة السيارة',
    'plate_hint': '123 ABC',
    'car_brand': 'ماركة السيارة',
    'car_brand_hint': 'ابحث... Toyota, BMW, Mercedes',
    'car_model': 'طراز السيارة',
    'choose_brand_first': 'اختر الماركة أولاً',
    'search_model_hint': 'ابحث عن الطراز...',
    'create_account_btn': 'إنشاء الحساب',
    'creating_account': 'جاري إنشاء الحساب...',
    'login_link': 'تسجيل الدخول',
    'has_account': 'لديك حساب بالفعل؟',
    'err_passwords_no_match': 'كلمتا المرور غير متطابقتين',
    'err_password_short': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
    'err_email_in_use': 'هذا البريد مسجّل مسبقاً',
    'err_invalid_email': 'صيغة البريد الإلكتروني غير صحيحة',
    'err_weak_password': 'كلمة المرور ضعيفة جداً',

    // الحجوزات
    'bookings_title': 'حجوزاتي',
    'bookings_active': 'نشطة',
    'bookings_completed': 'مكتملة',
    'bookings_cancelled': 'ملغاة',
    'bookings_count': 'حجز',
    'bookings_empty': 'لا توجد حجوزات في هذه الفئة',
    'bookings_error': 'خطأ في تحميل الحجوزات',
    'status_active': 'نشط',
    'status_completed': 'مكتمل',
    'status_cancelled': 'ملغي',
    'spot_label': 'موقف',
    'cancel_booking': 'إلغاء الحجز',
    'navigate_to_spot': 'توجه للموقف',
    'confirm_cancel_title': 'تأكيد الإلغاء',
    'confirm_cancel_body': 'هل أنت متأكد من إلغاء هذا الحجز؟ سيتم استرداد الموقف.',
    'cancel_yes': 'نعم، إلغاء',
    'booking_cancelled': 'تم إلغاء الحجز وتحرير الموقف',
    'cancel_failed': 'فشل الإلغاء',

    // البحث
    'search_title': 'البحث عن موقف',
    'search_hint': 'ابحث عن موقف أو عنوان...',
    'available_only': 'متاح فقط',
    'sort_smart': 'ذكي ⬡',
    'sort_nearest': 'الأقرب',
    'sort_cheapest': 'الأرخص',
    'sort_most': 'الأكثر',
    'nearby_spots': 'المواقف القريبة',
    'results_label': 'نتيجة',
    'top_10': '(أقرب 10)',
    'no_results': 'لا توجد نتائج',
    'full': 'ممتلئ',
    'loc_disabled': 'خدمة الموقع معطّلة، فعّلها من الإعدادات',
    'loc_denied': 'تم رفض إذن الموقع',
    'loc_blocked': 'الإذن محظور — افتح الإعدادات للسماح',
    'loc_set': 'تم تحديد موقعك ✓',
    'loc_failed': 'تعذّر تحديد الموقع، حاول مجدداً',
    'city_default': 'سطيف، الجزائر',

    // بطاقة المنطقة
    'book_btn': 'احجز',
    'price_per_hour_short': 'دج/س',
    'distance_short': 'كم',

    // صفحة الحجز
    'coordinates': 'الإحداثيات',
    'available_spots_label': 'مواقف متاحة',
    'price_per_hour_label': 'السعر/ساعة',
    'distance_label': 'المسافة',
    'choose_spot': 'اختر موقفك',
    'suitable_only': 'مناسب لمركبتي',
    'all_spots': 'الكل',
    'your_vehicle_type': 'نوع مركبتك',
    'err_load_spots': 'خطأ في تحميل المواقف',
    'no_spots': 'لا توجد مواقف مضافة لهذه المنطقة',
    'no_suitable_spots': 'لا توجد مواقف مناسبة لنوع مركبتك',
    'show_all_spots': 'عرض كل المواقف',
    'suitable_badge': 'مناسب',
    'legend_available': 'متاح',
    'legend_booked': 'محجوز',
    'legend_selected': 'مختار',
    'booking_type': 'نوع الحجز',
    'booking_type_hourly': 'ساعي',
    'booking_type_daily': 'يومي',
    'booking_type_weekly': 'أسبوعي',
    'unit_hour': 'ساعة',
    'unit_day': 'يوم',
    'unit_week': 'أسبوع',
    'duration_label': 'مدة الحجز',
    'summary_spot': 'الموقف',
    'summary_type': 'النوع',
    'summary_booking_type': 'نوع الحجز',
    'summary_duration': 'المدة',
    'summary_price_per': 'السعر',
    'summary_total': 'الإجمالي',
    'pay_and_book': 'ادفع واحجز',
    'processing_booking': 'جاري تأكيد الحجز...',
    'navigate_to_zone': 'توجه إلى المنطقة',
    'navigate_to_spot_at': 'توجه إلى الموقف',
    'booking_confirmed_back': 'تم تأكيد الحجز — اضغط للعودة',
    'rate_experience': 'قيّم تجربتك',
    'direction': 'الاتجاه',
    'err_choose_spot': 'يرجى اختيار موقف أولاً',
    'booking_success': 'تم تأكيد الحجز بنجاح!',
    'booking_failed': 'فشل الحجز',
    'feedback_banner_title': 'كيف كانت تجربتك؟',
    'feedback_banner_subtitle': 'قيّم تجربة الحجز الآن',
    'feedback_later': 'لاحقاً',
    'thanks_rating': 'شكراً على تقييمك!',

    // التقييمات
    'feedback_title': 'التقييمات',
    'feedback_send_tab': 'أرسل تقييماً',
    'feedback_all_tab': 'جميع التقييمات',
    'your_feedback_matters': 'ملاحظاتك تهمّنا',
    'how_was_experience': 'كيف كانت تجربتك؟',
    'choose_rating': 'اختر تقييمك من 1 إلى 5 نجوم',
    'feedback_category': 'نوع الملاحظة',
    'cat_general': 'عام',
    'cat_booking': 'تجربة الحجز',
    'cat_price': 'السعر',
    'cat_app': 'التطبيق',
    'cat_service': 'خدمة العملاء',
    'cat_suggestion': 'اقتراح',
    'your_notes': 'ملاحظاتك',
    'notes_hint': 'اكتب ملاحظاتك هنا...',
    'send_feedback': 'إرسال التقييم',
    'sending': 'جاري الإرسال...',
    'send_another': 'إرسال تقييم آخر',
    'success_subtitle': 'لقد تلقّينا ملاحظاتك وسنعمل على تحسين خدماتنا',
    'err_select_rating': 'يرجى اختيار تقييم بالنجوم',
    'err_message_short': 'الرجاء كتابة ملاحظة مفصّلة (10 أحرف على الأقل)',
    'err_send_failed': 'فشل الإرسال، حاول مجدداً',
    'rating_count': 'تقييم',
    'rating_avg': 'المتوسط',
    'rating_satisfaction': 'الرضا',
    'no_feedback_yet': 'لا توجد تقييمات بعد',
    'rating_very_bad': 'سيء جداً',
    'rating_bad': 'سيء',
    'rating_ok': 'مقبول',
    'rating_good': 'جيد',
    'rating_excellent': 'ممتاز 🎉',
    'time_ago_min': 'منذ {n} دقيقة',
    'time_ago_hour': 'منذ {n} ساعة',
    'time_ago_day': 'منذ {n} يوم',

    // الإعدادات
    'settings_title': 'الإعدادات',
    'language': 'اللغة',
    'language_subtitle': 'اختر لغة التطبيق',
    'language_changed': 'تم تغيير اللغة بنجاح',
    'lang_arabic': 'العربية',
    'lang_french': 'Français',
    'lang_english': 'English',
    'about': 'حول التطبيق',
    'version': 'الإصدار',

    // الأمان
    'security_title': 'الأمان وكلمة المرور',
    'change_password': 'تغيير كلمة المرور',
    'current_password': 'كلمة المرور الحالية',
    'new_password': 'كلمة المرور الجديدة',
    'confirm_new_password': 'تأكيد كلمة المرور الجديدة',
    'password_changed': 'تم تغيير كلمة المرور بنجاح',
    'password_change_failed': 'فشل تغيير كلمة المرور',

    // التوجيه
    'preparing_navigation': 'جاري تحضير التوجيه',
    'calculating_route': 'جاري حساب المسار...',
    'navigation_to': 'التوجيه إلى',
    'arrived': 'وصلت! 🎉',
    'arrived_subtitle': 'تم الوصول إلى الموقف',
    'remaining': 'متبقية',
    'time_remaining': 'الوقت المتبقي',
    'step': 'خطوة',
    'recalculate': 'إعادة',
    'covered_pct': '{n}% مكتمل',
    'covered_dist': 'قطعت {d}',
    'remaining_of': 'من {d}',
    'then_label': 'ثم',
    'unknown_error': 'خطأ غير معروف',
    'route_unavailable': 'لا يوجد مسار متاح',
    'connection_timeout': 'انتهت مهلة الاتصال، تحقق من الإنترنت',
    'cannot_locate': 'تعذّر تحديد موقعك',

    // وحدات المسافة
    'meters': 'م',
    'km': 'كم',
    'minutes_short': 'د',
    'hours_short': 'س',
  },

  // ─────────── الفرنسية ───────────
  'fr': {
    'app_name': 'SmartParking',
    'app_subtitle': 'Système de gestion intelligent',
    'ok': 'OK',
    'cancel': 'Annuler',
    'save': 'Enregistrer',
    'edit': 'Modifier le profil',
    'delete': 'Supprimer',
    'confirm': 'Confirmer',
    'yes': 'Oui',
    'no': 'Non',
    'close': 'Fermer',
    'back': 'Retour',
    'retry': 'Réessayer',
    'loading': 'Chargement...',
    'currency': 'DA',
    'verified_account': 'Compte vérifié',

    'nav_search': 'Recherche',
    'nav_bookings': 'Réservations',
    'nav_profile': 'Profil',

    'profile_title': 'Mon profil',
    'profile_ratings': 'Évaluations',
    'profile_settings': 'Paramètres',
    'profile_security': 'Sécurité et mot de passe',
    'profile_help': 'Aide',
    'profile_logout': 'Déconnexion',
    'register_plate': 'Enregistrer la plaque',
    'my_vehicle': 'Mon véhicule',
    'stat_bookings': 'Réservations',
    'stat_paid': 'Payé',
    'stat_total': 'Total',
    'edit_profile_title': 'Modifier le profil',
    'edit_vehicle_title': 'Modifier le véhicule',
    'name_label': 'Nom',
    'plate_label': "Numéro d'immatriculation",
    'vehicle_type_label': 'Type de véhicule',
    'help_title': 'Aide',
    'help_body':
        'Bienvenue sur SmartParking !\n\n• Recherche : trouvez le parking le plus proche.\n• Réservation : choisissez une zone, une place et payez.\n• Réservations : consultez vos réservations.\n• Paramètres : changez la langue.\n\nPour toute question, contactez le support.',

    'vehicle_standard': 'Voiture standard',
    'vehicle_vip': 'Voiture de luxe',
    'vehicle_motorcycle': 'Moto',
    'vehicle_electric': 'Voiture électrique',
    'vehicle_disabled': 'Personne à mobilité réduite',

    'login_welcome': 'Bienvenue',
    'login_subtitle': "Connectez-vous pour accéder à l'application",
    'email': 'Adresse e-mail',
    'password': 'Mot de passe',
    'forgot_password': 'Mot de passe oublié ?',
    'remember_me': 'Se souvenir',
    'login_btn': 'Se connecter',
    'logging_in': 'Vérification...',
    'demo_fill': 'Cliquer pour remplir les données de démo',
    'signup_link': 'Créer un compte',
    'no_account': "Vous n'avez pas de compte ?",
    'forgot_dialog_title': 'Récupérer le mot de passe',
    'forgot_dialog_hint': 'Saisissez votre e-mail',
    'send_btn': 'Envoyer',
    'reset_sent': 'Lien de récupération envoyé — vérifiez votre boîte',
    'err_fill_all': 'Veuillez remplir tous les champs',
    'err_invalid_creds': 'E-mail ou mot de passe incorrect',
    'err_user_not_found': 'Aucun compte avec cet e-mail',
    'err_too_many': 'Trop de tentatives, réessayez plus tard',
    'err_network': 'Vérifiez votre connexion Internet',
    'err_generic': "Une erreur s'est produite, réessayez",

    'register_title': 'Créer un compte',
    'register_subtitle': 'Saisissez vos informations pour rejoindre',
    'personal_info': 'Informations personnelles',
    'vehicle_info': 'Informations du véhicule',
    'full_name': 'Nom complet',
    'name_hint': 'Mohamed Ahmed',
    'confirm_password': 'Confirmer le mot de passe',
    'plate_number': "Numéro d'immatriculation",
    'plate_hint': '123 ABC',
    'car_brand': 'Marque',
    'car_brand_hint': 'Rechercher... Toyota, BMW, Mercedes',
    'car_model': 'Modèle',
    'choose_brand_first': "Choisissez d'abord la marque",
    'search_model_hint': 'Rechercher le modèle...',
    'create_account_btn': 'Créer le compte',
    'creating_account': 'Création du compte...',
    'login_link': 'Se connecter',
    'has_account': 'Vous avez déjà un compte ?',
    'err_passwords_no_match': 'Les mots de passe ne correspondent pas',
    'err_password_short': 'Le mot de passe doit contenir au moins 6 caractères',
    'err_email_in_use': 'Cet e-mail est déjà utilisé',
    'err_invalid_email': "Format d'e-mail invalide",
    'err_weak_password': 'Mot de passe trop faible',

    'bookings_title': 'Mes réservations',
    'bookings_active': 'Actives',
    'bookings_completed': 'Terminées',
    'bookings_cancelled': 'Annulées',
    'bookings_count': 'réservation(s)',
    'bookings_empty': 'Aucune réservation dans cette catégorie',
    'bookings_error': 'Erreur lors du chargement',
    'status_active': 'Active',
    'status_completed': 'Terminée',
    'status_cancelled': 'Annulée',
    'spot_label': 'Place',
    'cancel_booking': 'Annuler',
    'navigate_to_spot': 'Aller à la place',
    'confirm_cancel_title': "Confirmer l'annulation",
    'confirm_cancel_body':
        'Êtes-vous sûr d’annuler ? La place sera libérée.',
    'cancel_yes': 'Oui, annuler',
    'booking_cancelled': 'Réservation annulée et place libérée',
    'cancel_failed': "Échec de l'annulation",

    'search_title': 'Rechercher un parking',
    'search_hint': 'Rechercher un parking ou une adresse...',
    'available_only': 'Disponibles seulement',
    'sort_smart': 'Intelligent ⬡',
    'sort_nearest': 'Plus proche',
    'sort_cheapest': 'Moins cher',
    'sort_most': 'Plus de places',
    'nearby_spots': 'Parkings à proximité',
    'results_label': 'résultat(s)',
    'top_10': '(10 plus proches)',
    'no_results': 'Aucun résultat',
    'full': 'Plein',
    'loc_disabled':
        'Service de localisation désactivé, activez-le dans les paramètres',
    'loc_denied': 'Permission de localisation refusée',
    'loc_blocked':
        'Permission bloquée — ouvrez les paramètres pour autoriser',
    'loc_set': 'Position détectée ✓',
    'loc_failed': 'Impossible de détecter la position, réessayez',
    'city_default': 'Sétif, Algérie',

    'book_btn': 'Réserver',
    'price_per_hour_short': 'DA/h',
    'distance_short': 'km',

    'coordinates': 'Coordonnées',
    'available_spots_label': 'Places disponibles',
    'price_per_hour_label': 'Prix / heure',
    'distance_label': 'Distance',
    'choose_spot': 'Choisissez votre place',
    'suitable_only': 'Adapté à mon véhicule',
    'all_spots': 'Toutes',
    'your_vehicle_type': 'Type de votre véhicule',
    'err_load_spots': 'Erreur de chargement des places',
    'no_spots': 'Aucune place dans cette zone',
    'no_suitable_spots': 'Aucune place adaptée à votre véhicule',
    'show_all_spots': 'Afficher toutes les places',
    'suitable_badge': 'Adaptée',
    'legend_available': 'Disponible',
    'legend_booked': 'Réservée',
    'legend_selected': 'Sélectionnée',
    'booking_type': 'Type de réservation',
    'booking_type_hourly': 'Horaire',
    'booking_type_daily': 'Journalière',
    'booking_type_weekly': 'Hebdomadaire',
    'unit_hour': 'heure',
    'unit_day': 'jour',
    'unit_week': 'semaine',
    'duration_label': 'Durée de réservation',
    'summary_spot': 'Place',
    'summary_type': 'Type',
    'summary_booking_type': 'Type de réservation',
    'summary_duration': 'Durée',
    'summary_price_per': 'Prix',
    'summary_total': 'Total',
    'pay_and_book': 'Payer et réserver',
    'processing_booking': 'Confirmation en cours...',
    'navigate_to_zone': 'Aller à la zone',
    'navigate_to_spot_at': 'Aller à la place',
    'booking_confirmed_back': 'Réservation confirmée — appuyez pour revenir',
    'rate_experience': 'Évaluer votre expérience',
    'direction': 'Itinéraire',
    'err_choose_spot': "Veuillez d'abord choisir une place",
    'booking_success': 'Réservation confirmée avec succès !',
    'booking_failed': 'Échec de la réservation',
    'feedback_banner_title': 'Comment était votre expérience ?',
    'feedback_banner_subtitle': 'Évaluez votre réservation maintenant',
    'feedback_later': 'Plus tard',
    'thanks_rating': 'Merci pour votre évaluation !',

    'feedback_title': 'Évaluations',
    'feedback_send_tab': 'Envoyer une évaluation',
    'feedback_all_tab': 'Toutes les évaluations',
    'your_feedback_matters': 'Vos commentaires comptent',
    'how_was_experience': 'Comment était votre expérience ?',
    'choose_rating': 'Choisissez de 1 à 5 étoiles',
    'feedback_category': 'Catégorie',
    'cat_general': 'Général',
    'cat_booking': 'Réservation',
    'cat_price': 'Prix',
    'cat_app': 'Application',
    'cat_service': 'Service client',
    'cat_suggestion': 'Suggestion',
    'your_notes': 'Vos remarques',
    'notes_hint': 'Écrivez vos remarques ici...',
    'send_feedback': 'Envoyer',
    'sending': 'Envoi...',
    'send_another': 'Envoyer un autre',
    'success_subtitle':
        'Nous avons reçu vos commentaires et les utiliserons pour améliorer nos services',
    'err_select_rating': 'Veuillez choisir une note',
    'err_message_short':
        'Veuillez écrire un message détaillé (au moins 10 caractères)',
    'err_send_failed': "Échec de l'envoi, réessayez",
    'rating_count': 'évaluation(s)',
    'rating_avg': 'Moyenne',
    'rating_satisfaction': 'Satisfaction',
    'no_feedback_yet': "Aucune évaluation pour l'instant",
    'rating_very_bad': 'Très mauvais',
    'rating_bad': 'Mauvais',
    'rating_ok': 'Acceptable',
    'rating_good': 'Bon',
    'rating_excellent': 'Excellent 🎉',
    'time_ago_min': 'il y a {n} min',
    'time_ago_hour': 'il y a {n} h',
    'time_ago_day': 'il y a {n} j',

    'settings_title': 'Paramètres',
    'language': 'Langue',
    'language_subtitle': "Choisissez la langue de l'application",
    'language_changed': 'Langue modifiée avec succès',
    'lang_arabic': 'العربية',
    'lang_french': 'Français',
    'lang_english': 'English',
    'about': "À propos de l'application",
    'version': 'Version',

    'security_title': 'Sécurité et mot de passe',
    'change_password': 'Changer le mot de passe',
    'current_password': 'Mot de passe actuel',
    'new_password': 'Nouveau mot de passe',
    'confirm_new_password': 'Confirmer le nouveau mot de passe',
    'password_changed': 'Mot de passe modifié avec succès',
    'password_change_failed': 'Échec du changement de mot de passe',

    'preparing_navigation': "Préparation de l'itinéraire",
    'calculating_route': 'Calcul de l’itinéraire...',
    'navigation_to': 'Itinéraire vers',
    'arrived': 'Arrivé ! 🎉',
    'arrived_subtitle': 'Vous êtes arrivé à la place',
    'remaining': 'restant',
    'time_remaining': 'Temps restant',
    'step': 'étape',
    'recalculate': 'Recalculer',
    'covered_pct': '{n}% terminé',
    'covered_dist': 'parcouru {d}',
    'remaining_of': 'sur {d}',
    'then_label': 'puis',
    'unknown_error': 'Erreur inconnue',
    'route_unavailable': "Aucun itinéraire disponible",
    'connection_timeout': 'Délai de connexion expiré, vérifiez Internet',
    'cannot_locate': 'Impossible de vous localiser',

    'meters': 'm',
    'km': 'km',
    'minutes_short': 'min',
    'hours_short': 'h',
  },

  // ─────────── الإنجليزية ───────────
  'en': {
    'app_name': 'SmartParking',
    'app_subtitle': 'Smart management system',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'edit': 'Edit profile',
    'delete': 'Delete',
    'confirm': 'Confirm',
    'yes': 'Yes',
    'no': 'No',
    'close': 'Close',
    'back': 'Back',
    'retry': 'Retry',
    'loading': 'Loading...',
    'currency': 'DZD',
    'verified_account': 'Verified account',

    'nav_search': 'Search',
    'nav_bookings': 'Bookings',
    'nav_profile': 'Profile',

    'profile_title': 'My profile',
    'profile_ratings': 'Ratings',
    'profile_settings': 'Settings',
    'profile_security': 'Security & password',
    'profile_help': 'Help',
    'profile_logout': 'Sign out',
    'register_plate': 'Register plate',
    'my_vehicle': 'My vehicle',
    'stat_bookings': 'Bookings',
    'stat_paid': 'Paid',
    'stat_total': 'Total',
    'edit_profile_title': 'Edit profile',
    'edit_vehicle_title': 'Edit vehicle',
    'name_label': 'Name',
    'plate_label': 'Plate number',
    'vehicle_type_label': 'Vehicle type',
    'help_title': 'Help',
    'help_body':
        'Welcome to SmartParking!\n\n• Search: find the nearest parking.\n• Booking: choose a zone, a spot and pay.\n• Bookings: view your bookings.\n• Settings: change language.\n\nFor any question contact support.',

    'vehicle_standard': 'Standard car',
    'vehicle_vip': 'Luxury car',
    'vehicle_motorcycle': 'Motorcycle',
    'vehicle_electric': 'Electric car',
    'vehicle_disabled': 'Disabled / accessible',

    'login_welcome': 'Welcome',
    'login_subtitle': 'Sign in to access the app',
    'email': 'Email address',
    'password': 'Password',
    'forgot_password': 'Forgot password?',
    'remember_me': 'Remember me',
    'login_btn': 'Sign in',
    'logging_in': 'Verifying...',
    'demo_fill': 'Tap to fill demo credentials',
    'signup_link': 'Create new account',
    'no_account': 'No account yet?',
    'forgot_dialog_title': 'Reset password',
    'forgot_dialog_hint': 'Enter your email',
    'send_btn': 'Send',
    'reset_sent': 'Reset link sent — check your inbox',
    'err_fill_all': 'Please fill all fields',
    'err_invalid_creds': 'Wrong email or password',
    'err_user_not_found': 'No account with this email',
    'err_too_many': 'Too many attempts, try later',
    'err_network': 'Check your internet connection',
    'err_generic': 'Something went wrong, try again',

    'register_title': 'Create new account',
    'register_subtitle': 'Enter your information to join',
    'personal_info': 'Personal information',
    'vehicle_info': 'Vehicle information',
    'full_name': 'Full name',
    'name_hint': 'Mohamed Ahmed',
    'confirm_password': 'Confirm password',
    'plate_number': 'Plate number',
    'plate_hint': '123 ABC',
    'car_brand': 'Car brand',
    'car_brand_hint': 'Search... Toyota, BMW, Mercedes',
    'car_model': 'Car model',
    'choose_brand_first': 'Choose the brand first',
    'search_model_hint': 'Search the model...',
    'create_account_btn': 'Create account',
    'creating_account': 'Creating account...',
    'login_link': 'Sign in',
    'has_account': 'Already have an account?',
    'err_passwords_no_match': "Passwords don't match",
    'err_password_short': 'Password must be at least 6 characters',
    'err_email_in_use': 'This email is already in use',
    'err_invalid_email': 'Invalid email format',
    'err_weak_password': 'Password too weak',

    'bookings_title': 'My bookings',
    'bookings_active': 'Active',
    'bookings_completed': 'Completed',
    'bookings_cancelled': 'Cancelled',
    'bookings_count': 'booking(s)',
    'bookings_empty': 'No bookings in this category',
    'bookings_error': 'Error loading bookings',
    'status_active': 'Active',
    'status_completed': 'Completed',
    'status_cancelled': 'Cancelled',
    'spot_label': 'Spot',
    'cancel_booking': 'Cancel',
    'navigate_to_spot': 'Navigate to spot',
    'confirm_cancel_title': 'Confirm cancellation',
    'confirm_cancel_body':
        'Are you sure you want to cancel this booking? The spot will be released.',
    'cancel_yes': 'Yes, cancel',
    'booking_cancelled': 'Booking cancelled and spot released',
    'cancel_failed': 'Cancellation failed',

    'search_title': 'Find parking',
    'search_hint': 'Search parking or address...',
    'available_only': 'Available only',
    'sort_smart': 'Smart ⬡',
    'sort_nearest': 'Nearest',
    'sort_cheapest': 'Cheapest',
    'sort_most': 'Most spots',
    'nearby_spots': 'Nearby parking',
    'results_label': 'result(s)',
    'top_10': '(top 10)',
    'no_results': 'No results',
    'full': 'Full',
    'loc_disabled':
        'Location service disabled, enable it in settings',
    'loc_denied': 'Location permission denied',
    'loc_blocked':
        'Permission blocked — open settings to allow',
    'loc_set': 'Location detected ✓',
    'loc_failed': 'Could not detect location, retry',
    'city_default': 'Setif, Algeria',

    'book_btn': 'Book',
    'price_per_hour_short': 'DZD/h',
    'distance_short': 'km',

    'coordinates': 'Coordinates',
    'available_spots_label': 'Available spots',
    'price_per_hour_label': 'Price / hour',
    'distance_label': 'Distance',
    'choose_spot': 'Choose your spot',
    'suitable_only': 'Suitable for my vehicle',
    'all_spots': 'All',
    'your_vehicle_type': 'Your vehicle type',
    'err_load_spots': 'Error loading spots',
    'no_spots': 'No spots in this zone',
    'no_suitable_spots': 'No suitable spots for your vehicle',
    'show_all_spots': 'Show all spots',
    'suitable_badge': 'Suitable',
    'legend_available': 'Available',
    'legend_booked': 'Reserved',
    'legend_selected': 'Selected',
    'booking_type': 'Booking type',
    'booking_type_hourly': 'Hourly',
    'booking_type_daily': 'Daily',
    'booking_type_weekly': 'Weekly',
    'unit_hour': 'hour',
    'unit_day': 'day',
    'unit_week': 'week',
    'duration_label': 'Booking duration',
    'summary_spot': 'Spot',
    'summary_type': 'Type',
    'summary_booking_type': 'Booking type',
    'summary_duration': 'Duration',
    'summary_price_per': 'Price',
    'summary_total': 'Total',
    'pay_and_book': 'Pay and book',
    'processing_booking': 'Confirming booking...',
    'navigate_to_zone': 'Go to zone',
    'navigate_to_spot_at': 'Go to spot',
    'booking_confirmed_back': 'Booking confirmed — tap to go back',
    'rate_experience': 'Rate your experience',
    'direction': 'Directions',
    'err_choose_spot': 'Please choose a spot first',
    'booking_success': 'Booking confirmed successfully!',
    'booking_failed': 'Booking failed',
    'feedback_banner_title': 'How was your experience?',
    'feedback_banner_subtitle': 'Rate your booking now',
    'feedback_later': 'Later',
    'thanks_rating': 'Thanks for your rating!',

    'feedback_title': 'Ratings',
    'feedback_send_tab': 'Send rating',
    'feedback_all_tab': 'All ratings',
    'your_feedback_matters': 'Your feedback matters',
    'how_was_experience': 'How was your experience?',
    'choose_rating': 'Choose 1 to 5 stars',
    'feedback_category': 'Category',
    'cat_general': 'General',
    'cat_booking': 'Booking',
    'cat_price': 'Price',
    'cat_app': 'App',
    'cat_service': 'Customer service',
    'cat_suggestion': 'Suggestion',
    'your_notes': 'Your notes',
    'notes_hint': 'Write your notes here...',
    'send_feedback': 'Send rating',
    'sending': 'Sending...',
    'send_another': 'Send another',
    'success_subtitle':
        'We received your feedback and will use it to improve our services',
    'err_select_rating': 'Please choose a star rating',
    'err_message_short':
        'Please write a detailed message (at least 10 characters)',
    'err_send_failed': 'Sending failed, try again',
    'rating_count': 'rating(s)',
    'rating_avg': 'Average',
    'rating_satisfaction': 'Satisfaction',
    'no_feedback_yet': 'No ratings yet',
    'rating_very_bad': 'Very bad',
    'rating_bad': 'Bad',
    'rating_ok': 'OK',
    'rating_good': 'Good',
    'rating_excellent': 'Excellent 🎉',
    'time_ago_min': '{n} min ago',
    'time_ago_hour': '{n} h ago',
    'time_ago_day': '{n} d ago',

    'settings_title': 'Settings',
    'language': 'Language',
    'language_subtitle': 'Choose the application language',
    'language_changed': 'Language changed successfully',
    'lang_arabic': 'العربية',
    'lang_french': 'Français',
    'lang_english': 'English',
    'about': 'About',
    'version': 'Version',

    'security_title': 'Security & password',
    'change_password': 'Change password',
    'current_password': 'Current password',
    'new_password': 'New password',
    'confirm_new_password': 'Confirm new password',
    'password_changed': 'Password changed successfully',
    'password_change_failed': 'Password change failed',

    'preparing_navigation': 'Preparing navigation',
    'calculating_route': 'Calculating route...',
    'navigation_to': 'Navigating to',
    'arrived': 'Arrived! 🎉',
    'arrived_subtitle': 'You arrived at the spot',
    'remaining': 'remaining',
    'time_remaining': 'Time remaining',
    'step': 'step',
    'recalculate': 'Recalculate',
    'covered_pct': '{n}% complete',
    'covered_dist': 'covered {d}',
    'remaining_of': 'of {d}',
    'then_label': 'then',
    'unknown_error': 'Unknown error',
    'route_unavailable': 'No route available',
    'connection_timeout': 'Connection timeout, check Internet',
    'cannot_locate': 'Could not locate you',

    'meters': 'm',
    'km': 'km',
    'minutes_short': 'min',
    'hours_short': 'h',
  },
};

// ════════════════════════════════════════════
//  دالة استبدال متغيرات النص
//  مثال: trf('time_ago_min', {'n': '5'})
// ════════════════════════════════════════════
String trf(String key, Map<String, String> args) {
  String text = tr(key);
  args.forEach((k, v) {
    text = text.replaceAll('{$k}', v);
  });
  return text;
}
