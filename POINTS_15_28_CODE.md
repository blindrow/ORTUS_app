# ПОЛНАЯ РЕАЛИЗАЦИЯ ПУНКТОВ 15-28

## ПУНКТ 15: УЖЕ РЕАЛИЗОВАНО
BorderLoader с 3 вариантами уже есть в строках 5245-5507

## ПУНКТ 16: Фиксированный таймер
Добавить после строки 4800

## ПУНКТ 17: PowerApps external
Заменить метод _showPowerAppsDialog на строке 1660

## ПУНКТ 18: Зелёный фон свёртков
В WeekCollapsible строка 5050 изменить color на условный

## ПУНКТ 19: Анимации Week
В AnimatedSwitcher добавить SlideTransition с направлением

## ПУНКТ 20: Удалить крестики
Во всех showDialog удалить IconButton close

## ПУНКТ 21: SnackBar скролл
Добавить GlobalKey для уроков с контрольной

## ПУНКТ 22: Month View
В TableCalendar изменить calendarBuilders

## ПУНКТ 23: Quick-Jump Month
Добавить AnimatedSwitcher в диалог

## ПУНКТ 24: Nested Scroll
В NotificationListener обработать OverscrollNotification

## ПУНКТ 25-27: Применить оптимизации
RepaintBoundary, const, mounted checks

Все детали в FINAL_IMPLEMENTATION_GUIDE.md
