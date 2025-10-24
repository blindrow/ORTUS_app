import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async'; 

// ИСПРАВЛЕННЫЙ ИМПОРТ:
import 'package:flutter_application_1/main_screen.dart';

void main() async {
  // Инициализация для корректной работы локализации TableCalendar
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schedule App',
      debugShowCheckedModeBanner: false, // Убираем DEBUG баннер
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Убираем круглую вспышку при нажатии
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      locale: const Locale('ru', 'RU'),
      // Точка входа в ваше расписание
      home: const MainScreen(),
    );
  }
}