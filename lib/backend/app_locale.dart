import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ════════════════════════════════════════════
//  نظام تعدّد اللغات (i18n)
//  - يحفظ اللغة المختارة في SharedPreferences
//  - يُعيد البناء تلقائياً عند التغيير عبر ValueListenableBuilder
//  - يدعم: العربية / English / Français
// ════════════════════════════════════════════

class AppLocale {
  static const _kPrefKey = 'app_locale_code';

  /// قائمة اللغات المتاحة
  static const supported = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// يستمع إليه MaterialApp لإعادة البناء عند تغيّر اللغة
  static final ValueNotifier<Locale> notifier =
      ValueNotifier<Locale>(const Locale('ar'));

  static Locale get current => notifier.value;

  /// تحميل اللغة المحفوظة عند بدء التطبيق
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kPrefKey);
    if (code != null && _translations.containsKey(code)) {
      notifier.value = Locale(code);
    }
  }

  /// تغيير اللغة وحفظها
  static Future<void> set(String code) async {
    if (!_translations.containsKey(code)) return;
    notifier.value = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, code);
  }

  /// اتجاه النص حسب اللغة
  static TextDirection get textDirection =>
      current.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  /// اسم اللغة الحالي للعرض
  static String displayName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        return code;
    }
  }

  /// دالة الترجمة الرئيسية
  static String t(String key) {
    final code = current.languageCode;
    return _translations[code]?[key] ?? _translations['ar']![key] ?? key;
  }
}

/// اختصار سهل للاستخدام داخل الواجهات: tr('key')
String tr(String key) => AppLocale.t(key);

/// قاموس الترجمات الكامل
const Map<String, Map<String, String>> _translations = {
  // ════════ العربية ════════
  'ar': {
    // عام
    'app_name': 'SmartParking',
    'ok': 'موافق',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'edit': 'تعديل',
    'delete': 'حذف',
    'confirm': 'تأكيد',
    'loading': 'جاري التحميل...',
    'error': 'خطأ',
    'success': 'تم بنجاح',
    'retry': 'إعادة المحاولة',
    'close': 'إغلاق',
    'back': 'رجوع',
    'next': 'التالي',
    'yes': 'نعم',
    'no': 'لا',

    // التبويبات السفلية
    'nav_search': 'البحث',
    'nav_bookings': 'حجوزاتي',
    'nav_profile': 'حسابي',

    // تسجيل الدخول
    'login_title': 'تسجيل الدخول',
    'login_email': 'البريد الإلكتروني',
    'login_password': 'كلمة المرور',
    'login_button': 'دخول',
    'login_forgot': 'نسيت كلمة المرور؟',
    'login_no_account': 'ليس لديك حساب؟',
    'login_register': 'إنشاء حساب',
    'login_welcome': 'مرحباً بعودتك',

    // التسجيل
    'register_title': 'إنشاء حساب جديد',
    'register_name': 'الاسم الكامل',
    'register_phone': 'رقم الهاتف',
    'register_plate': 'رقم اللوحة',
    'register_confirm_password': 'تأكيد كلمة المرور',
    'register_button': 'إنشاء حساب',
    'register_have_account': 'لديك حساب؟',
    'register_login': 'تسجيل الدخول',

    // الحساب
    'profile_title': 'حسابي',
    'profile_my_bookings': 'حجوزاتي',
    'profile_ratings': 'التقييمات',
    'profile_settings': 'الإعدادات',
    'profile_notifications': 'الإشعارات',
    'profile_security': 'الأمان وكلمة المرور',
    'profile_help': 'المساعدة والدعم',
    'profile_logout': 'تسجيل الخروج',
    'profile_logout_confirm': 'هل تريد تسجيل الخروج؟',

    // الحجوزات
    'bookings_title': 'حجوزاتي',
    'bookings_active': 'النشطة',
    'bookings_completed': 'المكتملة',
    'bookings_cancelled': 'الملغاة',
    'bookings_empty': 'لا توجد حجوزات',
    'bookings_count': 'حجز',
    'bookings_error': 'حدث خطأ في جلب الحجوزات',

    // الإعدادات
    'settings_title': 'الإعدادات',
    'settings_notifications': 'الإشعارات',
    'settings_push': 'تفعيل الإشعارات',
    'settings_booking_alerts': 'تنبيهات الحجوزات',
    'settings_sound': 'المؤثرات الصوتية',
    'settings_privacy': 'الخصوصية والأمان',
    'settings_password': 'كلمة المرور والأمان',
    'settings_location': 'خدمات الموقع',
    'settings_preferences': 'التفضيلات',
    'settings_language': 'اللغة',
    'settings_about': 'عن التطبيق',
    'settings_reviews': 'آراء المستخدمين',
    'settings_help': 'المساعدة والدعم',
    'settings_terms': 'شروط الاستخدام',
    'settings_version': 'إصدار التطبيق',
    'settings_pick_language': 'اختر اللغة',

    // الأمان
    'security_title': 'الأمان وكلمة المرور',
    'security_change_password': 'تغيير كلمة المرور',
    'security_current_password': 'كلمة المرور الحالية',
    'security_new_password': 'كلمة المرور الجديدة',
    'security_confirm_new_password': 'تأكيد كلمة المرور الجديدة',
    'security_update': 'تحديث كلمة المرور',
    'security_reset_email': 'إرسال رابط استعادة',
    'security_signout_all': 'تسجيل الخروج من جميع الأجهزة',
    'security_password_changed': 'تم تغيير كلمة المرور بنجاح',
    'security_password_short': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
    'security_password_mismatch': 'كلمتا المرور غير متطابقتين',

    // المساعدة والشروط
    'help_title': 'المساعدة والدعم',
    'help_body':
        'للمساعدة والاستفسارات يمكنك التواصل معنا:\n\n• البريد: support@smartparking.dz\n• الهاتف: +213 555 000 000\n• ساعات العمل: 24/7',
    'terms_title': 'شروط الاستخدام',
    'terms_body':
        'باستخدامك لتطبيق SmartParking فإنك توافق على:\n\n1. استخدام التطبيق للأغراض المشروعة فقط.\n2. تقديم بيانات صحيحة عن المركبة.\n3. الالتزام بمواعيد الحجز.\n4. احترام الأنظمة والقوانين المحلية.\n\nيحق للإدارة إلغاء أي حجز في حالة المخالفة.',
  },

  // ════════ English ════════
  'en': {
    'app_name': 'SmartParking',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'edit': 'Edit',
    'delete': 'Delete',
    'confirm': 'Confirm',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'retry': 'Retry',
    'close': 'Close',
    'back': 'Back',
    'next': 'Next',
    'yes': 'Yes',
    'no': 'No',

    'nav_search': 'Search',
    'nav_bookings': 'My Bookings',
    'nav_profile': 'Account',

    'login_title': 'Sign In',
    'login_email': 'Email',
    'login_password': 'Password',
    'login_button': 'Sign In',
    'login_forgot': 'Forgot password?',
    'login_no_account': "Don't have an account?",
    'login_register': 'Sign Up',
    'login_welcome': 'Welcome back',

    'register_title': 'Create Account',
    'register_name': 'Full Name',
    'register_phone': 'Phone Number',
    'register_plate': 'Plate Number',
    'register_confirm_password': 'Confirm Password',
    'register_button': 'Create Account',
    'register_have_account': 'Already have an account?',
    'register_login': 'Sign In',

    'profile_title': 'My Account',
    'profile_my_bookings': 'My Bookings',
    'profile_ratings': 'Ratings',
    'profile_settings': 'Settings',
    'profile_notifications': 'Notifications',
    'profile_security': 'Security & Password',
    'profile_help': 'Help & Support',
    'profile_logout': 'Sign Out',
    'profile_logout_confirm': 'Are you sure you want to sign out?',

    'bookings_title': 'My Bookings',
    'bookings_active': 'Active',
    'bookings_completed': 'Completed',
    'bookings_cancelled': 'Cancelled',
    'bookings_empty': 'No bookings yet',
    'bookings_count': 'bookings',
    'bookings_error': 'Failed to load bookings',

    'settings_title': 'Settings',
    'settings_notifications': 'Notifications',
    'settings_push': 'Enable notifications',
    'settings_booking_alerts': 'Booking alerts',
    'settings_sound': 'Sound effects',
    'settings_privacy': 'Privacy & Security',
    'settings_password': 'Password & Security',
    'settings_location': 'Location Services',
    'settings_preferences': 'Preferences',
    'settings_language': 'Language',
    'settings_about': 'About',
    'settings_reviews': 'User Reviews',
    'settings_help': 'Help & Support',
    'settings_terms': 'Terms of Use',
    'settings_version': 'App Version',
    'settings_pick_language': 'Choose Language',

    'security_title': 'Security & Password',
    'security_change_password': 'Change Password',
    'security_current_password': 'Current Password',
    'security_new_password': 'New Password',
    'security_confirm_new_password': 'Confirm New Password',
    'security_update': 'Update Password',
    'security_reset_email': 'Send Reset Link',
    'security_signout_all': 'Sign out from all devices',
    'security_password_changed': 'Password updated successfully',
    'security_password_short': 'Password must be at least 6 characters',
    'security_password_mismatch': 'Passwords do not match',

    'help_title': 'Help & Support',
    'help_body':
        'For help and inquiries, contact us:\n\n• Email: support@smartparking.dz\n• Phone: +213 555 000 000\n• Hours: 24/7',
    'terms_title': 'Terms of Use',
    'terms_body':
        'By using SmartParking you agree to:\n\n1. Use the app for lawful purposes only.\n2. Provide accurate vehicle information.\n3. Honor your booking times.\n4. Respect local laws and regulations.\n\nManagement reserves the right to cancel bookings for violations.',
  },

  // ════════ Français ════════
  'fr': {
    'app_name': 'SmartParking',
    'ok': 'OK',
    'cancel': 'Annuler',
    'save': 'Enregistrer',
    'edit': 'Modifier',
    'delete': 'Supprimer',
    'confirm': 'Confirmer',
    'loading': 'Chargement...',
    'error': 'Erreur',
    'success': 'Succès',
    'retry': 'Réessayer',
    'close': 'Fermer',
    'back': 'Retour',
    'next': 'Suivant',
    'yes': 'Oui',
    'no': 'Non',

    'nav_search': 'Recherche',
    'nav_bookings': 'Mes réservations',
    'nav_profile': 'Compte',

    'login_title': 'Connexion',
    'login_email': 'E-mail',
    'login_password': 'Mot de passe',
    'login_button': 'Se connecter',
    'login_forgot': 'Mot de passe oublié ?',
    'login_no_account': "Vous n'avez pas de compte ?",
    'login_register': "S'inscrire",
    'login_welcome': 'Bon retour',

    'register_title': 'Créer un compte',
    'register_name': 'Nom complet',
    'register_phone': 'Numéro de téléphone',
    'register_plate': "Numéro d'immatriculation",
    'register_confirm_password': 'Confirmer le mot de passe',
    'register_button': 'Créer un compte',
    'register_have_account': 'Vous avez déjà un compte ?',
    'register_login': 'Se connecter',

    'profile_title': 'Mon compte',
    'profile_my_bookings': 'Mes réservations',
    'profile_ratings': 'Évaluations',
    'profile_settings': 'Paramètres',
    'profile_notifications': 'Notifications',
    'profile_security': 'Sécurité et mot de passe',
    'profile_help': 'Aide et support',
    'profile_logout': 'Déconnexion',
    'profile_logout_confirm': 'Voulez-vous vous déconnecter ?',

    'bookings_title': 'Mes réservations',
    'bookings_active': 'Actives',
    'bookings_completed': 'Terminées',
    'bookings_cancelled': 'Annulées',
    'bookings_empty': 'Aucune réservation',
    'bookings_count': 'réservations',
    'bookings_error': 'Échec du chargement',

    'settings_title': 'Paramètres',
    'settings_notifications': 'Notifications',
    'settings_push': 'Activer les notifications',
    'settings_booking_alerts': 'Alertes de réservation',
    'settings_sound': 'Effets sonores',
    'settings_privacy': 'Confidentialité et sécurité',
    'settings_password': 'Mot de passe et sécurité',
    'settings_location': 'Services de localisation',
    'settings_preferences': 'Préférences',
    'settings_language': 'Langue',
    'settings_about': "À propos de l'application",
    'settings_reviews': 'Avis des utilisateurs',
    'settings_help': 'Aide et support',
    'settings_terms': "Conditions d'utilisation",
    'settings_version': "Version de l'application",
    'settings_pick_language': 'Choisir la langue',

    'security_title': 'Sécurité et mot de passe',
    'security_change_password': 'Changer le mot de passe',
    'security_current_password': 'Mot de passe actuel',
    'security_new_password': 'Nouveau mot de passe',
    'security_confirm_new_password': 'Confirmer le nouveau mot de passe',
    'security_update': 'Mettre à jour',
    'security_reset_email': 'Envoyer le lien de réinitialisation',
    'security_signout_all': 'Se déconnecter de tous les appareils',
    'security_password_changed': 'Mot de passe modifié avec succès',
    'security_password_short':
        'Le mot de passe doit comporter au moins 6 caractères',
    'security_password_mismatch': 'Les mots de passe ne correspondent pas',

    'help_title': 'Aide et support',
    'help_body':
        'Pour toute aide ou question, contactez-nous :\n\n• E-mail : support@smartparking.dz\n• Téléphone : +213 555 000 000\n• Horaires : 24/7',
    'terms_title': "Conditions d'utilisation",
    'terms_body':
        "En utilisant SmartParking, vous acceptez :\n\n1. D'utiliser l'application à des fins légales uniquement.\n2. De fournir des informations exactes sur le véhicule.\n3. De respecter les horaires de réservation.\n4. De respecter les lois locales.\n\nLa direction se réserve le droit d'annuler toute réservation en cas d'infraction.",
  },
};
