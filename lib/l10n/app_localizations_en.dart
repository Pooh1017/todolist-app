// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get thai => 'ไทย';

  @override
  String get english => 'English';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionCustomize => 'Customize';

  @override
  String get sectionDateTime => 'Date & Time';

  @override
  String get sectionAbout => 'About';

  @override
  String get account => 'Account';

  @override
  String get theme => 'Theme';

  @override
  String get notificationsAndReminder => 'Notifications & Reminders';

  @override
  String get dateFormat => 'Date format';

  @override
  String get defaultReminder => 'Default reminder';

  @override
  String get shareApp => 'Share app';

  @override
  String get rate5Stars => 'Rate stars';

  @override
  String get contactUs => 'Contact us';

  @override
  String get feedback => 'Feedback';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get onText => 'On';

  @override
  String get offText => 'Off';

  @override
  String get dateFmtDmySlash => 'Day/Month/Year';

  @override
  String get dateFmtMdySlash => 'Month/Day/Year';

  @override
  String get dateFmtYmdDash => 'Year-Month-Day';

  @override
  String get dateFmtDmyDash => 'Day-Month-Year';

  @override
  String versionLabel(String v) {
    return 'Version: $v';
  }

  @override
  String minutes(int m) {
    return '$m min';
  }

  @override
  String shareMessage(String link) {
    return 'Try this To-Do app: $link';
  }

  @override
  String get logout => 'Log out';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get ok => 'OK';

  @override
  String get now => 'Now';

  @override
  String get send => 'Send';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get userId => 'User ID';

  @override
  String get signedInWith => 'Signed in with';

  @override
  String get notSetName => 'No name set';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody => 'Do you want to log out now?';

  @override
  String get providerGoogle => 'Google';

  @override
  String get providerEmailPassword => 'Email / Password';

  @override
  String get providerPhone => 'Phone number';

  @override
  String get feedbackPrompt => 'Type your feedback';

  @override
  String get feedbackHint => 'Write a message...';

  @override
  String get feedbackSentExample => 'Feedback sent (example)';

  @override
  String get facebookPage => 'Facebook Page';

  @override
  String get facebookPlaceholder => 'Add real link here';

  @override
  String get supportEmail => 'thaitanapooh@email.com';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEnableTitle => 'Enable notifications';

  @override
  String get notificationsEnableSubtitle => 'Remind before the scheduled time';

  @override
  String get rateThanksTitle => 'Thanks for your support!';

  @override
  String get rateNoteSubtitle =>
      'In the next step, this can open the real Store page.';

  @override
  String get goToStore => 'Open Store page';

  @override
  String get goBack => 'Go back';

  @override
  String get rateSnackExample => 'Example: Open Store page';

  @override
  String get remindBefore => 'Remind before';

  @override
  String get themeApplyAllApp => 'Change the app theme';

  @override
  String get themeChooseHint => 'Choose: Light / Dark';

  @override
  String get themeLightDesc => 'Bright background, easy to read';

  @override
  String get themeDarkDesc => 'Modern dark look, easier on eyes at night';

  @override
  String get themeNote =>
      'Note: The app will save your choice and apply it immediately.';

  @override
  String get drawerAppTitle => 'To Do List';

  @override
  String get drawerAppSubtitle => 'Manage your tasks easily';

  @override
  String get drawerMenuSection => 'Menu';

  @override
  String get drawerTodo => 'To-do';

  @override
  String get drawerCategorySection => 'Categories';

  @override
  String get drawerCategoriesTitle => 'Categories';

  @override
  String get drawerCategoriesSubtitle => 'Choose a category to view';

  @override
  String get drawerCatWork => 'Work';

  @override
  String get drawerCatWorkSub => 'View all work tasks';

  @override
  String get drawerCatTodo => 'To-do';

  @override
  String get drawerCatTodoSub => 'To-do and starred items';

  @override
  String get drawerCatPlan => 'Planned';

  @override
  String get drawerCatPlanSub => 'Scheduled / planned tasks';

  @override
  String get drawerCatImportant => 'Due soon';

  @override
  String get drawerCatImportantSub => 'Upcoming deadlines / urgent tasks';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String calendarItemsTitle(String date) {
    return 'Items on $date';
  }

  @override
  String get calendarEmptyHint => 'No items today. Tap + to add one.';

  @override
  String get addItemTitle => 'Add item';

  @override
  String get typeItemHint => 'Type an item...';

  @override
  String get selectedDayLabel => 'Selected day';

  @override
  String get setTimeLabel => 'Set time';

  @override
  String get timeInputTitle => 'Enter time';

  @override
  String get timeInputHint => 'HH:mm e.g. 09:30';

  @override
  String get timeInputInvalid =>
      'Please enter time as HH:mm (e.g. 09:30, 18:05)';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search by title or category...';

  @override
  String get searchEmpty => 'No results';

  @override
  String get todoAllTitle => 'To-do (Starred included)';

  @override
  String get categoryEmptyHint => 'No items in this category.\nTap + to add.';

  @override
  String addInCategoryTitle(String category) {
    return 'Add to “$category”';
  }

  @override
  String get pickDate => 'Pick date';

  @override
  String get pickTime => 'Pick time';

  @override
  String get timeInvalidHint =>
      'Please enter time in HH:mm (e.g. 09:30, 18:05)';

  @override
  String get appTitle => 'To-Do List';

  @override
  String get homeToday => 'Today';

  @override
  String get homeFuture => 'Upcoming';

  @override
  String get homeOverdue => 'Overdue';

  @override
  String get homeDone => 'Completed';

  @override
  String get emptyHome => 'No tasks yet.\nTap + to add one.';

  @override
  String get emptyToday => 'No tasks for today';

  @override
  String get emptyFuture => 'No upcoming tasks';

  @override
  String get emptyOverdue => 'No overdue tasks';

  @override
  String get emptyDone => 'No completed tasks';

  @override
  String get addTaskTitle => 'Add task';

  @override
  String get addTaskHint => 'Type your task...';

  @override
  String dueLabel(String dt) {
    return 'Due: $dt';
  }

  @override
  String get chooseDate => 'Choose date';

  @override
  String get enterTime => 'Enter time';

  @override
  String get nearDueAllTitle => 'Due soon';

  @override
  String get nearDueAllEmpty => 'No tasks due soon';

  @override
  String itemsCount(int n) {
    return '$n items';
  }

  @override
  String get overviewTitle => 'Overview';

  @override
  String get overviewDoneCard => 'Completed tasks';

  @override
  String get overviewPendingCard => 'Pending tasks';

  @override
  String get overviewPieTitle => 'Task distribution';

  @override
  String get overviewEmptyAll => 'No tasks yet';

  @override
  String get overviewNext30Title => 'Tasks in 30 days';

  @override
  String get overviewNext30Empty => 'No tasks in 30 days';

  @override
  String get overviewCountLabel => 'Tasks';

  @override
  String get statusDone => 'Completed';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusNearDue => 'Due soon';

  @override
  String get addItemHint => 'Type an item...';

  @override
  String get nowText => 'Now';

  @override
  String get okText => 'OK';

  @override
  String get dueDate => 'Due date';

  @override
  String get timeAndReminder => 'Time & reminder';

  @override
  String get remindAt => 'Remind at';

  @override
  String get reminderType => 'Reminder type';

  @override
  String get note => 'Note';

  @override
  String get addSubtask => 'Add subtask';

  @override
  String get addSubtaskTitle => 'Add subtask';

  @override
  String get addSubtaskHint => 'Type subtask...';

  @override
  String get addText => 'Add';

  @override
  String get close => 'Close';

  @override
  String get deleteTaskTitle => 'Delete this task?';

  @override
  String get deleteTaskBody => 'This cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get duplicatedSnack => 'Duplicated';

  @override
  String get completed => 'Completed';

  @override
  String get notDone => 'Not done';

  @override
  String get remindOnTime => 'On time';

  @override
  String remindMinutesBefore(int m) {
    return '$m min before';
  }

  @override
  String remindHoursBefore(int h) {
    return '$h hr before';
  }

  @override
  String remindDaysBefore(int d) {
    return '$d day before';
  }

  @override
  String get remindTypeNotify => 'Notification';

  @override
  String get remindTypeSound => 'Sound';

  @override
  String get remindTypeVibrate => 'Vibrate';
}
