import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import 'security_page.dart';
import 'feedback_page.dart';
import '../backend/firebase_service.dart';
import '../backend/app_locale.dart';

// ════════════════════════════════════════════
//  صفحة الإعدادات العامة (متعدّدة اللغات)
// ════════════════════════════════════════════
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _bookingAlerts = true;
  bool _soundEffects = true;
  bool _locationServices = true;

  @override
  Widget build(BuildContext context) {
    // الاستماع لتغيّر اللغة لإعادة بناء الصفحة
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.notifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: C.light,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _sectionTitle(tr('settings_notifications'), FontAwesomeIcons.bell),
                _buildCard([
                  _switchTile(
                    icon: FontAwesomeIcons.bell,
                    color: const Color(0xFFF97316),
                    label: tr('settings_push'),
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  _divider(),
                  _switchTile(
                    icon: FontAwesomeIcons.squareParking,
                    color: C.primary,
                    label: tr('settings_booking_alerts'),
                    value: _bookingAlerts,
                    onChanged: (v) => setState(() => _bookingAlerts = v),
                  ),
                  _divider(),
                  _switchTile(
                    icon: FontAwesomeIcons.volumeHigh,
                    color: C.accent,
                    label: tr('settings_sound'),
                    value: _soundEffects,
                    onChanged: (v) => setState(() => _soundEffects = v),
                  ),
                ]),
                const SizedBox(height: 16),
                _sectionTitle(tr('settings_privacy'), FontAwesomeIcons.shieldHalved),
                _buildCard([
                  _navTile(
                    icon: FontAwesomeIcons.key,
                    color: C.secondary,
                    label: tr('settings_password'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SecurityPage()),
                    ),
                  ),
                  _divider(),
                  _switchTile(
                    icon: FontAwesomeIcons.locationDot,
                    color: C.success,
                    label: tr('settings_location'),
                    value: _locationServices,
                    onChanged: (v) => setState(() => _locationServices = v),
                  ),
                ]),
                const SizedBox(height: 16),
                _sectionTitle(tr('settings_preferences'), FontAwesomeIcons.sliders),
                _buildCard([
                  _pickerTile(
                    icon: FontAwesomeIcons.language,
                    color: C.primary,
                    label: tr('settings_language'),
                    value: AppLocale.displayName(locale.languageCode),
                    onTap: _pickLanguage,
                  ),
                ]),
                const SizedBox(height: 16),
                _sectionTitle(tr('settings_about'), FontAwesomeIcons.circleInfo),
                _buildCard([
                  _navTile(
                    icon: FontAwesomeIcons.star,
                    color: C.warning,
                    label: tr('settings_reviews'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackPage()),
                    ),
                  ),
                  _divider(),
                  _navTile(
                    icon: FontAwesomeIcons.circleQuestion,
                    color: C.muted,
                    label: tr('settings_help'),
                    onTap: _showHelpDialog,
                  ),
                  _divider(),
                  _navTile(
                    icon: FontAwesomeIcons.fileLines,
                    color: C.accent,
                    label: tr('settings_terms'),
                    onTap: _showTerms,
                  ),
                  _divider(),
                  _infoTile(
                    icon: FontAwesomeIcons.codeBranch,
                    color: C.dark,
                    label: tr('settings_version'),
                    value: '1.0.0',
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════ HEADER ══════════
  Widget _buildHeader() {
    final email = FirebaseService.currentUser?.email ?? '';
    final isRtl = AppLocale.current.languageCode == 'ar';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.panelDark1, C.panelDark2, C.panelDark3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 36),
                  Text(tr('settings_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(
                          isRtl
                              ? FontAwesomeIcons.arrowRight
                              : FontAwesomeIcons.arrowLeft,
                          color: Colors.white,
                          size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [C.primary, C.secondary]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(FontAwesomeIcons.gear,
                    color: Colors.white, size: 26),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(email,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ══════════ SECTIONS ══════════
  Widget _sectionTitle(String title, IconData icon) {
    final isRtl = AppLocale.current.languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        mainAxisAlignment:
            isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: isRtl
            ? [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: C.dark)),
                const SizedBox(width: 6),
                Icon(icon, size: 12, color: C.muted),
              ]
            : [
                Icon(icon, size: 12, color: C.muted),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: C.dark)),
              ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 16, color: C.border);

  // ══════════ TILES ══════════
  Widget _switchTile({
    required IconData icon,
    required Color color,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isRtl = AppLocale.current.languageCode == 'ar';
    final iconBox = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 14, color: color),
    );
    final text = Text(label,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: C.dark));
    final sw = Switch(value: value, onChanged: onChanged, activeColor: C.primary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: isRtl
            ? [
                sw,
                Row(children: [text, const SizedBox(width: 12), iconBox]),
              ]
            : [
                Row(children: [iconBox, const SizedBox(width: 12), text]),
                sw,
              ],
      ),
    );
  }

  Widget _navTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    final isRtl = AppLocale.current.languageCode == 'ar';
    final iconBox = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 14, color: color),
    );
    final text = Text(label,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: C.dark));
    final chev = Icon(
        isRtl ? FontAwesomeIcons.angleLeft : FontAwesomeIcons.angleRight,
        size: 12,
        color: C.muted);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: isRtl
              ? [
                  chev,
                  Row(children: [text, const SizedBox(width: 12), iconBox]),
                ]
              : [
                  Row(children: [iconBox, const SizedBox(width: 12), text]),
                  chev,
                ],
        ),
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isRtl = AppLocale.current.languageCode == 'ar';
    final iconBox = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 14, color: color),
    );
    final labelText = Text(label,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: C.dark));
    final valueText = Text(value,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: C.primary));
    final chev = Icon(
        isRtl ? FontAwesomeIcons.angleLeft : FontAwesomeIcons.angleRight,
        size: 12,
        color: C.muted);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: isRtl
              ? [
                  Row(children: [chev, const SizedBox(width: 8), valueText]),
                  Row(children: [labelText, const SizedBox(width: 12), iconBox]),
                ]
              : [
                  Row(children: [iconBox, const SizedBox(width: 12), labelText]),
                  Row(children: [valueText, const SizedBox(width: 8), chev]),
                ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final isRtl = AppLocale.current.languageCode == 'ar';
    final iconBox = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 14, color: color),
    );
    final labelText = Text(label,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: C.dark));
    final valueText = Text(value,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: C.muted));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: isRtl
            ? [
                valueText,
                Row(children: [labelText, const SizedBox(width: 12), iconBox]),
              ]
            : [
                Row(children: [iconBox, const SizedBox(width: 12), labelText]),
                valueText,
              ],
      ),
    );
  }

  // ══════════ ACTIONS ══════════
  Future<void> _pickLanguage() async {
    final options = const [
      {'code': 'ar', 'name': 'العربية'},
      {'code': 'en', 'name': 'English'},
      {'code': 'fr', 'name': 'Français'},
    ];
    final current = AppLocale.current.languageCode;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('settings_pick_language'),
            style: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((o) => RadioListTile<String>(
                    title: Text(o['name']!,
                        style: const TextStyle(fontFamily: 'Tajawal')),
                    value: o['code']!,
                    groupValue: current,
                    activeColor: C.primary,
                    onChanged: (v) => Navigator.pop(ctx, v),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null && selected != current) {
      await AppLocale.set(selected);
      if (mounted) setState(() {});
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('help_title'),
            style: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
        content: Text(
          tr('help_body'),
          style: const TextStyle(fontFamily: 'Tajawal', height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('ok'),
                style: const TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('terms_title'),
            style: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Text(
            tr('terms_body'),
            style: const TextStyle(
                fontFamily: 'Tajawal', height: 1.6, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('ok'),
                style: const TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }
}
