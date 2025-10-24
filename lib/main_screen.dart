import 'package:flutter/material.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:flutter_application_1/schedule_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 1. Устанавливаем 1, чтобы Расписание открывалось первым
  int _selectedIndex = 1; 

  // Список виджетов, которые будут отображаться на каждой вкладке
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const HomePage(),  // Индекс 0: Главная
      SchedulePage(),  // Индекс 1: Расписание
      // Индекс 2: Чат (Заглушка)
      const Center(
        child: Text(
          'Чат/Уведомления', 
          style: TextStyle(fontSize: 24, color: Colors.black54)
        ),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF409187);

    return Scaffold(
      // Отображаем выбранную страницу
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      
      // Нижняя панель навигации
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Расписание',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Чат',
          ),
        ],
        currentIndex: _selectedIndex, 
        selectedItemColor: primaryColor, 
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}