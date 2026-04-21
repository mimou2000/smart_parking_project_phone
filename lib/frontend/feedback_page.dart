import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import '../backend/firebase_service.dart';

// ════════════════════════════════════════════
//  صفحة التقييمات الكاملة (تبويبان)
// ════════════════════════════════════════════
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.light,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const QuickFeedbackForm(showTitle: true),
                    const SizedBox(height: 24),
                  ]),
                ),
                const _AllFeedbackTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.panelDark1, C.panelDark2],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: C.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  Icon(FontAwesomeIcons.star, color: C.warning, size: 11),
                  SizedBox(width: 5),
                  Text("ملاحظاتك تهمّنا",
                      style: TextStyle(
                          color: C.warning, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
              const Text("التقييمات",
                  style: TextStyle(
                      color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: C.white,
      child: TabBar(
        controller: _tab,
        labelColor: C.primary,
        unselectedLabelColor: C.muted,
        indicatorColor: C.primary,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Tajawal'),
        tabs: const [
          Tab(text: "أرسل تقييماً"),
          Tab(text: "جميع التقييمات"),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
//  QuickFeedbackForm — مستقل قابل لإعادة الاستخدام
//  يُستخدم في: FeedbackPage + search bottom sheet + booking page
// ════════════════════════════════════════════
class QuickFeedbackForm extends StatefulWidget {
  final bool showTitle;
  final String? prefillCategory; // مثلاً "تجربة الحجز"
  final VoidCallback? onSubmitted;

  const QuickFeedbackForm({
    super.key,
    this.showTitle = false,
    this.prefillCategory,
    this.onSubmitted,
  });

  @override
  State<QuickFeedbackForm> createState() => _QuickFeedbackFormState();
}

class _QuickFeedbackFormState extends State<QuickFeedbackForm> {
  int     _rating    = 0;
  String? _category;
  bool    _loading   = false;
  bool    _submitted = false;
  String? _errorMsg;

  final _msgCtrl = TextEditingController();

  final List<String> _categories = [
    'عام', 'تجربة الحجز', 'السعر', 'التطبيق', 'خدمة العملاء', 'اقتراح'
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.prefillCategory ?? 'عام';
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _errorMsg = 'يرجى اختيار تقييم بالنجوم');
      return;
    }
    if (_msgCtrl.text.trim().length < 10) {
      setState(() => _errorMsg = 'الرجاء كتابة ملاحظة مفصّلة (10 أحرف على الأقل)');
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId':    FirebaseService.uid,
        'rating':    _rating,
        'category':  _category,
        'message':   _msgCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status':    'pending',
      });

      if (!mounted) return;
      setState(() { _loading = false; _submitted = true; });
      widget.onSubmitted?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _errorMsg = 'فشل الإرسال، حاول مجدداً'; });
    }
  }

  void _reset() => setState(() {
    _rating = 0;
    _category = widget.prefillCategory ?? 'عام';
    _submitted = false;
    _errorMsg = null;
    _msgCtrl.clear();
  });

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── بطاقة النجوم ──
        _card(child: Column(children: [
          if (widget.showTitle) ...[
            const Text("كيف كانت تجربتك؟",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.dark)),
            const SizedBox(height: 4),
            const Text("اختر تقييمك من 1 إلى 5 نجوم",
                style: TextStyle(fontSize: 11, color: C.muted)),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final n = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = n),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      key: ValueKey(n <= _rating),
                      n <= _rating
                          ? FontAwesomeIcons.solidStar
                          : FontAwesomeIcons.star,
                      color: n <= _rating ? C.warning : C.border,
                      size: n <= _rating ? 34 : 28,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 10),
            Text(_ratingLabel(_rating),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: _ratingColor(_rating))),
          ],
        ])),

        const SizedBox(height: 12),

        // ── فئات ──
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text("نوع الملاحظة",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.dark)),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8, runSpacing: 8,
            children: _categories.map((cat) {
              final sel = _category == cat;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? const LinearGradient(colors: [C.primary, C.secondary])
                        : null,
                    color: sel ? null : C.light,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? Colors.transparent : C.border, width: 1.5),
                  ),
                  child: Text(cat,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: sel ? C.white : C.muted)),
                ),
              );
            }).toList(),
          ),
        ])),

        const SizedBox(height: 12),

        // ── حقل النص ──
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text("ملاحظاتك",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.dark)),
          const SizedBox(height: 10),
          TextField(
            controller: _msgCtrl,
            maxLines: 4,
            maxLength: 500,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 13, color: C.dark),
            decoration: InputDecoration(
              hintText: "اكتب ملاحظاتك هنا...",
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true, fillColor: C.light,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: C.border, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: C.primary, width: 1.5)),
              contentPadding: const EdgeInsets.all(14),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ])),

        // خطأ
        if (_errorMsg != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: C.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.error.withOpacity(0.3)),
            ),
            child: Row(children: [
              const SizedBox(width: 6),
              Expanded(child: Text(_errorMsg!, textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: C.error, fontWeight: FontWeight.w700))),
              const Icon(FontAwesomeIcons.circleXmark, size: 13, color: C.error),
            ]),
          ),
        ],

        const SizedBox(height: 16),

        // زر الإرسال
        GestureDetector(
          onTap: _loading ? null : _submit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: _loading ? null : const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [C.primary, C.secondary]),
              color: _loading ? C.border : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _loading ? [] : [BoxShadow(
                  color: C.primary.withOpacity(0.35),
                  blurRadius: 14, offset: const Offset(0, 5))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (_loading) ...[
                const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white))),
                const SizedBox(width: 10),
                const Text("جاري الإرسال...",
                    style: TextStyle(color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ] else ...[
                const Icon(FontAwesomeIcons.paperPlane,
                    color: Colors.white, size: 14),
                const SizedBox(width: 10),
                const Text("إرسال التقييم",
                    style: TextStyle(color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [C.success, Color(0xFF059669)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
                color: C.success.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Icon(FontAwesomeIcons.circleCheck,
              color: Colors.white, size: 34),
        ),
        const SizedBox(height: 20),
        const Text("شكراً على تقييمك!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.dark)),
        const SizedBox(height: 8),
        const Text("لقد تلقّينا ملاحظاتك وسنعمل على تحسين خدماتنا",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: C.muted, height: 1.6)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _reset,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [C.primary, C.secondary]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: C.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(FontAwesomeIcons.plus, color: Colors.white, size: 12),
              SizedBox(width: 8),
              Text("إرسال تقييم آخر",
                  style: TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: C.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 8,
          offset: const Offset(0, 3))],
    ),
    child: child,
  );

  String _ratingLabel(int r) => switch (r) {
    1 => 'سيء جداً',
    2 => 'سيء',
    3 => 'مقبول',
    4 => 'جيد',
    _ => 'ممتاز 🎉',
  };

  Color _ratingColor(int r) => switch (r) {
    1 || 2 => C.error,
    3      => C.warning,
    _      => C.success,
  };
}

// ════════════════════════════════════════════
//  تبويب عرض جميع التقييمات
// ════════════════════════════════════════════
class _AllFeedbackTab extends StatelessWidget {
  const _AllFeedbackTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: C.primary));
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(FontAwesomeIcons.commentSlash, size: 36,
                  color: C.muted.withOpacity(0.3)),
              const SizedBox(height: 12),
              const Text("لا توجد تقييمات بعد",
                  style: TextStyle(color: C.muted, fontSize: 14)),
            ]),
          );
        }

        final ratings = docs.map((d) => (d['rating'] as int? ?? 0)).toList();
        final avg = ratings.fold(0, (a, b) => a + b) / ratings.length;

        return Column(children: [
          _buildSummaryBar(docs.length, avg),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _buildCard(docs[i]),
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildSummaryBar(int count, double avg) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [C.panelDark1, C.panelDark2],
            begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat(count.toString(), "تقييم", FontAwesomeIcons.commentDots, C.accent),
        Container(width: 1, height: 36, color: Colors.white24),
        _stat(avg.toStringAsFixed(1), "المتوسط", FontAwesomeIcons.star, C.warning),
        Container(width: 1, height: 36, color: Colors.white24),
        _stat("${(avg / 5 * 100).toInt()}%", "الرضا",
            FontAwesomeIcons.faceSmile, C.success),
      ]),
    );
  }

  Widget _stat(String val, String label, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(height: 5),
      Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
    ]);
  }

  Widget _buildCard(DocumentSnapshot doc) {
    final d       = doc.data() as Map<String, dynamic>;
    final rating  = (d['rating']   as int?)    ?? 0;
    final cat     = (d['category'] as String?) ?? 'عام';
    final message = (d['message']  as String?) ?? '';
    final ts      = d['createdAt'] as Timestamp?;
    final dateStr = ts != null ? _fmt(ts.toDate()) : '—';
    final rColor  = rating >= 4 ? C.success : rating == 3 ? C.warning : C.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8,
            offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(dateStr, style: const TextStyle(fontSize: 10, color: C.muted)),
          Row(children: [
            Row(children: List.generate(5, (i) => Icon(
              i < rating ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
              color: i < rating ? C.warning : C.border, size: 10,
            ))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: rColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(cat, style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w700, color: rColor)),
            ),
          ]),
        ]),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: C.dark, height: 1.55)),
      ]),
    );
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours   < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays    <  7) return 'منذ ${diff.inDays} يوم';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
