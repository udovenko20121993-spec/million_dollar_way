# App Icons - Million Dollar Way

## Варіанти іконок

### 1. `app_icon.svg` - Піраміда успіху (Рекомендовано)
- Золота піраміда символізує шлях до мільйона
- Знак долара в центрі
- Зірки - досягнення та віхи
- Графік росту на фоні

### 2. `app_icon_simple.svg` - Мінімалістична
- Золоте кільце (монета)
- Зелений графік росту
- Великий знак долара
- Чистий дизайн

### 3. `app_icon_modern.svg` - Сучасна M
- Буква M як гори/графік
- Точки як цілі на вершинах
- Мінімалізм у стилі iOS

## Кольори бренду

| Колір | HEX | Використання |
|-------|-----|--------------|
| Золотий | `#D4AF37` | Основний акцент |
| Яскравий золотий | `#FFD700` | Світіння, зірки |
| Темний золотий | `#B8860B` | Тіні |
| Зелений | `#00C853` | Успіх, графіки |
| Темний фон | `#0F0F0F` | Фон |
| Сірий | `#1A1A1A` | Вторинний фон |

## Як згенерувати іконки

### Крок 1: Конвертація SVG → PNG

**Онлайн:**
- [svgtopng.com](https://svgtopng.com/)
- [cloudconvert.com](https://cloudconvert.com/svg-to-png)

**Локально (Inkscape):**
```bash
inkscape app_icon.svg --export-png=app_icon.png --export-width=1024 --export-height=1024
```

**ImageMagick:**
```bash
convert -background none -density 300 app_icon.svg -resize 1024x1024 app_icon.png
```

### Крок 2: Генерація іконок Flutter

```bash
# Встановити залежності
flutter pub get

# Згенерувати іконки
flutter pub run flutter_launcher_icons
```

### Крок 3: Адаптивна іконка (Android)

Створіть `app_icon_foreground.png`:
- Розмір: 1024x1024
- Контент в центральних 66% (важлива зона)
- Прозорий фон

Фон автоматично буде `#0F0F0F` (налаштовано в pubspec.yaml)

## Результат

Після генерації іконки з'являться в:

**Android:**
- `android/app/src/main/res/mipmap-hdpi/`
- `android/app/src/main/res/mipmap-mdpi/`
- `android/app/src/main/res/mipmap-xhdpi/`
- `android/app/src/main/res/mipmap-xxhdpi/`
- `android/app/src/main/res/mipmap-xxxhdpi/`

**iOS:**
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Розміри

| Платформа | Розміри |
|-----------|---------|
| Android | 48, 72, 96, 144, 192 |
| iOS | 20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024 |
| Web | 192, 512 |
| macOS | 16, 32, 64, 128, 256, 512, 1024 |
