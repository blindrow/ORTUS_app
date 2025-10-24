# 🎯 СПИСОК ИЗМЕНЕНИЙ ДЛЯ КОНТРОЛЬНЫХ РАБОТ

## ✅ ЧТО УЖЕ РАБОТАЕТ:
- Контрольные работы отображаются (красный блок)
- Пульсация работает
- SnackBar появляется

## 🔧 ЧТО НУЖНО ИЗМЕНИТЬ:

### 1. Цвет блока контрольной (ЗЕЛЁНЫЙ вместо красного)
```dart
// В LessonTile, строка ~3240
decoration: BoxDecoration(
  color: const Color(0xFF409187).withOpacity(0.15),  // Зелёный прозрачный
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: const Color(0xFF409187), width: 2),  // Зелёная рамка
),
```

### 2. Иконка (📄 документ вместо ⚠️)
```dart
// В LessonTile, строка ~3252
const Icon(Icons.description_outlined, color: Color(0xFF409187), size: 24),
```

### 3. Цвет текста (тёмно-зелёный)
```dart
// В LessonTile, строка ~3258
style: const TextStyle(
  color: Color(0xFF2C6B63),  // Тёмно-зелёный
  fontWeight: FontWeight.bold,
  fontSize: 15,
),
```

### 4. Пульсация - только 2 раза, быстрая
```dart
// В _LessonTileState.initState(), строка ~2911
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

### 5. ClipRRect для ограничения анимации
```dart
// Обернуть ScaleTransition в ClipRRect, строка ~3240
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

### 6. SnackBar для контрольных (зелёный, закруглённый)
```dart
// В _showExamSnackBar(), строка ~448
SnackBar(
  content: Row(
    children: [
      const Icon(Icons.description_outlined, color: Colors.white, size: 20),
      const SizedBox(width: 12),
      const Expanded(
        child: Text(
          'Контрольная работа',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    ],
  ),
  backgroundColor: const Color(0xFF409187),  // Зелёный
  behavior: SnackBarBehavior.floating,
  margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
  duration: const Duration(seconds: 5),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),  // Закруглённый
  ),
  action: SnackBarAction(
    label: 'ПОКАЗАТЬ',
    textColor: Colors.white,
    backgroundColor: Colors.white.withOpacity(0.2),
    onPressed: () {
      // Прокрутка к контрольной
    },
  ),
),
```

### 7. PowerApps - добавить url_launcher
```yaml
# В pubspec.yaml
dependencies:
  url_launcher: ^6.3.1
```

```dart
// В schedule_page.dart
import 'package:url_launcher/url_launcher.dart';

// В _showPowerAppsDialog(), обернуть InkWell в Material
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
        // Показать ошибку
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

## 📝 ВАЖНО:
- Файл schedule_page.dart сейчас поврежден
- Нужно восстановить из Git или сделать откат
- Затем применить изменения по одному
- Тестировать после каждого изменения

## 🎯 РЕЗУЛЬТАТ:
- ✅ Зелёный прозрачный блок контрольной
- ✅ Иконка документа 📄
- ✅ Быстрая пульсация 2 раза
- ✅ Анимация не выходит за границы
- ✅ Зелёный закруглённый SnackBar
- ✅ PowerApps открывается реально
- ✅ Фиолетовый стильный SnackBar для PowerApps
