import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: JawadainApp()));
}

class JawadainApp extends StatelessWidget {
  const JawadainApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF78998A);
    return MaterialApp(
      title: 'مدرسة الجوادين الإلكترونية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF7F8F6),
        fontFamily: 'Cairo',
      ),
      home: const SetupNoticeScreen(),
    );
  }
}

class SetupNoticeScreen extends StatelessWidget {
  const SetupNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مدرسة الجوادين')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined, size: 52),
                    const SizedBox(height: 16),
                    Text('مرحباً بكم في مدرسة الجوادين',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'تم تجهيز الهيكل الأولي. لم يتم إعداد اتصال قاعدة البيانات بعد؛ لذلك لن يتم عرض بيانات مدرسية وهمية.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
