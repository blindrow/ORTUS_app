# ⚠️ ФАЙЛ ПОВРЕЖДЕН - НУЖЕН ОТКАТ

## 🔧 ЧТО СЛУЧИЛОСЬ:
Файл `schedule_page.dart` поврежден при редактировании. Класс `_SchedulePageState` закрылся преждевременно, и методы `_buildDayScheduleList` и `_buildWeekScheduleList` оказались вне класса.

## ✅ ЧТО РАБОТАЛО ДО ПОЛОМКИ:
- ✅ Контрольные работы отображаются (красный блок)
- ✅ Пульсация работает
- ✅ SnackBar появляется при открытии дня с контрольной
- ✅ Все 3 вкладки (День, Неделя, Месяц) работают

## 🎯 РЕШЕНИЕ:

### Вариант 1: Откат через Git
```bash
cd "c:\Users\Michael\Desktop\ORTUS project\ORTUS_mobile\ORTUS_project(flutter)\flutter_application_1"
git checkout lib/schedule_page.dart
```

### Вариант 2: Откат через Ctrl+Z
1. Откройте файл `schedule_page.dart` в VS Code
2. Нажимайте `Ctrl+Z` много раз (50-100 раз)
3. Пока не вернётесь к рабочей версии
4. Сохраните файл

### Вариант 3: Восстановить из резервной копии
Если у вас есть резервная копия файла - восстановите её.

---

## 📋 ПОСЛЕ ВОССТАНОВЛЕНИЯ - ПРИМЕНИТЬ ИЗМЕНЕНИЯ:

### 1. ЗЕЛЁНЫЙ БЛОК КОНТРОЛЬНОЙ

Найдите в файле `schedule_page.dart` строку ~3200 (в LessonTile):
```dart
// БЫЛО (красный):
decoration: BoxDecoration(
  color: const Color(0xFFFFEBEE),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: const Color(0xFFE57373), width: 2),
),

// СТАЛО (зелёный):
decoration: BoxDecoration(
  color: const Color(0xFF409187).withOpacity(0.15),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: const Color(0xFF409187), width: 2),
),
```

### 2. ИКОНКА ДОКУМЕНТА

Найдите строку ~3214:
```dart
// БЫЛО:
const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 24),

// СТАЛО:
const Icon(Icons.description_outlined, color: Color(0xFF409187), size: 24),
```

### 3. ЦВЕТ ТЕКСТА

Найдите строку ~3220:
```dart
// БЫЛО:
style: const TextStyle(
  color: Color(0xFFD32F2F),
  fontWeight: FontWeight.bold,
  fontSize: 15,
),

// СТАЛО:
style: const TextStyle(
  color: Color(0xFF2C6B63),
  fontWeight: FontWeight.bold,
  fontSize: 15,
),
```

### 4. CLIPRECT ДЛЯ ОГРАНИЧЕНИЯ АНИМАЦИИ

Найдите строку ~3203 и оберните ScaleTransition:
```dart
// БЫЛО:
ScaleTransition(
  scale: _pulseAnimation,
  child: Container(
    // ...
  ),
),

// СТАЛО:
ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: ScaleTransition(
    scale: _pulseAnimation,
    child: Container(
      // ...
    ),
  ),
),
```

### 5. ПУЛЬСАЦИЯ - 2 РАЗА, БЫСТРАЯ

Найдите в `_LessonTileState.initState()` строку ~2911:
```dart
// БЫЛО:
_pulseController = AnimationController(
  duration: const Duration(milliseconds: 1500),
  vsync: this,
);
_pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
);

if (widget.shouldPulse && widget.examNote != null) {
  _pulseController.repeat(reverse: true);
}

// СТАЛО:
_pulseController = AnimationController(
  duration: const Duration(milliseconds: 600), // Быстрее
  vsync: this,
);
_pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
);

if (widget.shouldPulse && widget.examNote != null) {
  // Пульсация только 2 раза
  _pulseController.forward().then((_) {
    _pulseController.reverse().then((_) {
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });
    });
  });
}
```

### 6. ЗЕЛЁНЫЙ SNACKBAR ДЛЯ КОНТРОЛЬНЫХ

Найдите `_showExamSnackBar()` строка ~448:
```dart
// Изменить:
backgroundColor: const Color(0xFF409187),  // Зелёный вместо красного
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(12),  // Закруглённый
),

// Изменить иконку:
const Icon(Icons.description_outlined, color: Colors.white, size: 20),

// Добавить фон кнопке:
action: SnackBarAction(
  label: 'ПОКАЗАТЬ',
  textColor: Colors.white,
  backgroundColor: Colors.white.withOpacity(0.2),  // Добавить
  onPressed: () {
    // ...
  },
),
```

### 7. POWERAPPS - РЕАЛЬНОЕ ОТКРЫТИЕ

#### A. Добавить пакет в `pubspec.yaml`:
```yaml
dependencies:
  url_launcher: ^6.3.1
```

#### B. Установить пакет:
```bash
flutter pub get
```

#### C. Добавить import в `schedule_page.dart`:
```dart
import 'package:url_launcher/url_launcher.dart';
```

#### D. Изменить `_showPowerAppsDialog()` строка ~1200:

Обернуть InkWell в Material:
```dart
Material(
  color: Colors.transparent,
  child: InkWell(
    onTap: () async {
      Navigator.of(context).pop();
      
      // Стильный SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.power, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Открываем PowerApps...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF742774),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      
      // Открыть PowerApps
      try {
        final Uri powerAppsUri = Uri.parse('ms-powerapp://');
        if (await canLaunchUrl(powerAppsUri)) {
          await launchUrl(powerAppsUri, mode: LaunchMode.externalApplication);
        } else {
          final Uri playStoreUri = Uri.parse('market://details?id=com.microsoft.msapps');
          if (await canLaunchUrl(playStoreUri)) {
            await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не удалось открыть PowerApps: $e'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    },
    splashColor: const Color(0xFF742774).withOpacity(0.3),
    highlightColor: const Color(0xFF742774).withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      // ... существующий код
    ),
  ),
),
```

---

## 🎯 ПОРЯДОК ДЕЙСТВИЙ:

1. ✅ **Откатите файл** к рабочей версии
2. ✅ **Проверьте** что приложение запускается
3. ✅ **Примените изменения** по одному
4. ✅ **Тестируйте** после каждого изменения
5. ✅ **Сохраняйте** после успешного теста

## 📱 РЕЗУЛЬТАТ:
- ✅ Зелёный прозрачный блок контрольной
- ✅ Иконка документа 📄
- ✅ Быстрая пульсация 2 раза
- ✅ Анимация не выходит за границы
- ✅ Зелёный закруглённый SnackBar
- ✅ PowerApps открывается реально
- ✅ Фиолетовый стильный SnackBar для PowerApps

---

## ⚠️ ВАЖНО:
- Делайте изменения **по одному**
- **Тестируйте** после каждого
- **Сохраняйте** резервные копии
- Используйте `flutter run` для проверки

**Удачи!** 🚀
