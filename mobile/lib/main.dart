import 'dart:ui' as ui;
import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Supabase configuration is missing. Build with SUPABASE_URL and SUPABASE_ANON_KEY dart-defines.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: JawadainApp()));
}

class JawadainApp extends StatelessWidget {
  const JawadainApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF5876D8);
    return MaterialApp(
      title: 'مدرسة الجوادين الإلكترونية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFE8EAFE),
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF26345E),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const AuthGate(),
    );
  }
}


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? client.auth.currentSession;
        return session == null ? const SchoolHomeScreen() : const AdminDashboardScreen();
      },
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool busy = false;
  bool obscurePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      setState(() => errorMessage = 'يرجى إدخال البريد الإلكتروني وكلمة المرور.');
      return;
    }
    setState(() { busy = true; errorMessage = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        (route) => route.isFirst,
      );
    } on AuthException catch (e) {
      setState(() => errorMessage = e.message);
    } catch (_) {
      setState(() => errorMessage = 'تعذر تسجيل الدخول. تحقق من الاتصال وحاول مجدداً.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5876D8);
    const ink = Color(0xFF26345E);
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8EAFE),
        appBar: AppBar(title: const Text('دخول الإدارة')),
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFF6E9F0), Color(0xFFDCE2FF), Color(0xFF8299ED)])),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: .9))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircleAvatar(radius: 35, backgroundColor: Color(0xFFE8ECFF),
                    child: Icon(Icons.admin_panel_settings_rounded, color: primary, size: 38)),
                  const SizedBox(height: 16),
                  const Text('بوابة إدارة مدرسة الجوادين',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: ink)),
                  const SizedBox(height: 7),
                  const Text('سجّل الدخول باستخدام حساب المدير',
                    style: TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: ui.TextDirection.ltr,
                    decoration: InputDecoration(labelText: 'البريد الإلكتروني',
                      prefixIcon: const Icon(Icons.email_outlined), filled: true,
                      fillColor: Colors.white.withValues(alpha: .7),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    onSubmitted: (_) { if (!busy) login(); },
                    decoration: InputDecoration(labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
                      filled: true, fillColor: Colors.white.withValues(alpha: .7),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 50,
                    child: FilledButton(
                      onPressed: busy ? null : login,
                      child: busy ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('تسجيل الدخول'))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<String> _adminName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'مدير المدرسة';
    final row = await Supabase.instance.client.from('profiles')
      .select('full_name, role, is_active').eq('id', user.id).maybeSingle();
    if (row == null || row['role'] != 'admin' || row['is_active'] != true) {
      await Supabase.instance.client.auth.signOut();
      throw const AuthException('هذا الحساب غير مخوّل لدخول لوحة الإدارة.');
    }
    return (row['full_name'] as String?) ?? 'مدير المدرسة';
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF26345E);
    const primary = Color(0xFF5876D8);
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('لوحة إدارة المدرسة'),
          actions: [IconButton(tooltip: 'تسجيل الخروج',
            onPressed: () async { await Supabase.instance.client.auth.signOut(); },
            icon: const Icon(Icons.logout_rounded))]),
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFF6E9F0), Color(0xFFDCE2FF), Color(0xFF8299ED)])),
          child: FutureBuilder<String>(
            future: _adminName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Padding(padding: const EdgeInsets.all(24),
                  child: Text(snapshot.error.toString(), textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red))));
              }
              return ListView(padding: const EdgeInsets.all(20), children: [
                Container(padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .62),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: .9))),
                  child: Row(children: [
                    const CircleAvatar(radius: 28, backgroundColor: Color(0xFFE8ECFF),
                      child: Icon(Icons.person_rounded, color: primary, size: 30)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('مرحباً بك', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      Text(snapshot.data!, style: const TextStyle(color: ink,
                        fontWeight: FontWeight.bold, fontSize: 17)),
                      const Text('صلاحية مدير المدرسة', style: TextStyle(color: primary, fontSize: 11)),
                    ])),
                  ])),
                const SizedBox(height: 22),
                const Text('إدارة المدرسة', style: TextStyle(color: ink,
                  fontWeight: FontWeight.bold, fontSize: 19)),
                const SizedBox(height: 12),
                const _AdminTile(icon: Icons.people_alt_outlined, title: 'الطلبة', subtitle: 'إدارة ملفات الطلبة'),
                const _AdminTile(icon: Icons.class_outlined, title: 'الصفوف والشُعب', subtitle: 'إدارة الصفوف الدراسية'),
                const _AdminTile(icon: Icons.fact_check_outlined, title: 'الحضور والغياب', subtitle: 'متابعة سجلات الحضور'),
                const _AdminTile(icon: Icons.grade_outlined, title: 'الدرجات والنتائج', subtitle: 'إدارة درجات الطلبة'),
                const _AdminTile(icon: Icons.campaign_outlined, title: 'الإعلانات', subtitle: 'نشر إعلانات المدرسة'),
                const _AdminTile(icon: Icons.calendar_month_outlined, title: 'الجدول الدراسي', subtitle: 'تنظيم الحصص والجداول'),
                const SizedBox(height: 12),
                const Text('هذه أقسام الواجهة الأولية؛ سيتم تفعيل عمليات الإضافة والتعديل والحفظ تدريجياً.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 11, height: 1.6)),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .52),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .85))),
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF5876D8)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left_rounded),
    ),
  );
}

class SchoolHomeScreen extends StatefulWidget {
  const SchoolHomeScreen({super.key});

  @override
  State<SchoolHomeScreen> createState() => _SchoolHomeScreenState();
}

class _SchoolHomeScreenState extends State<SchoolHomeScreen> {
  int selectedIndex = 0;
  late DateTime now;
  Timer? clockTimer;

  static const green = Color(0xFF5876D8);
  static const ink = Color(0xFF26345E);
  static const news = [
    'أهلاً وسهلاً بكم في تطبيق مدرسة الجوادين الإلكتروني',
    'تابعوا إعلانات المدرسة والتعليمات عبر هذه النافذة',
    'سيتم نشر الأخبار الرسمية بعد ربط لوحة الإدارة',
  ];

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    super.dispose();
  }

  void openService(String title, String description, IconData icon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 42, height: 4, decoration: BoxDecoration(
              color: Colors.black12, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 22),
            CircleAvatar(radius: 30, backgroundColor: green.withValues(alpha: .10),
              child: Icon(icon, color: green, size: 30)),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ink)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.7)),
            const SizedBox(height: 18),
            const Text('هذه الخدمة قيد التجهيز وسيتم تفعيلها بعد ربط قاعدة البيانات وتسجيل الدخول.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.deepOrange)),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homePage(),
      _servicesPage(),
      _aboutPage(),
    ];
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: green.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.school_rounded, color: green, size: 25)),
            const SizedBox(width: 10),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('مدرسة الجوادين', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text('التطبيق الإلكتروني', style: TextStyle(fontSize: 11, color: Colors.black54)),
            ])),
          ]),
          actions: [
            IconButton(
              tooltip: 'دخول الإدارة',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
            IconButton(onPressed: () => openService('الإشعارات', 'ستظهر هنا إشعارات المدرسة وأخبارها الرسمية.', Icons.notifications_none_rounded),
              icon: const Icon(Icons.notifications_none_rounded)),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFF6E9F0), Color(0xFFDCE2FF), Color(0xFF8299ED)],
            stops: [0.0, 0.52, 1.0],
          )),
          child: IndexedStack(index: selectedIndex, children: pages),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => setState(() => selectedIndex = i),
          backgroundColor: const Color(0xDDF4F6FF),
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0xFFCBD6FF),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'الخدمات'),
            NavigationDestination(icon: Icon(Icons.info_outline_rounded), label: 'عن المدرسة'),
          ],
        ),
      ),
    );
  }

  Widget _homePage() => ListView(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
    children: [
      _welcomeCard(),
      const SizedBox(height: 14),
      _newsBar(),
      const SizedBox(height: 24),
      _sectionTitle('الخدمات المدرسية', 'اختر الخدمة المطلوبة'),
      const SizedBox(height: 13),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.22,
        children: [
          _serviceCard('الجدول الدراسي', Icons.calendar_month_rounded, const Color(0xFF3978B8), 'عرض الجداول والحصص الدراسية.'),
          _serviceCard('النتائج والدرجات', Icons.assignment_turned_in_outlined, const Color(0xFF8B65B5), 'متابعة نتائج الطالب ودرجاته.'),
          _serviceCard('الغياب والحضور', Icons.fact_check_outlined, const Color(0xFFD28B35), 'متابعة سجل الحضور والغياب.'),
          _serviceCard('الإعلانات', Icons.campaign_outlined, const Color(0xFF278B79), 'آخر إعلانات وتنبيهات المدرسة.'),
          _serviceCard('مكتبة الصور', Icons.photo_library_outlined, const Color(0xFFB56D79), 'الفعاليات والأنشطة المدرسية.'),
          _serviceCard('تواصل معنا', Icons.call_outlined, const Color(0xFF557A88), 'قنوات التواصل مع إدارة المدرسة.'),
        ],
      ),
      const SizedBox(height: 22),
      _sectionTitle('بوابة ولي الأمر', 'خدمات متابعة الأبناء'),
      const SizedBox(height: 12),
      _parentCard(),
      const SizedBox(height: 20),
      const Center(child: Text('مدرسة الجوادين © 2026', style: TextStyle(color: Colors.black45, fontSize: 11))),
    ],
  );

  Widget _welcomeCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.white.withValues(alpha: .78), const Color(0xFFDCE4FF).withValues(alpha: .62), const Color(0xFF9DB2F5).withValues(alpha: .72)],
        begin: Alignment.topRight, end: Alignment.bottomLeft),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: Colors.white.withValues(alpha: .85), width: 1.2),
      boxShadow: [BoxShadow(color: const Color(0xFF536FC4).withValues(alpha: .16), blurRadius: 24, offset: const Offset(0, 10))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('مرحباً بكم في\nمدرسة الجوادين',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.45))),
        Container(width: 62, height: 62,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 34)),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        const Icon(Icons.access_time_rounded, color: Colors.white70, size: 17),
        const SizedBox(width: 7),
        Text(DateFormat('hh:mm:ss a', 'en').format(now), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(DateFormat('yyyy/MM/dd', 'en').format(now), style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    ]),
  );

  Widget _newsBar() => Container(
    height: 52, padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .48), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: .8))),
    child: Row(children: [
      const Icon(Icons.campaign_rounded, color: green),
      const SizedBox(width: 8),
      const Text('الأخبار', style: TextStyle(color: ink, fontWeight: FontWeight.bold, fontSize: 12)),
      const SizedBox(width: 10),
      Container(width: 1, height: 23, color: green.withValues(alpha: .2)),
      const SizedBox(width: 10),
      Expanded(child: _NewsTicker(items: news)),
    ]),
  );

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ]);

  Widget _serviceCard(String title, IconData icon, Color color, String description) =>
    ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withValues(alpha: .38),
          child: InkWell(
            onTap: () => openService(title, description, icon),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Colors.white.withValues(alpha: .70), Colors.white.withValues(alpha: .28)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: .88), width: 1.1),
                boxShadow: [BoxShadow(color: const Color(0xFF526FC5).withValues(alpha: .10), blurRadius: 18, offset: const Offset(0, 7))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(width: 43, height: 43,
                  decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, color: color, size: 24)),
                Row(children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ink))),
                  const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: Colors.black38),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );

  Widget _parentCard() => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .48),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .9)),
        ),
        child: Row(children: [
      const CircleAvatar(backgroundColor: Color(0xFFE8F2ED), child: Icon(Icons.family_restroom_rounded, color: green)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('متابعة الطالب', style: TextStyle(fontWeight: FontWeight.bold, color: ink)),
        Text('الدخول إلى حساب ولي الأمر', style: TextStyle(fontSize: 11, color: Colors.black54)),
      ])),
      FilledButton.tonal(onPressed: () => openService('بوابة ولي الأمر', 'سيتم تفعيل حسابات أولياء الأمور وربطها بملفات الطلبة.', Icons.family_restroom_rounded),
        child: const Text('دخول')),
        ]),
      ),
    ),
  );

  Widget _servicesPage() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const Text('جميع الخدمات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ink)),
      const SizedBox(height: 6),
      const Text('اختر إحدى خدمات المدرسة للوصول إلى تفاصيلها.', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 18),
      ...[
        ['الجدول الدراسي', Icons.calendar_month_rounded, 'الجداول والحصص الدراسية.'],
        ['النتائج والدرجات', Icons.grade_rounded, 'درجات ونتائج الطلبة.'],
        ['الغياب والحضور', Icons.fact_check_outlined, 'سجل حضور وغياب الطلبة.'],
        ['الإعلانات والأخبار', Icons.campaign_outlined, 'التعاميم والإعلانات الرسمية.'],
        ['الأنشطة المدرسية', Icons.event_available_rounded, 'الفعاليات والأنشطة.'],
        ['التواصل مع الإدارة', Icons.support_agent_rounded, 'التواصل والاستفسارات.'],
      ].map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          tileColor: Colors.white.withValues(alpha: .52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: BorderSide(color: Colors.white.withValues(alpha: .8))),
          leading: CircleAvatar(backgroundColor: const Color(0xFFE8F2ED), child: Icon(item[1] as IconData, color: green)),
          title: Text(item[0] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item[2] as String),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: () => openService(item[0] as String, item[2] as String, item[1] as IconData),
        ),
      )),
    ],
  );

  Widget _aboutPage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 25),
      const CircleAvatar(radius: 48, backgroundColor: Color(0xFFE8F2ED),
        child: Icon(Icons.school_rounded, size: 52, color: green)),
      const SizedBox(height: 18),
      const Center(child: Text('مدرسة الجوادين', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: ink))),
      const SizedBox(height: 8),
      const Center(child: Text('التطبيق الإلكتروني الرسمي للمدرسة', style: TextStyle(color: Colors.black54))),
      const SizedBox(height: 25),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .52),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .88)),
            ),
            child: const Text(
              'تهدف هذه المنصة إلى تسهيل التواصل بين المدرسة وأولياء الأمور، وتوفير الخدمات والمعلومات المدرسية في مكان واحد.',
              textAlign: TextAlign.center, style: TextStyle(height: 1.8, color: ink)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const ListTile(leading: Icon(Icons.verified_user_outlined, color: green), title: Text('منصة مدرسية قيد التطوير')),
      const ListTile(leading: Icon(Icons.calendar_today_outlined, color: green), title: Text('الإصدار التجريبي 2026')),
    ],
  );
}

class _NewsTicker extends StatefulWidget {
  const _NewsTicker({required this.items});
  final List<String> items;

  @override
  State<_NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<_NewsTicker> {
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => index = (index + 1) % widget.items.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 450),
    transitionBuilder: (child, animation) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(-.25, 0), end: Offset.zero).animate(animation),
      child: FadeTransition(opacity: animation, child: child)),
    child: Text(widget.items[index], key: ValueKey(index), maxLines: 1,
      overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF315D4D))),
  );
}
