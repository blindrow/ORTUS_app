import 'package:flutter/material.dart';
import 'package:flutter_application_1/lesson_model.dart';

class ScheduleService {
  static List<DailySchedule> fetchSchedule() {
    // Цвета для занятий (константы)
    const colorMath = Color.fromARGB(255, 255, 236, 179);
    const colorPhysics = Color.fromARGB(255, 179, 219, 255);
    const colorEnglish = Color.fromARGB(255, 216, 255, 179);
    const colorHistory = Color.fromARGB(255, 255, 204, 204);
    const colorIT = Color.fromARGB(255, 240, 204, 255);
    const colorPE = Color.fromARGB(255, 204, 255, 255);

    // 1. ПОНЕДЕЛЬНИК
    final mondayLessons = [
      const Lesson(
        time: '8:30 - 10:00',
        title: 'Высшая математика',
        teacher: 'Профессор Иванов',
        classroom: 'Аудитория 301',
        baseColor: colorMath,
        type: LessonType.regular,
        format: LessonFormat.lecture,
      ),
      // Пример ОНЛАЙН (LAB)
      const Lesson(
        time: '10:10 - 11:40',
        title: 'Физика (Онлайн)',
        teacher: 'Доцент Смирнова',
        classroom: 'Zoom ID 456',
        baseColor: colorPhysics,
        type: LessonType.online,
        format: LessonFormat.lab,
      ),
      const Lesson(
        time: '11:50 - 13:20',
        title: 'История',
        teacher: 'Преподаватель Николаев',
        classroom: 'Аудитория 405',
        baseColor: colorHistory,
        type: LessonType.regular,
        format: LessonFormat.lecture,
      ),
    ];

    // 2. ВТОРНИК
    final tuesdayLessons = [
      // Пример ЭКЗАМЕНА (LECTURE)
      const Lesson(
        time: '9:00 - 10:30',
        title: 'Экзамен по Англ. языку',
        teacher: 'Преподаватель Петрова',
        classroom: 'Аудитория 205',
        baseColor: colorEnglish,
        type: LessonType.exam,
        format: LessonFormat.lecture,
      ),
      const Lesson(
        time: '10:40 - 12:10',
        title: 'Информатика',
        teacher: 'Профессор Сидоров',
        classroom: 'Комп. класс 101',
        baseColor: colorIT,
        type: LessonType.regular,
        format: LessonFormat.practice,
      ),
    ];

    // 3. СРЕДА
    final wednesdayLessons = [
      const Lesson(
        time: '8:30 - 10:00',
        title: 'Физкультура',
        teacher: 'Тренер Кузнецов',
        classroom: 'Спортзал',
        baseColor: colorPE,
        type: LessonType.regular,
        format: LessonFormat.practice,
      ),
      // Пример ВОЗМОЖНОГО ИЗМЕНЕНИЯ (PRACTICE)
      const Lesson(
        time: '10:10 - 11:40',
        title: 'Высшая математика (Возможны изм.)',
        teacher: 'Профессор Иванов',
        classroom: 'Аудитория 301',
        baseColor: colorMath,
        type: LessonType.changed,
        format: LessonFormat.practice,
      ),
    ];

    // 4. ЧЕТВЕРГ
    final thursdayLessons = [
      const Lesson(
        time: '11:00 - 12:30',
        title: 'Английский язык',
        teacher: 'Преподаватель Петрова',
        classroom: 'Аудитория 205',
        baseColor: colorEnglish,
        type: LessonType.regular,
        format: LessonFormat.lecture,
      ),
      const Lesson(
        time: '12:40 - 14:10',
        title: 'Физика',
        teacher: 'Доцент Смирнова',
        classroom: 'Лаборатория 110',
        baseColor: colorPhysics,
        type: LessonType.regular,
        format: LessonFormat.lab,
      ),
      const Lesson(
        time: '14:20 - 15:50',
        title: 'История',
        teacher: 'Преподаватель Николаев',
        classroom: 'Аудитория 405',
        baseColor: colorHistory,
        type: LessonType.regular,
        format: LessonFormat.lecture,
      ),
    ];

    // 5. ПЯТНИЦА
    final fridayLessons = [
      const Lesson(
        time: '9:00 - 10:30',
        title: 'Философия',
        teacher: 'Профессор Аристотель',
        classroom: 'Аудитория 500',
        baseColor: colorHistory,
        type: LessonType.regular,
        format: LessonFormat.lecture,
      ),
      const Lesson(
        time: '10:40 - 12:10',
        title: 'Экономика',
        teacher: 'Преподаватель Смит',
        classroom: 'Аудитория 305',
        baseColor: colorMath,
        type: LessonType.regular,
        format: LessonFormat.practice,
      ),
    ];

    // 6. СУББОТА и 7. ВОСКРЕСЕНЬЕ (Выходной)
    final List<Lesson> saturdayLessons = [];
    final List<Lesson> sundayLessons = [];

    // Порядок: [0]=ПН, [1]=ВТ, [2]=СР, [3]=ЧТ, [4]=ПТ, [5]=СБ, [6]=ВС
    return [
      DailySchedule(day: 'Понедельник', lessons: mondayLessons),
      DailySchedule(day: 'Вторник', lessons: tuesdayLessons),
      DailySchedule(day: 'Среда', lessons: wednesdayLessons),
      DailySchedule(day: 'Четверг', lessons: thursdayLessons),
      DailySchedule(day: 'Пятница', lessons: fridayLessons),
      DailySchedule(day: 'Суббота', lessons: saturdayLessons),
      DailySchedule(day: 'Воскресенье', lessons: sundayLessons),
    ];
  }
}
