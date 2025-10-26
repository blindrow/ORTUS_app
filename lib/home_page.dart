import 'package:flutter/material.dart';

// Главная страница
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF409187);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Главная',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: primaryColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 25),
            Text(
              'Сегодня ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} г.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Выберите "Расписание" внизу для просмотра занятий.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
