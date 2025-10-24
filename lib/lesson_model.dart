import 'package:flutter/material.dart';

// 1. Enum для типов занятий (УРГЕНТНОСТЬ/ЛОКАЦИЯ)
enum LessonType {
  regular, // Обычное занятие
  online,  // Дистанционное (Zoom)
  exam,    // Экзамен
  changed, // Возможно, поменяется (оранжевый)
}

// 2. Enum для ФОРМАТА занятия (LECT/PRAC/LAB)
enum LessonFormat {
  lecture, // LECT
  practice, // PRAC
  lab, // LAB
}

// 3. Класс урока (Lesson)
class Lesson {
  final String time;
  final String title;
  final String teacher;
  final String classroom;
  final Color baseColor; // Светлый цвет предмета (для фона)
  final LessonType type; 
  final LessonFormat format; 

  const Lesson({
    required this.time,
    required this.title,
    required this.teacher,
    required this.classroom,
    required this.baseColor,
    this.type = LessonType.regular, 
    this.format = LessonFormat.lecture,
  });
}

// 4. Класс расписания на день (DailySchedule)
class DailySchedule {
  final String day;
  final List<Lesson> lessons;

  DailySchedule({required this.day, required this.lessons});
}