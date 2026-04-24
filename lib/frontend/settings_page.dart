import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import 'security_page.dart';
import 'feedback_page.dart';
import '../backend/firebase_service.dart';

// ════════════════════════════════════════════
//  صفحة الإعدادات العامة
// ════════════════════════════════════════════
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // إعدادات محلية داخل الجلسة (غير مُخزّنة بعد)
  bool _pushNotifications = true;
  bool _bookingAlerts = true;
  bool _soundEffects = true;
  bool _locationServices = true;
  String _language = 'العربية';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.light,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _sectionTitle('الإشعارات', FontAwesomeIcons.bell),
            _buildCard([
              _switchTile(
                icon: FontAwesomeIcons.bell,
                color: const Color(0xFFF97316),
                label: 'تفعيل الإشعارات',
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
              _divider(),
              _switchTile(
                icon: FontAwesomeIcons.squareParking,
                color: C.primary,
                label: 'تنبيهات الحجوزات',
                value: _bookingAlerts,
                onChanged: (v) => setState(() => _bookingAlerts = v),
              ),
              _divider(),
              _switchTile(
                icon: FontAwesomeIcons.volumeHigh,
                color: C.accent,
                label: 'المؤثرات الصوتية',
                value: _soundEffects,
                onChanged: (v) => setState(() => _soundEffects = v),
              ),
            ]),
            const SizedBox(height: 16),
            _sectionTitle('الخصوصية والأمان', FontAwesomeIcons.shieldHalved),
            _buildCard([
              _navTile(
                icon: FontAwesomeIcons.key,
                color: C.secondary,
                label: 'كلمة المرور والأمان',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecurityPage()),
                ),
              ),
              _divider(),
              _switchTile(
                icon: FontAwesomeIcons.locationDot,
                color: C.success,
                label: 'خدمات الموقع',
                value: _locationServices,
                onChanged: (v) => setState(() => _locationServices = v),
              ),
            ]),
            const SizedBox(height: 16),
            _sectionTitle('التفضيلات', FontAwesomeIcons.sliders),
            _buildCard([
              _pickerTile(
                icon: FontAwesomeIcons.language,
                color: C.primary,
                label: 'اللغة',
                value: _language,
                onTap: _pickLanguage,
              ),
            ]),
            const SizedBox(height: 16),
            _sectionTitle('عن التطبيق', FontAwesomeIcons.circleInfo),
            _buildCard([
              _navTile(
                icon: FontAwesomeIcons.star,
                color: C.warning,
                label: 'آراء المستخدمين',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackPage()),
                ),
              ),
              _divider(),
              _navTile(
                icon: FontAwesomeIcons.circleQuestion,
                color: C.muted,
                label: 'المساعدة والدعم',
                onTap: _showHelpDialog,
              ),
              _divider(),
              _navTile(
                icon: FontAwesomeIcons.fileLines,
                color: C.accent,
                label: 'شروط الاستخدام',
                onTap: _showTerms,
              ),
              _divider(),
              _infoTile(
                icon: FontAwesomeIcons.codeBranch,
                color: C.dark,
                label: 'إصدار التطبيق',
                value: '1.0.0',
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ══════════ HEADER ══════════
  Widget _buildHeader() {
    final email = FirebaseService.currentUser?.email ?? '';
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
                  const Text('الإعدادات',
                      style: TextStyle(
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
                      child: const Icon(FontAwesomeIcons.arrowRight,
                          color: Colors.white, size: 14),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: C.dark)),
          const SizedBox(width: 6),
          Icon(icon, size: 12, color: C.muted),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: C.primary,
          ),
          Row(children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
            const SizedBox(width: 12),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 14, color: color),
            ),
          ]),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(FontAwesomeIcons.angleLeft, size: 12, color: C.muted),
            Row(children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: C.dark)),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 14, color: color),
              ),
            ]),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              const Icon(FontAwesomeIcons.angleLeft, size: 12, color: C.muted),
              const SizedBox(width: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: C.primary)),
            ]),
            Row(children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: C.dark)),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 14, color: color),
              ),
            ]),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: C.muted)),
          Row(children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
            const SizedBox(width: 12),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 14, color: color),
            ),
          ]),
        ],
      ),
    );
  }

  // ══════════ ACTIONS ══════════
  Future<void> _pickLanguage() async {
    final options = ['العربية', 'English', 'Français'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('اختر اللغة',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((o) => RadioListTile<String>(
                      title: Text(o,
                          style: const TextStyle(fontFamily: 'Tajawal')),
                      value: o,
                      groupValue: _language,
                      activeColor: C.primary,
                      onChanged: (v) => Navigator.pop(ctx, v),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) setState(() => _language = selected);
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('المساعدة والدعم',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          content: const Text(
            'للمساعدة والاستفسارات يمكنك التواصل معنا:\n\n'
            '• البريد: support@smartparking.dz\n'
            '• الهاتف: +213 555 000 000\n'
            '• ساعات العمل: 24/7',
            style: TextStyle(fontFamily: 'Tajawal', height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('موافق',
                  style: TextStyle(fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('شروط الاستخدام',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          content: const SingleChildScrollView(
            child: Text(
              'باستخدامك لتطبيق SmartParking فإنك توافق على:\n\n'
              '1. استخدام التطبيق للأغراض المشروعة فقط.\n'
              '2. تقديم بيانات صحيحة عن المركبة.\n'
              '3. الالتزام بمواعيد الحجز.\n'
              '4. احترام الأنظمة والقوانين المحلية.\n\n'
              'يحق للإدارة إلغاء أي حجز في حالة المخالفة.',
              style: TextStyle(fontFamily: 'Tajawal', height: 1.6, fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('موافق',
                  style: TextStyle(fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }
}
