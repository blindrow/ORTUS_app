import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' as math;
import 'dart:async';

enum LessonType { regular, online, exam, changed }

enum LessonFormat { lecture, practice, lab }

enum ScheduleViewMode { day, week, month }

class Lesson {
  final String time;
  final String title;
  final String teacher;
  final String classroom;
  final Color baseColor;
  final LessonType type;
  final LessonFormat format;
  final String? examNote;
  final String deepLink;

  const Lesson({
    required this.time,
    required this.title,
    required this.teacher,
    required this.classroom,
    required this.baseColor,
    required this.type,
    required this.format,
    this.examNote,
    this.deepLink = '',
  });
}

class DailySchedule {
  final String day;
  final DateTime date;
  final List<Lesson> lessons;

  DailySchedule({required this.day, required this.date, required this.lessons});
}

// Painter для анимации загрузки по периметру рамки
class _BorderLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BorderLoadingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );

    final path = Path()..addRRect(rect);
    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;

    // Рисуем свечение (glow effect)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final currentLength = totalLength * progress;
    final glowPath = pathMetrics.extractPath(0, currentLength);
    canvas.drawPath(glowPath, glowPaint);

    // Рисуем основную линию с градиентом
    final mainPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.4), color, color],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final extractPath = pathMetrics.extractPath(0, currentLength);
    canvas.drawPath(extractPath, mainPaint);

    // Рисуем яркую точку на конце (leading dot)
    if (progress > 0 && progress < 1) {
      final dotPosition = pathMetrics
          .getTangentForOffset(currentLength)
          ?.position;
      if (dotPosition != null) {
        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(dotPosition, 2.5, dotPaint);

        final dotGlowPaint = Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(dotPosition, 4, dotGlowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BorderLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ScheduleService {
  static List<DailySchedule> fetchSchedule() {
    final now = DateTime.now();
    final monday = now.subtract(
      Duration(days: now.weekday - 1),
    ); // текущий понедельник

    List<DailySchedule> schedule = [];

    // Генерируем расписание на 8 недель (текущая + 3 назад + 4 вперед)
    for (int weekOffset = -3; weekOffset <= 4; weekOffset++) {
      final weekStart = monday.add(Duration(days: weekOffset * 7));
      schedule.addAll(_generateWeekSchedule(weekStart, weekOffset));
    }

    return schedule;
  }

  static List<DailySchedule> _generateWeekSchedule(
    DateTime weekStart,
    int weekOffset,
  ) {
    // Разное расписание для разных недель
    bool isCurrentWeek = weekOffset == 0;
    bool isPastWeek = weekOffset < 0;

    return [
      DailySchedule(
        day: 'Понедельник',
        date: weekStart,
        lessons: isCurrentWeek
            ? [
                const Lesson(
                  time: '08:30 - 10:00',
                  title: 'Информационные системы',
                  teacher: 'Иванов А.С.',
                  classroom: 'Ауд. 301',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lecture,
                ),
                const Lesson(
                  time: '10:15 - 11:45',
                  title: 'Английский язык (Онлайн)',
                  teacher: 'Петрова Е.Д.',
                  classroom: 'Zoom',
                  baseColor: Color(0xFFD4E6F1),
                  type: LessonType.online,
                  format: LessonFormat.practice,
                ),
                const Lesson(
                  time: '12:00 - 13:30',
                  title: 'Дискретная математика',
                  teacher: 'Кузнецов В.П.',
                  classroom: 'Ауд. 215',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lecture,
                ),
                const Lesson(
                  time: '14:00 - 15:30',
                  title: 'Операционные системы',
                  teacher: 'Петров А.Н.',
                  classroom: 'Ауд. 412',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lecture,
                ),
                const Lesson(
                  time: '15:45 - 17:15',
                  title: 'Компьютерная графика',
                  teacher: 'Зайцев В.А.',
                  classroom: 'Ауд. 501',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lab,
                ),
                const Lesson(
                  time: '17:30 - 19:00',
                  title: 'Веб-технологии',
                  teacher: 'Соколов Д.В.',
                  classroom: 'Ауд. 401',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lab,
                ),
                const Lesson(
                  time: '20:00 - 23:00',
                  title: 'Дополнительный курс',
                  teacher: 'Морозов Д.И.',
                  classroom: 'Ауд. 102',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lecture,
                  deepLink: 'com.microsoft.msapps://app123',
                ),
              ]
            : isPastWeek
            ? [
                const Lesson(
                  time: '09:00 - 10:30',
                  title: 'Математика',
                  teacher: 'Смирнов Г.П.',
                  classroom: 'Ауд. 202',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lecture,
                ),
                const Lesson(
                  time: '11:00 - 12:30',
                  title: 'История',
                  teacher: 'Орлов П.Т.',
                  classroom: 'Ауд. 305',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lecture,
                ),
                const Lesson(
                  time: '13:00 - 14:30',
                  title: 'Физика',
                  teacher: 'Волков Н.М.',
                  classroom: 'Ауд. 108',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.practice,
                ),
              ]
            : [
                const Lesson(
                  time: '08:30 - 10:00',
                  title: 'Физика',
                  teacher: 'Волков Н.М.',
                  classroom: 'Ауд. 108',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lecture,
                ),
                const Lesson(
                  time: '10:15 - 11:45',
                  title: 'Химия',
                  teacher: 'Лебедева О.К.',
                  classroom: 'Лаб. 210',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lab,
                ),
                const Lesson(
                  time: '12:00 - 13:30',
                  title: 'История',
                  teacher: 'Орлов П.Т.',
                  classroom: 'Ауд. 305',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lecture,
                ),
              ],
      ),
      DailySchedule(
        day: 'Вторник',
        date: weekStart.add(const Duration(days: 1)),
        lessons: [
          const Lesson(
            time: '08:30 - 10:00',
            title: 'Экономика предприятий (Лаб)',
            teacher: 'Сидоров И.А.',
            classroom: 'Лаб. 105',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lab,
          ),
          const Lesson(
            time: '10:15 - 11:45',
            title: 'Программирование',
            teacher: 'Новиков С.Д.',
            classroom: 'Ауд. 215',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.practice,
            examNote: '📝 Защита проекта',
          ),
          const Lesson(
            time: '12:00 - 13:30',
            title: 'Базы данных',
            teacher: 'Морозова Л.К.',
            classroom: 'Ауд. 320',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '14:00 - 15:30',
            title: 'Операционные системы',
            teacher: 'Петров А.Н.',
            classroom: 'Ауд. 412',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '15:45 - 17:15',
            title: 'Компьютерная графика',
            teacher: 'Зайцев В.А.',
            classroom: 'Ауд. 501',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lab,
          ),
          const Lesson(
            time: '17:30 - 19:00',
            title: 'Теория алгоритмов',
            teacher: 'Павлов К.Р.',
            classroom: 'Ауд. 305',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '20:00 - 23:00',
            title: 'Проектная работа',
            teacher: 'Иванов А.С.',
            classroom: 'Ауд. 301',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.practice,
          ),
        ],
      ),
      DailySchedule(
        day: 'Среда',
        date: weekStart.add(const Duration(days: 2)),
        lessons: [
          const Lesson(
            time: '08:30 - 10:00',
            title: 'Теория вероятностей',
            teacher: 'Григорьев М.А.',
            classroom: 'Ауд. 210',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '10:00 - 11:30',
            title: 'Алгоритмы и структуры данных',
            teacher: 'Павлов К.Р.',
            classroom: 'Ауд. 305',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '11:00 - 12:30',
            title: 'Философия',
            teacher: 'Козлова В.И.',
            classroom: 'Ауд. 410',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '12:00 - 13:30',
            title: 'Компьютерные сети',
            teacher: 'Федоров В.П.',
            classroom: 'Ауд. 412',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.practice,
          ),
          const Lesson(
            time: '12:45 - 14:15',
            title: 'Математический анализ',
            teacher: 'Смирнов Г.П.',
            classroom: 'Ауд. 202',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.practice,
          ),
          const Lesson(
            time: '14:30 - 16:00',
            title: 'Физика',
            teacher: 'Волков Н.М.',
            classroom: 'Ауд. 108',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '16:15 - 17:45',
            title: 'Искусственный интеллект',
            teacher: 'Новиков С.Д.',
            classroom: 'Ауд. 215',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '20:00 - 23:00',
            title: 'Машинное обучение',
            teacher: 'Новиков С.Д.',
            classroom: 'Ауд. 215',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lab,
          ),
        ],
      ),
      DailySchedule(
        day: 'Четверг',
        date: weekStart.add(const Duration(days: 3)),
        lessons: [
          const Lesson(
            time: '09:00 - 10:30',
            title: 'Сдача Долга по Физкультуре',
            teacher: 'Тренер А.В.',
            classroom: 'Спортзал',
            baseColor: Color(0xFFF9E79F),
            type: LessonType.changed,
            format: LessonFormat.practice,
          ),
          const Lesson(
            time: '11:00 - 12:30',
            title: 'Веб-разработка',
            teacher: 'Соколов Д.В.',
            classroom: 'Ауд. 401',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lab,
          ),
          const Lesson(
            time: '12:45 - 14:15',
            title: 'Мобильная разработка',
            teacher: 'Романов И.К.',
            classroom: 'Ауд. 502',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.practice,
          ),
          const Lesson(
            time: '14:30 - 16:00',
            title: 'Тестирование ПО',
            teacher: 'Белова А.С.',
            classroom: 'Ауд. 310',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '16:15 - 17:45',
            title: 'Проектирование ИС',
            teacher: 'Иванов А.С.',
            classroom: 'Ауд. 301',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.practice,
          ),
          const Lesson(
            time: '18:00 - 19:30',
            title: 'Безопасность ПО',
            teacher: 'Белова А.С.',
            classroom: 'Ауд. 310',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '20:00 - 23:00',
            title: 'Кибербезопасность',
            teacher: 'Белова А.С.',
            classroom: 'Ауд. 310',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lab,
          ),
        ],
      ),
      DailySchedule(
        day: 'Пятница',
        date: weekStart.add(const Duration(days: 4)),
        lessons: [
          const Lesson(
            time: '08:30 - 10:00',
            title: 'Английский язык',
            teacher: 'Петрова Е.Д.',
            classroom: 'Ауд. 205',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.practice,
          ),
          const Lesson(
            time: '10:00 - 11:30',
            title: 'Алгоритмы и структуры данных',
            teacher: 'Павлов К.Р.',
            classroom: 'Ауд. 305',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '12:00 - 13:30',
            title: 'Архитектура ПО',
            teacher: 'Кузнецов В.П.',
            classroom: 'Ауд. 215',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '14:30 - 16:00',
            title: 'Экзамен по Информатике',
            teacher: 'Иванов А.С.',
            classroom: 'Ауд. 301',
            baseColor: Color(0xFFD6EAF8),
            type: LessonType.exam,
            format: LessonFormat.lecture,
            examNote: '⚠️ Контрольная работа по алгоритмам',
          ),
          const Lesson(
            time: '16:15 - 17:45',
            title: 'Управление проектами',
            teacher: 'Соколов Д.В.',
            classroom: 'Ауд. 401',
            baseColor: defaultColor,
            type: LessonType.regular,
            format: LessonFormat.lecture,
          ),
          const Lesson(
            time: '21:00 - 23:00',
            title: 'Вечерний семинар по AI',
            teacher: 'Новиков М.А.',
            classroom: 'Онлайн',
            baseColor: defaultColor,
            type: LessonType.online,
            format: LessonFormat.lecture,
          ),
        ],
      ),
      DailySchedule(
        day: 'Суббота',
        date: weekStart.add(const Duration(days: 5)),
        lessons: isCurrentWeek
            ? [
                const Lesson(
                  time: '10:00 - 11:30',
                  title: 'Дополнительная математика',
                  teacher: 'Смирнов Г.П.',
                  classroom: 'Ауд. 202',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.practice,
                ),
                const Lesson(
                  time: '12:00 - 13:30',
                  title: 'Консультация по программированию',
                  teacher: 'Новиков С.Д.',
                  classroom: 'Ауд. 215',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.practice,
                ),
                const Lesson(
                  time: '14:00 - 15:30',
                  title: 'Разработка игр',
                  teacher: 'Романов И.К.',
                  classroom: 'Ауд. 502',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lab,
                ),
                const Lesson(
                  time: '16:00 - 17:30',
                  title: 'Графический дизайн',
                  teacher: 'Зайцев В.А.',
                  classroom: 'Ауд. 501',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.practice,
                ),
                const Lesson(
                  time: '18:00 - 19:30',
                  title: '3D моделирование',
                  teacher: 'Зайцев В.А.',
                  classroom: 'Ауд. 501',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lab,
                ),
                const Lesson(
                  time: '20:00 - 23:00',
                  title: 'Хакатон',
                  teacher: 'Команда преподавателей',
                  classroom: 'Ауд. 401',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.practice,
                ),
              ]
            : [],
      ),
      DailySchedule(
        day: 'Воскресенье',
        date: weekStart.add(const Duration(days: 6)),
        lessons: isCurrentWeek
            ? [
                const Lesson(
                  time: '10:00 - 11:30',
                  title: 'Йога и медитация',
                  teacher: 'Инструктор Светлана К.',
                  classroom: 'Спортзал',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.practice,
                ),
                const Lesson(
                  time: '12:00 - 13:30',
                  title: 'Английский разговорный клуб',
                  teacher: 'Петрова Е.Д.',
                  classroom: 'Ауд. 205',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.practice,
                ),
                const Lesson(
                  time: '14:00 - 15:30',
                  title: 'Шахматный турнир',
                  teacher: 'Студсовет',
                  classroom: 'Ауд. 101',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.practice,
                ),
                const Lesson(
                  time: '16:00 - 17:30',
                  title: 'Киноклуб',
                  teacher: 'Иванов А.С.',
                  classroom: 'Актовый зал',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.lecture,
                ),
                const Lesson(
                  time: '20:00 - 23:00',
                  title: 'Вечер настольных игр',
                  teacher: 'Студсовет',
                  classroom: 'Ауд. 301',
                  baseColor: defaultColor,
                  type: LessonType.regular,
                  format: LessonFormat.practice,
                ),
              ]
            : [],
      ),
    ];
  }
}

const Color defaultColor = Color(0xFFE8F5E8);

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with AutomaticKeepAliveClientMixin {
  // State variables
  late DateTime _currentDate; // Для Day view
  late DateTime _currentWeekDate; // Для Week view (отдельная навигация)
  late DateTime _monthViewDate; // Для Month view (отдельная навигация)
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late List<DailySchedule> fullSchedule;
  ScheduleViewMode _viewMode = ScheduleViewMode.week;
  ScheduleViewMode _previousViewMode = ScheduleViewMode.week;
  final Map<DateTime, List<dynamic>> _events = {};
  final Map<DateTime, List<int>> _expandedDays = {};
  int _navigationDirection = 1; // 1 = вправо (вперед), -1 = влево (назад)
  final Set<String> _expandedTiles = {}; // Отслеживание раскрытых свертков
  final Set<String> _viewedExams = {}; // Отслеживание просмотренных контрольных
  Timer? _snackbarDebounceTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isFirstLaunch = true; // Флаг первого запуска

  // Animation variables - ОТКЛЮЧЕНО
  // double _indicatorWidth = 0;
  // double _indicatorOffset = 0;
  final GlobalKey _switcherKey = GlobalKey();
  final GlobalKey _dayKey = GlobalKey();
  final GlobalKey _weekKey = GlobalKey();
  final GlobalKey _monthKey = GlobalKey();

  // Getter for view mode
  ScheduleViewMode get _currentMode => _viewMode;

  // Setter for view mode
  set _currentMode(ScheduleViewMode mode) {
    if (_viewMode != mode) {
      debugPrint(
        'EVENT: mode_switch | from: $_viewMode | to: $mode | timestamp: ${DateTime.now()}',
      );
      _previousViewMode = _viewMode;
      setState(() {
        _viewMode = mode;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentDate = DateTime(now.year, now.month, now.day);
    _currentWeekDate = DateTime(
      now.year,
      now.month,
      now.day,
    ); // Отдельная дата для Week view
    _monthViewDate = DateTime(
      now.year,
      now.month,
      now.day,
    ); // Отдельная дата для Month view
    _selectedDay = _currentDate;
    _focusedDay = _currentDate;
    fullSchedule = ScheduleService.fetchSchedule();

    // Initialize expanded days for the current week
    final startOfWeek = _getStartOfWeek(_currentDate);
    for (var i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      _expandedDays[day] = [0, 1, 2, 3, 4, 5, 6]; // Expand all days by default
    }

    // WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicatorPosition());

    // Первичная вибрация при первом запуске
    if (_isFirstLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final hasVibrator = await Vibration.hasVibrator() ?? false;
        if (hasVibrator) {
          Vibration.vibrate(duration: 100);
        }
        _isFirstLaunch = false;
        debugPrint(
          'EVENT: first_launch_vibration | timestamp: ${DateTime.now()}',
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _snackbarDebounceTimer?.cancel();
    super.dispose();
  }

  void _showExamSnackBar(String examNote) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                examNote,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF409187),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'ПОКАЗАТЬ',
          textColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.2),
          onPressed: () {
            // Прокрутка к контрольной будет добавлена позже
          },
        ),
      ),
    );
  }

  void _showDayPickerDialog() {
    debugPrint(
      'EVENT: quickjump_open | screen: day | timestamp: ${DateTime.now()}',
    );
    final activeColor = const Color(0xFF409187);
    final normalizedToday = _normalizeDate(DateTime.now());
    DateTime displayWeekStart = _getStartOfWeek(_currentDate);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              final displayWeekEnd = displayWeekStart.add(
                const Duration(days: 6),
              );

              // Определяем цвета для стрелок
              final prevWeekStart = displayWeekStart.subtract(
                const Duration(days: 7),
              );
              final nextWeekStart = displayWeekStart.add(
                const Duration(days: 7),
              );
              final isPrevWeekCurrent =
                  normalizedToday.isAfter(
                    prevWeekStart.subtract(const Duration(days: 1)),
                  ) &&
                  normalizedToday.isBefore(
                    prevWeekStart.add(const Duration(days: 7)),
                  );
              final isNextWeekCurrent =
                  normalizedToday.isAfter(
                    nextWeekStart.subtract(const Duration(days: 1)),
                  ) &&
                  normalizedToday.isBefore(
                    nextWeekStart.add(const Duration(days: 7)),
                  );

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Верх: стрелки + диапазон недели
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Стрелка назад (с кругом)
                        InkWell(
                          onTap: () {
                            setStateDialog(() {
                              displayWeekStart = displayWeekStart.subtract(
                                const Duration(days: 7),
                              );
                            });
                            setState(() {
                              _currentDate = displayWeekStart;
                            });
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPrevWeekCurrent
                                  ? activeColor.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isPrevWeekCurrent
                                    ? activeColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 3),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  size: 16,
                                  color: isPrevWeekCurrent
                                      ? activeColor
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Диапазон недели
                        Text(
                          '${_formatDate(displayWeekStart)} – ${_formatDate(displayWeekEnd)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        // Стрелка вперед (с кругом)
                        InkWell(
                          onTap: () {
                            setStateDialog(() {
                              displayWeekStart = displayWeekStart.add(
                                const Duration(days: 7),
                              );
                            });
                            setState(() {
                              _currentDate = displayWeekStart;
                            });
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isNextWeekCurrent
                                  ? activeColor.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isNextWeekCurrent
                                    ? activeColor
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: isNextWeekCurrent
                                    ? activeColor
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 7 кнопок дней недели
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (index) {
                        final day = displayWeekStart.add(Duration(days: index));
                        final normalizedDay = _normalizeDate(day);
                        final isToday = normalizedDay == normalizedToday;
                        final dayName = [
                          'Пн',
                          'Вт',
                          'Ср',
                          'Чт',
                          'Пт',
                          'Сб',
                          'Вс',
                        ][index];

                        final dayIsCurrentMonth =
                            day.month == DateTime.now().month &&
                            day.year == DateTime.now().year;
                        final isSelected =
                            _selectedDay != null &&
                            normalizedDay == _normalizeDate(_selectedDay!);
                        final isCurrentDate =
                            normalizedDay == _normalizeDate(_currentDate);

                        // Определяем цвета
                        Color textColor;
                        Color borderColor;
                        Color backgroundColor;

                        // Фон всегда на текущем дне (isToday)
                        backgroundColor = isToday
                            ? activeColor.withValues(alpha: 0.2)
                            : Colors.transparent;

                        // Обводка на выбранном дне (isCurrentDate)
                        if (isCurrentDate) {
                          borderColor = activeColor;
                          textColor = dayIsCurrentMonth
                              ? activeColor
                              : Colors.grey.shade600;
                        } else if (isToday) {
                          // Если сегодня, но не выбран - серая обводка
                          borderColor = Colors.grey.shade400;
                          textColor = activeColor;
                        } else {
                          // Обычный день
                          borderColor = Colors.grey.shade300;
                          textColor = dayIsCurrentMonth
                              ? activeColor
                              : Colors.grey.shade600;
                        }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  _currentDate = normalizedDay;
                                  _selectedDay = normalizedDay;
                                });
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dayName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      day.day.toString(),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showWeekPickerDialog() {
    debugPrint(
      'EVENT: quickjump_open | screen: week | timestamp: ${DateTime.now()}',
    );
    final activeColor = const Color(0xFF409187);
    final greyColor = const Color(0xFF757575);
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    // Начинаем с текущего месяца Week view
    DateTime displayMonth = DateTime(
      _currentWeekDate.year,
      _currentWeekDate.month,
      1,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              // Получаем все недели месяца
              List<Map<String, DateTime>> getWeeksInMonth(DateTime month) {
                final firstDay = DateTime(month.year, month.month, 1);
                final lastDay = DateTime(month.year, month.month + 1, 0);

                // Находим понедельник первой недели
                DateTime weekStart = _getStartOfWeek(firstDay);
                List<Map<String, DateTime>> weeks = [];

                while (weekStart.isBefore(lastDay) ||
                    weekStart.isAtSameMomentAs(lastDay)) {
                  final weekEnd = weekStart.add(const Duration(days: 6));
                  weeks.add({'start': weekStart, 'end': weekEnd});
                  weekStart = weekStart.add(const Duration(days: 7));
                }

                return weeks;
              }

              final weeks = getWeeksInMonth(displayMonth);
              final isCurrentMonth =
                  displayMonth.month == currentMonth &&
                  displayMonth.year == currentYear;
              final firstDay = DateTime(
                displayMonth.year,
                displayMonth.month,
                1,
              );
              final lastDay = DateTime(
                displayMonth.year,
                displayMonth.month + 1,
                0,
              );

              return Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Верх: стрелки + месяц и промежуток
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            setStateDialog(() {
                              displayMonth = DateTime(
                                displayMonth.year,
                                displayMonth.month - 1,
                                1,
                              );
                            });
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 3),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: Column(
                            children: [
                              // Название месяца (с заглавной буквы)
                              Text(
                                _capitalize(
                                  DateFormat(
                                    'MMMM',
                                    'ru_RU',
                                  ).format(displayMonth),
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isCurrentMonth
                                      ? activeColor
                                      : greyColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Промежуток месяца
                              Text(
                                '${_formatDate(firstDay)} – ${_formatDate(lastDay)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isCurrentMonth
                                      ? activeColor
                                      : greyColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        InkWell(
                          onTap: () {
                            setStateDialog(() {
                              displayMonth = DateTime(
                                displayMonth.year,
                                displayMonth.month + 1,
                                1,
                              );
                            });
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Список недель
                    ...weeks.map((week) {
                      final weekStart = week['start']!;
                      final weekEnd = week['end']!;
                      final weekStartNorm = _normalizeDate(weekStart);

                      // Проверяем, является ли это реальной текущей неделей (с today)
                      final today = _normalizeDate(DateTime.now());
                      final todayWeekStart = _getStartOfWeek(DateTime.now());
                      final isRealCurrentWeek =
                          weekStartNorm == _normalizeDate(todayWeekStart);

                      // Проверяем, является ли это выбранной неделей
                      final selectedWeekStart = _getStartOfWeek(
                        _currentWeekDate,
                      );
                      final isSelectedWeek =
                          weekStartNorm == _normalizeDate(selectedWeekStart);

                      // Определяем цвета для начала и конца недели
                      final startIsCurrentMonth =
                          weekStart.month == currentMonth &&
                          weekStart.year == currentYear;
                      final endIsCurrentMonth =
                          weekEnd.month == currentMonth &&
                          weekEnd.year == currentYear;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              _currentWeekDate = weekStart;
                            });
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isRealCurrentWeek
                                  ? activeColor.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelectedWeek
                                    ? activeColor
                                    : (isRealCurrentWeek
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade400),
                                width: 2,
                              ),
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: _formatDate(weekStart),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: startIsCurrentMonth
                                          ? activeColor
                                          : greyColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' – ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _formatDate(weekEnd),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: endIsCurrentMonth
                                          ? activeColor
                                          : greyColor,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showPowerAppsDialog() async {
    debugPrint('EVENT: powerapps_dialog_open | timestamp: ${DateTime.now()}');

    // Показываем диалог подтверждения
    final shouldOpen = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Крупный квадрат с логотипом
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF742774), Color(0xFFD946A0)],
                    ),
                  ),
                  child: const Icon(Icons.apps, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 20),
                // Текст
                const Text(
                  'Открыть Power Apps?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Кнопка ОТКРЫТЬ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF409187),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'ОТКРЫТЬ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Если пользователь подтвердил открытие
    if (shouldOpen == true) {
      debugPrint(
        'EVENT: powerapps_launch_confirmed | timestamp: ${DateTime.now()}',
      );
      await _launchPowerApps();
    } else {
      debugPrint(
        'EVENT: powerapps_launch_cancelled | timestamp: ${DateTime.now()}',
      );
    }
  }

  Future<void> _launchPowerApps() async {
    // Пробуем несколько вариантов URL схем для PowerApps
    final powerAppsUrls = [
      Uri.parse('com.microsoft.msapps://'),
      Uri.parse('powerapps://'),
      Uri.parse('ms-apps://'),
    ];

    bool launched = false;

    for (final url in powerAppsUrls) {
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          launched = true;
          debugPrint('PowerApps launched with: $url');
          break;
        }
      } catch (e) {
        debugPrint('Failed to launch with $url: $e');
        continue;
      }
    }

    // Если не удалось запустить - показываем snackbar
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Приложение Power Apps не установлено')),
            ],
          ),
          action: SnackBarAction(
            label: 'Установить',
            textColor: Colors.white,
            onPressed: () async {
              debugPrint(
                'EVENT: powerapps_install_clicked | timestamp: ${DateTime.now()}',
              );
              final storeUrl = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.microsoft.msapps',
              );
              try {
                await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Failed to open store URL: $e');
              }
            },
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFE67E22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        ),
      );
    }
  }

  void _showPowerAppsDialogOld() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.black54,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        debugPrint('PowerApps открывается...');
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF742774), Color(0xFFD946A0)],
                          ),
                        ),
                        child: const Text(
                          'Открыть',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  void _showMonthPickerDialog() {
    debugPrint(
      'EVENT: quickjump_open | screen: month | timestamp: ${DateTime.now()}',
    );
    final now = DateTime.now();
    int selectedYear = _monthViewDate.year;
    int selectedMonth = _monthViewDate.month;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: FadeTransition(
                opacity: animation,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF409187,
                                    ).withValues(alpha: 0.1),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_left,
                                    color: Color(0xFF409187),
                                  ),
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    selectedYear--;
                                  });
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: selectedYear == now.year
                                      ? const Color(0xFF409187)
                                      : Colors.grey.shade200,
                                ),
                                child: Text(
                                  '$selectedYear',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: selectedYear == now.year
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF409187,
                                    ).withValues(alpha: 0.1),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF409187),
                                  ),
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    selectedYear++;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              final month = index + 1;
                              final isCurrentMonth =
                                  month == now.month &&
                                  selectedYear == now.year;
                              final isSelected =
                                  month == selectedMonth &&
                                  selectedYear == _monthViewDate.year;
                              final isCurrentYear = selectedYear == now.year;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _monthViewDate = DateTime(
                                      selectedYear,
                                      month,
                                      1,
                                    );
                                  });
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCurrentMonth
                                        ? const Color(0xFF409187)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF409187)
                                          : (isCurrentYear
                                                ? const Color(
                                                    0xFF409187,
                                                  ).withValues(alpha: 0.3)
                                                : Colors.grey.shade300),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      DateFormat(
                                        'MMM',
                                        'ru',
                                      ).format(DateTime(2024, month)),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected || isCurrentMonth
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isCurrentMonth
                                            ? Colors.white
                                            : (isCurrentYear
                                                  ? const Color(0xFF409187)
                                                  : Colors.grey.shade600),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTeacherInfo(String teacherName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF409187,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF409187),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            teacherName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            final email =
                                '${teacherName.toLowerCase().replaceAll(' ', '.')}@university.lv';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Почта скопирована: $email'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(
                                  0xFF409187,
                                ).withValues(alpha: 0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.only(
                                  bottom: 20,
                                  left: 20,
                                  right: 20,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  size: 16,
                                  color: Color(0xFF409187),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${teacherName.toLowerCase().replaceAll(' ', '.')}@university.lv',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: Color(0xFF409187),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Преподаёт:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSubjectChip('Информационные системы'),
                            const SizedBox(height: 8),
                            _buildSubjectChip('Базы данных'),
                            const SizedBox(height: 8),
                            _buildSubjectChip('Программирование'),
                          ],
                        ),
                      ],
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

  Widget _buildSubjectChip(String subject) {
    return InkWell(
      onTap: () {
        debugPrint(
          'EVENT: subject_tap | screen: teacher_modal | subject: $subject | timestamp: ${DateTime.now()}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Загрузка: $subject'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF409187),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF409187).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF409187).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          subject,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF409187),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniWeekCalendar() {
    final startOfWeek = _getStartOfWeek(_currentDate);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final today = _normalizeDate(DateTime.now());

    final weekRangeText =
        '${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Диапазон недели
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            weekRangeText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        // Дни недели
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final day = startOfWeek.add(Duration(days: index));
            final isToday = day == today;
            final isSelected = _selectedDay != null && day == _selectedDay;
            final isCurrentMonth = day.month == _currentDate.month;

            final dayName = [
              'Пн',
              'Вт',
              'Ср',
              'Чт',
              'Пт',
              'Сб',
              'Вс',
            ][day.weekday - 1];
            final dayNumber = day.day.toString();

            Color textColor = isCurrentMonth
                ? Colors.green
                : const Color(0xFF9E9E9E);
            if (isToday || isSelected) textColor = Colors.white;

            BoxDecoration decoration = BoxDecoration();
            if (isToday) {
              decoration = BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF388E3C), width: 2),
              );
            } else if (isSelected) {
              decoration = BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
              );
            }

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                    _currentDate = day;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: decoration,
                  child: Column(
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  // Helper method to get schedule for a specific date
  DailySchedule _getScheduleForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);

    // Ищем расписание по дате
    for (var schedule in fullSchedule) {
      if (_normalizeDate(schedule.date) == normalizedDate) {
        return schedule;
      }
    }

    // Если не найдено, возвращаем пустое расписание
    return DailySchedule(
      day: DateFormat('EEEE', 'ru_RU').format(date),
      date: date,
      lessons: [],
    );
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Понедельник';
      case DateTime.tuesday:
        return 'Вторник';
      case DateTime.wednesday:
        return 'Среда';
      case DateTime.thursday:
        return 'Четверг';
      case DateTime.friday:
        return 'Пятница';
      case DateTime.saturday:
        return 'Суббота';
      case DateTime.sunday:
        return 'Воскресенье';
      default:
        return '';
    }
  }

  void _updateIndicatorPosition() {
    // ОТКЛЮЧЕНО - вызывало ошибки attached
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final buttonKey = _getKeyForMode(_currentMode);
    //   final buttonRenderBox = buttonKey.currentContext?.findRenderObject() as RenderBox?;
    //   final switcherRenderBox = _switcherKey.currentContext?.findRenderObject() as RenderBox?;

    //   if (buttonRenderBox != null && switcherRenderBox != null && switcherRenderBox.hasSize) {
    //     setState(() {
    //       _indicatorWidth = buttonRenderBox.size.width - 2.5;
    //       final buttonGlobalPos = buttonRenderBox.localToGlobal(Offset.zero).dx;
    //       final switcherGlobalPos = switcherRenderBox.localToGlobal(Offset.zero).dx;
    //       _indicatorOffset = (buttonGlobalPos - switcherGlobalPos) - 4.0;
    //     });
    //   }
    // });
  }

  GlobalKey _getKeyForMode(ScheduleViewMode mode) {
    switch (mode) {
      case ScheduleViewMode.day:
        return _dayKey;
      case ScheduleViewMode.week:
        return _weekKey;
      case ScheduleViewMode.month:
        return _monthKey;
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _changeDay(int delta) {
    debugPrint(
      'EVENT: day_change | screen: day | delta: $delta | timestamp: ${DateTime.now()}',
    );
    final oldDate = _currentDate;
    setState(() {
      _navigationDirection = delta;
      _currentDate = _normalizeDate(_currentDate.add(Duration(days: delta)));
    });

    _checkSkippedExams(oldDate, _currentDate);
  }

  void _checkSkippedExams(DateTime fromDate, DateTime toDate) {
    if ((toDate.difference(fromDate).inDays).abs() <= 1) return;

    _snackbarDebounceTimer?.cancel();
    _snackbarDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final start = fromDate.isBefore(toDate) ? fromDate : toDate;
      final end = fromDate.isAfter(toDate) ? fromDate : toDate;

      for (int i = 1; i < end.difference(start).inDays; i++) {
        final checkDate = start.add(Duration(days: i));
        final daily = _getScheduleForDate(checkDate);

        for (final lesson in daily.lessons) {
          if (lesson.examNote != null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Контрольная по ${lesson.title}')),
                  ],
                ),
                action: SnackBarAction(
                  label: 'Показать',
                  textColor: Colors.white,
                  onPressed: () async {
                    setState(() {
                      _currentDate = checkDate;
                    });

                    // Ждём обновления UI
                    await Future.delayed(const Duration(milliseconds: 300));

                    // Вибрация
                    final hasVibrator = await Vibration.hasVibrator() ?? false;
                    if (hasVibrator) {
                      Vibration.vibrate(duration: 200);
                    }

                    // TODO: Добавить автоскролл к уроку с контрольной
                    // Нужен ScrollController для реализации
                  },
                ),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFFE67E22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              ),
            );
            return;
          }
        }
      }
    });
  }

  void _changeWeek(int delta) {
    setState(() {
      _navigationDirection = delta;
      _currentWeekDate = _currentWeekDate.add(Duration(days: delta * 7));
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);
    return '$day.$month.$year';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  DateTime _getStartOfWeek(DateTime date) {
    int diff = date.weekday - 1;
    return _normalizeDate(date.subtract(Duration(days: diff)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const activeColor = Color(0xFF409187);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Расписание',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: activeColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModeSwitcher(activeColor),
              const SizedBox(height: 15),

              if (_currentMode == ScheduleViewMode.day) ...[
                _buildDayNavigator(context),
                const SizedBox(height: 12),
                _buildDayOfWeekDisplay(),
              ] else if (_currentMode == ScheduleViewMode.week)
                _buildWeekNavigator(context)
              else
                _buildMonthCalendar(context),

              const SizedBox(height: 20),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  // Определяем направление: День слева (-1), Неделя центр (0), Месяц справа (1)
                  double horizontalOffset = 0.0;

                  if (_previousViewMode != _currentMode) {
                    // День → Неделя: приходит справа
                    if (_currentMode == ScheduleViewMode.week &&
                        _previousViewMode == ScheduleViewMode.day) {
                      horizontalOffset = 1.0;
                    }
                    // День → Месяц: приходит справа
                    else if (_currentMode == ScheduleViewMode.month &&
                        _previousViewMode == ScheduleViewMode.day) {
                      horizontalOffset = 1.0;
                    }
                    // Неделя → День: приходит слева
                    else if (_currentMode == ScheduleViewMode.day &&
                        _previousViewMode == ScheduleViewMode.week) {
                      horizontalOffset = -1.0;
                    }
                    // Неделя → Месяц: приходит справа
                    else if (_currentMode == ScheduleViewMode.month &&
                        _previousViewMode == ScheduleViewMode.week) {
                      horizontalOffset = 1.0;
                    }
                    // Месяц → Неделя: приходит слева
                    else if (_currentMode == ScheduleViewMode.week &&
                        _previousViewMode == ScheduleViewMode.month) {
                      horizontalOffset = -1.0;
                    }
                    // Месяц → День: приходит слева
                    else if (_currentMode == ScheduleViewMode.day &&
                        _previousViewMode == ScheduleViewMode.month) {
                      horizontalOffset = -1.0;
                    }
                  } else {
                    // Навигация внутри режима (стрелки влево/вправо)
                    // Инвертируем направление: -1 (влево) -> -1.0, 1 (вправо) -> 1.0
                    horizontalOffset = -_navigationDirection.toDouble();
                  }

                  final offsetAnimation =
                      Tween<Offset>(
                        begin: Offset(horizontalOffset, 0.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      );

                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Container(
                  key: ValueKey(
                    '${_currentMode}_${_currentMode == ScheduleViewMode.day ? _currentDate.toString() : _currentWeekDate.toString()}',
                  ),
                  child:
                      _currentMode == ScheduleViewMode.day ||
                          _currentMode == ScheduleViewMode.month
                      ? _buildDayScheduleList(_currentDate)
                      : _buildWeekScheduleList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚨 ИСПРАВЛЕННЫЙ ВИДЖЕТ: Серый фон и точная анимация
  // В файле lib/schedule_page.dart замените _buildModeSwitcher на этот код:
  // В файле lib/schedule_page.dart замените _buildModeSwitcher на этот код:
  Widget _buildModeSwitcher(Color activeColor) {
    // Зелёный цвет для обводки
    final greenBorder = const Color(0xFF409187);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          // Свайп влево - предыдущий режим (День)
          if (_currentMode == ScheduleViewMode.week) {
            setState(() {
              _previousViewMode = _currentMode;
              _currentMode = ScheduleViewMode.day;
            });
          } else if (_currentMode == ScheduleViewMode.month) {
            setState(() {
              _previousViewMode = _currentMode;
              _currentMode = ScheduleViewMode.week;
            });
          }
        } else if (details.primaryVelocity! > 0) {
          // Свайп вправо - следующий режим (Месяц)
          if (_currentMode == ScheduleViewMode.day) {
            setState(() {
              _previousViewMode = _currentMode;
              _currentMode = ScheduleViewMode.week;
            });
          } else if (_currentMode == ScheduleViewMode.week) {
            setState(() {
              _previousViewMode = _currentMode;
              _currentMode = ScheduleViewMode.month;
              if (_selectedDay != null) {
                _currentDate = _selectedDay!;
              }
            });
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        key: _switcherKey,
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: greenBorder, width: 2.5),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttonWidth = (constraints.maxWidth - 6) / 3;
            double leftPosition;

            switch (_currentMode) {
              case ScheduleViewMode.day:
                leftPosition = 3;
                break;
              case ScheduleViewMode.week:
                leftPosition = 3 + buttonWidth;
                break;
              case ScheduleViewMode.month:
                leftPosition = 3 + buttonWidth * 2;
                break;
            }

            return Stack(
              children: [
                // Анимированный овал-индикатор
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  left: leftPosition,
                  top: 3,
                  bottom: 3,
                  width: buttonWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: greenBorder,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                // Кнопки поверх индикатора
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildModeButton(
                      'День',
                      ScheduleViewMode.day,
                      _dayKey,
                      greenBorder,
                    ),
                    _buildModeButton(
                      'Неделя',
                      ScheduleViewMode.week,
                      _weekKey,
                      greenBorder,
                    ),
                    _buildModeButton(
                      'Месяц',
                      ScheduleViewMode.month,
                      _monthKey,
                      greenBorder,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 🚨 ИСПРАВЛЕННЫЙ ВИДЖЕТ: Кнопка (вызывает обновление позиции)
  // В файле lib/schedule_page.dart замените _buildModeButton на этот код:
  Widget _buildModeButton(
    String title,
    ScheduleViewMode mode,
    GlobalKey key,
    Color greenBorder,
  ) {
    final isActive = _currentMode == mode;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          setState(() {
            _previousViewMode = _currentMode;
            _currentMode = mode;
            if (mode == ScheduleViewMode.month && _selectedDay != null) {
              _currentDate = _selectedDay!;
            }
            _updateIndicatorPosition();
          });
        },
        child: Container(
          key: key,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          height: 40,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isActive ? Colors.white : greenBorder,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  // ... (Остальные виджеты _buildDayNavigator, _buildWeekNavigator, и т.д. ниже)

  Widget _buildDayNavigator(BuildContext context) {
    final normalizedToday = _normalizeDate(DateTime.now());
    final normalizedCurrent = _currentDate;
    final isToday = normalizedCurrent.difference(normalizedToday).inDays == 0;
    final isCurrentMonth =
        _currentDate.month == DateTime.now().month &&
        _currentDate.year == DateTime.now().year;
    const activeColor = Color(0xFF409187);
    const greyColor = Color(0xFF757575);

    final dateText = _formatDate(_currentDate);

    // Определяем цвета для даты
    Color textColor;
    Color? borderColor;
    Color? backgroundColor;

    if (isToday) {
      // Текущий день = зеленый текст + зеленая обводка + зеленый фон
      textColor = activeColor;
      borderColor = activeColor;
      backgroundColor = activeColor.withValues(alpha: 0.2);
    } else if (isCurrentMonth) {
      // Другие дни текущего месяца = зеленый текст + серая обводка
      textColor = activeColor;
      borderColor = greyColor;
      backgroundColor = Colors.transparent;
    } else {
      // Другой месяц = серый текст + серая обводка
      textColor = greyColor;
      borderColor = greyColor;
      backgroundColor = Colors.transparent;
    }

    // Определяем цвета для стрелок
    final isPrevDayToday =
        _normalizeDate(_currentDate.subtract(const Duration(days: 1))) ==
        normalizedToday;
    final isNextDayToday =
        _normalizeDate(_currentDate.add(const Duration(days: 1))) ==
        normalizedToday;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Кнопка назад (с кругом)
        InkWell(
          onTap: () => _changeDay(-1),
          borderRadius: BorderRadius.circular(50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrevDayToday
                  ? activeColor.withValues(alpha: 0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isPrevDayToday ? activeColor : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.arrow_back_ios,
                    key: ValueKey(isPrevDayToday),
                    size: 18,
                    color: isPrevDayToday ? activeColor : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Центральная дата + диалог выбора (овальная обводка)
        GestureDetector(
          onTap: _showDayPickerDialog,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              setState(() => _currentMode = ScheduleViewMode.month);
            } else if (details.primaryVelocity! < 0) {
              setState(() => _currentMode = ScheduleViewMode.week);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20), // Овальная
              border: Border.all(color: borderColor, width: 2),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: Offset(
                            -_navigationDirection.toDouble() * 1.0,
                            0,
                          ),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: Text(
                dateText,
                key: ValueKey(dateText),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),

        // Кнопка вперед (с кругом)
        InkWell(
          onTap: () => _changeDay(1),
          borderRadius: BorderRadius.circular(50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNextDayToday
                  ? activeColor.withValues(alpha: 0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isNextDayToday ? activeColor : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.arrow_forward_ios,
                  key: ValueKey(isNextDayToday),
                  size: 18,
                  color: isNextDayToday ? activeColor : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayOfWeekDisplay() {
    const activeColor = Color(0xFF409187);
    final greyColor = Colors.grey.shade600;
    final dayName = DateFormat('EEEE', 'ru_RU').format(_currentDate);
    final capitalizedDayName = _capitalize(dayName);

    // Проверяем, является ли _currentDate сегодняшним днем
    final isToday =
        _normalizeDate(_currentDate) == _normalizeDate(DateTime.now());

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: Offset(-_navigationDirection.toDouble() * 1.0, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        child: Text(
          capitalizedDayName,
          key: ValueKey(capitalizedDayName),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isToday ? activeColor : greyColor,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekNavigator(BuildContext context) {
    const activeColor = Color(0xFF409187);
    const greyColor = Color(0xFF757575);
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final normalizedToday = _normalizeDate(DateTime.now());

    final startOfWeek = _getStartOfWeek(_currentWeekDate);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final today = _normalizeDate(DateTime.now());
    final isCurrentWeek =
        today.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        today.isBefore(endOfWeek.add(const Duration(days: 1)));

    final color = isCurrentWeek ? activeColor : greyColor;
    final fillColor = isCurrentWeek
        ? activeColor.withValues(alpha: 0.2)
        : Colors.transparent;

    // Определяем цвета для начала и конца недели
    final startIsCurrentMonth =
        startOfWeek.month == currentMonth && startOfWeek.year == currentYear;
    final endIsCurrentMonth =
        endOfWeek.month == currentMonth && endOfWeek.year == currentYear;

    // Определяем цвета для стрелок
    final prevWeekStart = startOfWeek.subtract(const Duration(days: 7));
    final nextWeekStart = startOfWeek.add(const Duration(days: 7));
    final isPrevWeekCurrent =
        normalizedToday.isAfter(
          prevWeekStart.subtract(const Duration(days: 1)),
        ) &&
        normalizedToday.isBefore(prevWeekStart.add(const Duration(days: 7)));
    final isNextWeekCurrent =
        normalizedToday.isAfter(
          nextWeekStart.subtract(const Duration(days: 1)),
        ) &&
        normalizedToday.isBefore(nextWeekStart.add(const Duration(days: 7)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Кнопка назад (с кругом)
        InkWell(
          onTap: () => _changeWeek(-1),
          borderRadius: BorderRadius.circular(50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrevWeekCurrent
                  ? activeColor.withValues(alpha: 0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isPrevWeekCurrent ? activeColor : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.arrow_back_ios,
                    key: ValueKey(isPrevWeekCurrent),
                    size: 18,
                    color: isPrevWeekCurrent
                        ? activeColor
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        ),

        GestureDetector(
          onTap: _showWeekPickerDialog,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              setState(() => _currentMode = ScheduleViewMode.day);
            } else if (details.primaryVelocity! < 0) {
              setState(() => _currentMode = ScheduleViewMode.month);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(20),
              color: fillColor,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: Offset(
                            -_navigationDirection.toDouble() * 1.0,
                            0,
                          ),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: Text.rich(
                key: ValueKey(
                  '${_formatDate(startOfWeek)}_${_formatDate(endOfWeek)}',
                ),
                TextSpan(
                  children: [
                    TextSpan(
                      text: _formatDate(startOfWeek),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: startIsCurrentMonth ? activeColor : greyColor,
                      ),
                    ),
                    TextSpan(
                      text: ' – ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: _formatDate(endOfWeek),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: endIsCurrentMonth ? activeColor : greyColor,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Кнопка вперед (с кругом)
        InkWell(
          onTap: () => _changeWeek(1),
          borderRadius: BorderRadius.circular(50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNextWeekCurrent
                  ? activeColor.withValues(alpha: 0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isNextWeekCurrent ? activeColor : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.arrow_forward_ios,
                  key: ValueKey(isNextWeekCurrent),
                  size: 18,
                  color: isNextWeekCurrent ? activeColor : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool hasLessons(DateTime day) {
    final schedule = _getScheduleForDate(day);
    return schedule.lessons.isNotEmpty;
  }

  String _getWeekRange(DateTime date) {
    final startOfWeek = _getStartOfWeek(date);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}';
  }

  int _getTotalLessonsForWeek(DateTime weekStart) {
    int total = 0;
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final schedule = _getScheduleForDate(day);
      total += schedule.lessons.length;
    }
    return total;
  }

  Duration _getLessonDuration(String time) {
    final parts = time.split(' - ');
    if (parts.length != 2) return Duration.zero;

    final startParts = parts[0].split(':');
    final endParts = parts[1].split(':');

    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    return Duration(minutes: endMinutes - startMinutes);
  }

  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(BuildContext context) {
    if (fullSchedule.isEmpty) return Container();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _monthViewDate = DateTime(
                    _monthViewDate.year,
                    _monthViewDate.month - 1,
                  );
                  _focusedDay = _monthViewDate;
                });
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _showMonthPickerDialog,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  setState(() => _currentMode = ScheduleViewMode.week);
                } else if (details.primaryVelocity! < 0) {
                  setState(() => _currentMode = ScheduleViewMode.day);
                }
              },
              child: Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final isCurrentMonth =
                      _monthViewDate.year == now.year &&
                      _monthViewDate.month == now.month;
                  final isCurrentYear = _monthViewDate.year == now.year;

                  // Определяем стили на основе месяца
                  Color backgroundColor;
                  Color borderColor;
                  Color textColor;

                  if (isCurrentMonth) {
                    // Текущий месяц: яркий зеленый фон + зеленая обводка + зеленый текст
                    backgroundColor = const Color(
                      0xFF409187,
                    ).withValues(alpha: 0.2);
                    borderColor = const Color(0xFF409187);
                    textColor = const Color(0xFF409187);
                  } else if (isCurrentYear) {
                    // Другой месяц текущего года: без фона + серая обводка + зеленый текст
                    backgroundColor = Colors.transparent;
                    borderColor = Colors.grey.shade400;
                    textColor = const Color(0xFF409187);
                  } else {
                    // Месяц другого года: без фона + серая обводка + серый текст
                    backgroundColor = Colors.transparent;
                    borderColor = Colors.grey.shade400;
                    textColor = Colors.grey.shade600;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 2),
                      color: backgroundColor,
                    ),
                    child: Text(
                      '${DateFormat('LLLL', 'ru').format(_monthViewDate)[0].toUpperCase()}${DateFormat('LLLL', 'ru').format(_monthViewDate).substring(1)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _monthViewDate = DateTime(
                    _monthViewDate.year,
                    _monthViewDate.month + 1,
                  );
                  _focusedDay = _monthViewDate;
                });
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          // Разрешаем вертикальный скроллинг на виджете календаря
          onVerticalDragUpdate: (details) {
            // Передаем скролл родительскому виджету
            if (details.delta.dy.abs() > 0) {
              // Скролл будет обрабатываться родительским SingleChildScrollView
            }
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: TableCalendar(
              locale: 'ru_RU',
              startingDayOfWeek: StartingDayOfWeek.monday,
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              headerVisible: false,
              selectedDayPredicate: (day) {
                return _selectedDay != null &&
                    _selectedDay!.year == day.year &&
                    _selectedDay!.month == day.month &&
                    _selectedDay!.day == day.day;
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (_selectedDay == null ||
                    _selectedDay!.year != selectedDay.year ||
                    _selectedDay!.month != selectedDay.month ||
                    _selectedDay!.day != selectedDay.day) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _currentDate = selectedDay;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  _monthViewDate =
                      focusedDay; // Синхронизация заголовка месяца при скролле
                });
              },
              calendarStyle: CalendarStyle(
                // КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Today ВСЕГДА с зеленым фоном
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF409187).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF409187), width: 2),
                  shape: BoxShape.circle, // Круг как уступка
                ),
                todayTextStyle: const TextStyle(
                  color: Color(0xFF409187),
                  fontWeight: FontWeight.bold,
                ),
                // КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Selected ТОЛЬКО обводка (без фона)
                selectedDecoration: BoxDecoration(
                  color: Colors.transparent, // БЕЗ ФОНА!
                  border: Border.all(color: const Color(0xFF409187), width: 2),
                  shape: BoxShape.circle, // Круг как уступка
                ),
                selectedTextStyle: const TextStyle(
                  color: Color(0xFF409187),
                  fontWeight: FontWeight.bold,
                ),
                defaultTextStyle: TextStyle(
                  color:
                      _monthViewDate.month == DateTime.now().month &&
                          _monthViewDate.year == DateTime.now().year
                      ? const Color(0xFF409187) // Текущий месяц - зеленый
                      : Colors.black87, // Другие месяцы - черный
                ),
                weekendTextStyle: TextStyle(
                  color:
                      _monthViewDate.month == DateTime.now().month &&
                          _monthViewDate.year == DateTime.now().year
                      ? const Color(0xFF409187) // Текущий месяц - зеленый
                      : Colors.black87, // Другие месяцы - черный
                ),
                outsideTextStyle: TextStyle(
                  color: Colors.grey.shade400, // Дни других месяцев - серый
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  return null;
                },
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayScheduleList(DateTime date) {
    final DailySchedule daily = _getScheduleForDate(date);
    final isToday = _normalizeDate(date) == _normalizeDate(DateTime.now());

    if (daily.lessons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0),
        child: Center(
          child: Text(
            'На этот день (${daily.day}) занятий нет! Отдыхайте. 😊',
            style: const TextStyle(fontSize: 20, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // УБРАНО: Окно текущего урока больше не отображается

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF409187).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              ...daily.lessons.asMap().entries.map((entry) {
                final index = entry.key;
                final lesson = entry.value;
                final examKey = '${date.toString()}_${lesson.time}';
                final shouldPulse =
                    lesson.examNote != null && !_viewedExams.contains(examKey);

                return LessonTile(
                  time: lesson.time,
                  title: lesson.title,
                  teacher: lesson.teacher,
                  classroom: lesson.classroom,
                  baseColor: lesson.baseColor,
                  type: lesson.type,
                  format: lesson.format,
                  isToday: isToday,
                  onPowerAppsPressed: _showPowerAppsDialog,
                  onTeacherTap: () => _showTeacherInfo(lesson.teacher),
                  examNote: lesson.examNote,
                  shouldPulse: shouldPulse,
                  lessonNumber: index + 1,
                  deepLink: lesson.deepLink,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDayTimer(
    DailySchedule dailySchedule,
    bool isToday,
    Color activeColor,
    int lessonCount,
  ) {
    if (!isToday || dailySchedule.lessons.isEmpty) {
      // Обычный круг с количеством уроков
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isToday
              ? activeColor.withValues(alpha: 0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isToday ? activeColor : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$lessonCount',
            style: TextStyle(
              color: isToday ? activeColor : Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // ДИНАМИЧЕСКИЙ ТАЙМЕР для сегодняшнего дня
    final now = DateTime.now();
    double progress = 0.0;

    for (final lesson in dailySchedule.lessons) {
      final times = lesson.time.split(' - ');
      if (times.length == 2) {
        final startParts = times[0].split(':');
        final endParts = times[1].split(':');
        if (startParts.length == 2 && endParts.length == 2) {
          final start = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(startParts[0]),
            int.parse(startParts[1]),
          );
          final end = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(endParts[0]),
            int.parse(endParts[1]),
          );

          if (now.isAfter(start) && now.isBefore(end)) {
            final elapsed = now.difference(start).inSeconds.toDouble();
            final total = end.difference(start).inSeconds.toDouble();
            progress = elapsed / total;
            break;
          }
        }
      }
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _CircleProgressPainter(
          progress: progress,
          progressColor: activeColor,
          bgColor: activeColor.withValues(alpha: 0.2),
          strokeWidth: 3,
        ),
        child: Center(
          child: Text(
            '$lessonCount',
            style: TextStyle(
              color: activeColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekScheduleList() {
    final today = _normalizeDate(DateTime.now());
    const activeColor = Color(0xFF409187);

    // Фильтруем расписание только для текущей недели
    final startOfWeek = _getStartOfWeek(_currentWeekDate);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final weekSchedule = fullSchedule.where((schedule) {
      final date = _normalizeDate(schedule.date);
      return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();

    return Column(
      children: weekSchedule.map((dailySchedule) {
        final normalizedDate = _normalizeDate(dailySchedule.date);
        final isToday = normalizedDate == today;
        final lessonCount = dailySchedule.lessons.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isToday ? activeColor.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? activeColor : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              expansionTileTheme: const ExpansionTileThemeData(
                expandedAlignment: Alignment.topLeft,
                tilePadding: EdgeInsets.zero,
                collapsedIconColor: Colors.grey,
                iconColor: Color(0xFF409187),
              ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              childrenPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.trailing,
              maintainState: true,
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              key: ValueKey('tile_${dailySchedule.date}'),
              onExpansionChanged: (expanded) {
                setState(() {
                  final tileKey = '${dailySchedule.date}';
                  if (expanded) {
                    _expandedTiles.add(tileKey);
                  } else {
                    _expandedTiles.remove(tileKey);
                  }
                });
              },
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      dailySchedule.day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isToday ? activeColor : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  // КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Динамический таймер на Неделе
                  _buildWeekDayTimer(
                    dailySchedule,
                    isToday,
                    activeColor,
                    lessonCount,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(dailySchedule.date),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? activeColor
                          : (normalizedDate.month == DateTime.now().month &&
                                    normalizedDate.year == DateTime.now().year
                                ? activeColor
                                : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              initiallyExpanded: false,
              children: dailySchedule.lessons.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Занятий нет',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ]
                  : [
                      ...dailySchedule.lessons.asMap().entries.map((entry) {
                        final index = entry.key;
                        final lesson = entry.value;
                        final examKey =
                            '${dailySchedule.date.toString()}_${lesson.time}';
                        final shouldPulse =
                            lesson.examNote != null &&
                            !_viewedExams.contains(examKey);

                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 200 + (index * 80)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateX((1 - value) * 0.5)
                                ..translate(
                                  0.0,
                                  -30 * (1 - value),
                                  -50 * (1 - value),
                                ),
                              alignment: Alignment.topCenter,
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: LessonTile(
                              time: lesson.time,
                              title: lesson.title,
                              teacher: lesson.teacher,
                              classroom: lesson.classroom,
                              baseColor: lesson.baseColor,
                              type: lesson.type,
                              format: lesson.format,
                              isToday: isToday,
                              onPowerAppsPressed: _showPowerAppsDialog,
                              onTeacherTap: () =>
                                  _showTeacherInfo(lesson.teacher),
                              examNote: lesson.examNote,
                              shouldPulse: shouldPulse,
                              lessonNumber: index + 1,
                              deepLink: lesson.deepLink,
                            ),
                          ),
                        );
                      }).toList(),
                      // КНОПКА ЗАКРЫТИЯ СВЁРТКА - МАЛЕНЬКАЯ ПЛОСКАЯ ПРЯМОУГОЛЬНАЯ
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _expandedTiles.remove('${dailySchedule.date}');
                              });
                              // Плавный скролл к заголовку дня
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  final renderBox =
                                      context.findRenderObject() as RenderBox?;
                                  if (renderBox != null) {
                                    Scrollable.ensureVisible(
                                      context,
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: activeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: activeColor,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: activeColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class LessonTile extends StatefulWidget {
  final String time;
  final String title;
  final String teacher;
  final String classroom;
  final Color baseColor;
  final LessonType type;
  final LessonFormat format;
  final bool isToday;
  final VoidCallback? onPowerAppsPressed;
  final VoidCallback? onTeacherTap;
  final String? examNote;
  final bool shouldPulse;
  final int lessonNumber; // Порядковый номер урока в дне
  final String deepLink;

  const LessonTile({
    super.key,
    required this.time,
    required this.title,
    required this.teacher,
    required this.classroom,
    required this.baseColor,
    required this.type,
    required this.format,
    this.isToday = false,
    this.onPowerAppsPressed,
    this.onTeacherTap,
    this.examNote,
    this.shouldPulse = false,
    required this.lessonNumber,
    this.deepLink = '',
  });

  @override
  State<LessonTile> createState() => _LessonTileState();
}

class _LessonTileState extends State<LessonTile> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _borderController;
  bool _isLoading = false;
  bool _isPressedTitle = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _borderController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.shouldPulse && widget.examNote != null) {
      _startPulseWithVibration();
    }
  }

  Future<void> _startPulseWithVibration() async {
    debugPrint('EVENT: exam_pulse_start | timestamp: ${DateTime.now()}');
    final hasVibrator = await Vibration.hasVibrator() ?? false;

    // Первая серия: 3 удара за 1 секунду (333ms на удар)
    for (int i = 0; i < 3; i++) {
      if (hasVibrator) Vibration.vibrate(duration: 50);
      await _pulseController.forward();
      await _pulseController.reverse();
      if (i < 2)
        await Future.delayed(
          const Duration(milliseconds: 183),
        ); // 150ms анимация + 183ms = 333ms
    }

    // Пауза 1.5 секунды
    await Future.delayed(const Duration(milliseconds: 1500));

    // Вторая серия: 3 удара за 1 секунду
    for (int i = 0; i < 3; i++) {
      if (hasVibrator) Vibration.vibrate(duration: 50);
      await _pulseController.forward();
      await _pulseController.reverse();
      if (i < 2) await Future.delayed(const Duration(milliseconds: 183));
    }

    debugPrint('EVENT: exam_pulse_end | timestamp: ${DateTime.now()}');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getLessonStyle() {
    switch (widget.type) {
      case LessonType.online:
        return {
          'icon': Icons.laptop_windows,
          'color': const Color.fromARGB(255, 27, 79, 114),
        };
      case LessonType.exam:
        return {
          'icon': Icons.assignment,
          'color': const Color.fromARGB(255, 52, 152, 219),
        };
      case LessonType.changed:
        return {
          'icon': Icons.warning_amber,
          'color': const Color.fromARGB(255, 230, 126, 34),
        };
      case LessonType.regular:
      default:
        return {'icon': Icons.menu_book, 'color': const Color(0xFF409187)};
    }
  }

  String _getFormatText() {
    switch (widget.format) {
      case LessonFormat.lecture:
        return 'LECT';
      case LessonFormat.practice:
        return 'PRAC';
      case LessonFormat.lab:
        return 'LAB';
      default:
        return 'LECT';
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        const Text('—', style: TextStyle(fontSize: 20, color: Colors.grey)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  void _showLessonTypePopup(BuildContext context, Color typeColor) {
    String typeName = '';
    IconData typeIcon = Icons.menu_book;

    switch (widget.type) {
      case LessonType.regular:
        typeName = 'Обычный урок';
        typeIcon = Icons.menu_book;
        break;
      case LessonType.online:
        typeName = 'Дистанционно';
        typeIcon = Icons.laptop_windows;
        break;
      case LessonType.exam:
        typeName = 'Экзамен';
        typeIcon = Icons.assignment;
        break;
      case LessonType.changed:
        typeName = 'Изменено';
        typeIcon = Icons.warning_amber;
        break;
    }

    String formatName = '';
    switch (widget.format) {
      case LessonFormat.lecture:
        formatName = 'Лекция';
        break;
      case LessonFormat.practice:
        formatName = 'Практика';
        break;
      case LessonFormat.lab:
        formatName = 'Лабораторная';
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              const Text(
                '—',
                style: TextStyle(fontSize: 24, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatName,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // НОВОЕ МОДАЛЬНОЕ ОКНО ПРИ КЛИКЕ НА ВРЕМЯ
  void _showLessonDetailsDialog(BuildContext context, Color typeColor) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return LessonDetailsDialog(
          lessonNumber: widget.lessonNumber,
          title: widget.title,
          timeRange: widget.time,
          color: typeColor,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _getLessonStyle();
    final typeColor = style['color'] as Color;
    final formatText = _getFormatText();

    return InkWell(
      onLongPress: () => _showLessonTypePopup(context, typeColor),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 5,
        color: widget.baseColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            // 1. ЦВЕТНОЙ ВЕРХНИЙ БАР
            GestureDetector(
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Легенда цветов',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLegendItem(
                          const Color(0xFF409187),
                          'Обычный урок',
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          const Color.fromARGB(255, 27, 79, 114),
                          'Дистанционно',
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          const Color.fromARGB(255, 52, 152, 219),
                          'Экзамен',
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          const Color.fromARGB(255, 230, 126, 34),
                          'Изменено',
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    // 1. ЛЕВАЯ ЗОНА - ТИП УРОКА (С КРАЮ БЕЗ ОТСТУПА)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              String description = '';
                              IconData icon = Icons.menu_book;
                              switch (widget.format) {
                                case LessonFormat.lecture:
                                  description =
                                      'Лекция - теоретическое занятие';
                                  icon = Icons.menu_book;
                                  break;
                                case LessonFormat.practice:
                                  description =
                                      'Практика - практическое занятие';
                                  icon = Icons.edit_note;
                                  break;
                                case LessonFormat.lab:
                                  description = 'Лабораторная работа';
                                  icon = Icons.science;
                                  break;
                              }
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) => Container(
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: typeColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          icon,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        '—',
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          description,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: typeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              formatText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (widget.type == LessonType.online) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Открывается: ${widget.classroom} (${widget.classroom})',
                                    ),
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(
                                      0xFF409187,
                                    ).withValues(alpha: 0.85),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.only(
                                      bottom: 20,
                                      left: 20,
                                      right: 20,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.videocam,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 2. ЦЕНТРАЛЬНАЯ ЗОНА - ВРЕМЯ (КЛИКАБЕЛЬНОЕ)
                    Expanded(
                      child: Center(
                        child: InkWell(
                          onTap: () =>
                              _showLessonDetailsDialog(context, typeColor),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              widget.time,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. ПРАВАЯ ЗОНА - ИКОНКА (С КРАЮ БЕЗ ОТСТУПА)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            style['icon'] as IconData,
                            color: Colors.white,
                            size: 22,
                          ),
                          if (widget.isToday) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                if (widget.deepLink.isNotEmpty) {
                                  try {
                                    final url = Uri.parse(widget.deepLink);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Не удалось открыть приложение',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    debugPrint('Error launching deepLink: $e');
                                  }
                                } else {
                                  widget.onPowerAppsPressed?.call();
                                }
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF742774),
                                          Color(0xFFD946A0),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.apps,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. ИНФОРМАЦИОННЫЙ БЛОК
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: typeColor, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // НАЗВАНИЕ ПРЕДМЕТА В РАМКЕ С ИКОНКОЙ
                  GestureDetector(
                    onTapDown: (_) {
                      setState(() => _isPressedTitle = true);
                    },
                    onTapUp: (_) {
                      setState(() => _isPressedTitle = false);
                    },
                    onTapCancel: () {
                      setState(() => _isPressedTitle = false);
                    },
                    onTap: () {
                      debugPrint(
                        'EVENT: lesson_title_press | lesson: ${widget.title} | timestamp: ${DateTime.now()}',
                      );
                      setState(() {
                        _isLoading = !_isLoading;
                        if (_isLoading) {
                          _borderController.repeat();
                        } else {
                          _borderController.stop();
                          _borderController.reset();
                        }
                      });
                    },
                    child: AnimatedScale(
                      scale: _isPressedTitle ? 0.96 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeInOut,
                      child: CustomPaint(
                        painter: _isLoading
                            ? _BorderLoadingPainter(
                                progress: _borderController.value,
                                color: typeColor,
                              )
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: typeColor, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _isLoading
                                    ? const SizedBox(
                                        key: ValueKey('loading'),
                                        width: 20,
                                        height: 20,
                                      )
                                    : const Text(
                                        '🎓',
                                        key: ValueKey('emoji'),
                                        style: TextStyle(fontSize: 20),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // РАЗДЕЛИТЕЛЬ
                  const Divider(
                    height: 20,
                    thickness: 1,
                    color: Colors.black12,
                  ),

                  // ПРЕПОДАВАТЕЛЬ
                  InkWell(
                    onTap: widget.onTeacherTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 18,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.teacher,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // АУДИТОРИЯ/АДРЕС (КЛИКАБЕЛЬНАЯ ДЛЯ ОНЛАЙН И GOOGLE MAPS)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: widget.type == LessonType.online
                            ? InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Открывается: ${widget.classroom}',
                                      ),
                                      duration: const Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(
                                        0xFF409187,
                                      ).withValues(alpha: 0.85),
                                      dismissDirection: DismissDirection.down,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.only(
                                        bottom: 20,
                                        left: 20,
                                        right: 20,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  widget.classroom,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final address =
                                          'Ломоносова 27, Рига, Латвия';
                                      final encodedAddress =
                                          Uri.encodeComponent(address);
                                      final url = Uri.parse(
                                        'geo:0,0?q=$encodedAddress',
                                      );
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } else {
                                        final webUrl = Uri.parse(
                                          'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
                                        );
                                        await launchUrl(
                                          webUrl,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Ломоносова 27',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    width: 1,
                                    height: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                  Text(
                                    widget.classroom,
                                    style: const TextStyle(
                                      color: Color(0xFF424242),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                  // БЛОК КОНТРОЛЬНОЙ РАБОТЫ (если есть)
                  if (widget.examNote != null) ...[
                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.black12,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF409187,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF409187),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                color: Color(0xFF409187),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.examNote!,
                                  style: const TextStyle(
                                    color: Color(0xFF2C6B63),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Динамический таймер урока с порядковым номером
class LessonTimer extends StatefulWidget {
  final String timeRange; // "08:30 - 10:00"
  final int lessonNumber; // Порядковый номер урока в дне
  final Color color;

  const LessonTimer({
    super.key,
    required this.timeRange,
    required this.lessonNumber,
    required this.color,
  });

  @override
  State<LessonTimer> createState() => _LessonTimerState();
}

class _LessonTimerState extends State<LessonTimer> {
  Timer? _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _updateProgress();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateProgress();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateProgress() {
    final now = DateTime.now();
    final times = widget.timeRange.split(' - ');
    if (times.length != 2) return;

    try {
      final startParts = times[0].split(':');
      final endParts = times[1].split(':');

      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      if (now.isBefore(startTime)) {
        setState(() => _progress = 0.0);
      } else if (now.isAfter(endTime)) {
        setState(() => _progress = 1.0);
      } else {
        final total = endTime.difference(startTime).inSeconds;
        final elapsed = now.difference(startTime).inSeconds;
        setState(() => _progress = elapsed / total);
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }
  }

  void _showDetailDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Детали урока',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Container();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
          child: FadeTransition(
            opacity: anim1,
            child: LessonDetailDialog(
              lessonNumber: widget.lessonNumber,
              timeRange: widget.timeRange,
              color: widget.color,
              progress: _progress,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showDetailDialog,
      child: SizedBox(
        width: 36,
        height: 36,
        child: CustomPaint(
          painter: _CircleProgressPainter(
            progress: _progress,
            progressColor: widget.color,
            bgColor: widget.color.withValues(alpha: 0.2),
            strokeWidth: 3,
          ),
          child: Center(
            child: Text(
              '${widget.lessonNumber}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Модальное окно с деталями урока
class LessonDetailDialog extends StatefulWidget {
  final int lessonNumber;
  final String timeRange;
  final Color color;
  final double progress;

  const LessonDetailDialog({
    super.key,
    required this.lessonNumber,
    required this.timeRange,
    required this.color,
    required this.progress,
  });

  @override
  State<LessonDetailDialog> createState() => _LessonDetailDialogState();
}

class _LessonDetailDialogState extends State<LessonDetailDialog> {
  Timer? _timer;
  bool _showElapsed = true; // true = прошедшее, false = оставшееся
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateDuration();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateDuration() {
    final now = DateTime.now();
    final times = widget.timeRange.split(' - ');
    if (times.length != 2) return;

    try {
      final startParts = times[0].split(':');
      final endParts = times[1].split(':');

      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      if (_showElapsed) {
        if (now.isBefore(startTime)) {
          setState(() => _currentDuration = Duration.zero);
        } else if (now.isAfter(endTime)) {
          setState(() => _currentDuration = endTime.difference(startTime));
        } else {
          setState(() => _currentDuration = now.difference(startTime));
        }
      } else {
        if (now.isBefore(startTime)) {
          setState(() => _currentDuration = endTime.difference(startTime));
        } else if (now.isAfter(endTime)) {
          setState(() => _currentDuration = Duration.zero);
        } else {
          setState(() => _currentDuration = endTime.difference(now));
        }
      }
    } catch (e) {
      debugPrint('Error calculating duration: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final times = widget.timeRange.split(' - ');
    final startTime = times.isNotEmpty ? times[0] : '';
    final endTime = times.length > 1 ? times[1] : '';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок: номер урока
            Text(
              '${widget.lessonNumber}-й Урок',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
            const SizedBox(height: 20),

            // Время начала и конца
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  startTime,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  endTime,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Горизонтальный прогресс бар
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: widget.progress,
                minHeight: 12,
                backgroundColor: widget.color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            ),
            const SizedBox(height: 16),

            // Время (переключаемое)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showElapsed = !_showElapsed;
                  _updateDuration();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.color, width: 2),
                ),
                child: Text(
                  _showElapsed
                      ? _formatDuration(_currentDuration)
                      : '-${_formatDuration(_currentDuration)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showElapsed ? 'Прошло времени' : 'Осталось времени',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// МОДАЛЬНОЕ ОКНО С ДЕТАЛЯМИ УРОКА (при клике на время)
class LessonDetailsDialog extends StatefulWidget {
  final int lessonNumber;
  final String title;
  final String timeRange;
  final Color color;

  const LessonDetailsDialog({
    super.key,
    required this.lessonNumber,
    required this.title,
    required this.timeRange,
    required this.color,
  });

  @override
  State<LessonDetailsDialog> createState() => _LessonDetailsDialogState();
}

class _LessonDetailsDialogState extends State<LessonDetailsDialog> {
  bool _showElapsed = true; // true = прошедшее, false = оставшееся
  late Timer _timer;
  Duration _currentDuration = Duration.zero;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateDuration();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateDuration() {
    final times = widget.timeRange.split(' - ');
    if (times.length != 2) return;

    final now = DateTime.now();
    final startTime = _parseTime(times[0]);
    final endTime = _parseTime(times[1]);

    if (startTime == null || endTime == null) return;

    final start = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    );
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      endTime.hour,
      endTime.minute,
    );
    final total = end.difference(start);

    if (now.isBefore(start)) {
      // Урок еще не начался
      _progress = 0.0;
      _currentDuration = Duration.zero;
    } else if (now.isAfter(end)) {
      // КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Урок закончился
      _progress = 1.0;
      if (_showElapsed) {
        _currentDuration = total; // Показываем полную длительность
      } else {
        _currentDuration = Duration.zero; // Оставшееся = 00:00:00
      }
    } else {
      // Урок идет
      final elapsed = now.difference(start);
      _progress = elapsed.inSeconds / total.inSeconds;
      _currentDuration = _showElapsed ? elapsed : end.difference(now);
    }
  }

  DateTime? _parseTime(String time) {
    try {
      final parts = time.trim().split(':');
      if (parts.length == 2) {
        return DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }
    return null;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final times = widget.timeRange.split(' - ');
    final startTime = times.isNotEmpty ? times[0] : '';
    final endTime = times.length > 1 ? times[1] : '';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ряд 1: Порядковый номер урока
            Text(
              '${widget.lessonNumber}-й Урок',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
            const SizedBox(height: 12),

            // Ряд 2: Название урока
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Время начала и конца
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  startTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  endTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ряд 3: Горизонтальный прогресс бар (динамический)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 12,
                backgroundColor: widget.color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            ),
            const SizedBox(height: 20),

            // Ряд 4: Время (переключаемое) - ЧАС:МИНУТА:СЕКУНДА С АНИМАЦИЕЙ
            GestureDetector(
              onTap: () {
                setState(() {
                  _showElapsed = !_showElapsed;
                  _updateDuration();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.color, width: 2),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _showElapsed
                        ? _formatDuration(_currentDuration)
                        : (_currentDuration == Duration.zero
                              ? '00:00:00'
                              : '-${_formatDuration(_currentDuration)}'),
                    key: ValueKey<bool>(_showElapsed),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showElapsed ? 'Прошло времени' : 'Осталось времени',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class BannerWidget extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const BannerWidget({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color bgColor;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return true;
  }
}
