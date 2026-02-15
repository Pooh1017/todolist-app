# SQLite (sqflite) integration

## 1) Add packages in pubspec.yaml
dependencies:
  sqflite: ^2.3.3
  path: ^1.9.0

Then run: flutter pub get

## 2) Files included
- lib/models/task.dart
- lib/db/app_db.dart
- lib/db/task_dao.dart
- Updated pages:
  - lib/home_page.dart
  - lib/category_page.dart
  - lib/search_page.dart
  - lib/calendar_page.dart
  - lib/overview_page.dart
  - lib/side_menu_drawer.dart
  - lib/settings/settings_page.dart
  - lib/main.dart, lib/login_page.dart, lib/splash_page.dart, lib/firebase_options.dart (copied from your upload)

## 3) Notes
- All pages load data from SQLite and can add/toggle done/star/delete.
- Calendar page uses TableCalendar markers from DB.
