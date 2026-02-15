import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @thai.
  ///
  /// In en, this message translates to:
  /// **'ไทย'**
  String get thai;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get sectionCustomize;

  /// No description provided for @sectionDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get sectionDateTime;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @notificationsAndReminder.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Reminders'**
  String get notificationsAndReminder;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get dateFormat;

  /// No description provided for @defaultReminder.
  ///
  /// In en, this message translates to:
  /// **'Default reminder'**
  String get defaultReminder;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share app'**
  String get shareApp;

  /// No description provided for @rate5Stars.
  ///
  /// In en, this message translates to:
  /// **'Rate stars'**
  String get rate5Stars;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @onText.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get onText;

  /// No description provided for @offText.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offText;

  /// No description provided for @dateFmtDmySlash.
  ///
  /// In en, this message translates to:
  /// **'Day/Month/Year'**
  String get dateFmtDmySlash;

  /// No description provided for @dateFmtMdySlash.
  ///
  /// In en, this message translates to:
  /// **'Month/Day/Year'**
  String get dateFmtMdySlash;

  /// No description provided for @dateFmtYmdDash.
  ///
  /// In en, this message translates to:
  /// **'Year-Month-Day'**
  String get dateFmtYmdDash;

  /// No description provided for @dateFmtDmyDash.
  ///
  /// In en, this message translates to:
  /// **'Day-Month-Year'**
  String get dateFmtDmyDash;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version: {v}'**
  String versionLabel(String v);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String minutes(int m);

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Try this To-Do app: {link}'**
  String shareMessage(String link);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @signedInWith.
  ///
  /// In en, this message translates to:
  /// **'Signed in with'**
  String get signedInWith;

  /// No description provided for @notSetName.
  ///
  /// In en, this message translates to:
  /// **'No name set'**
  String get notSetName;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to log out now?'**
  String get logoutConfirmBody;

  /// No description provided for @providerGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get providerGoogle;

  /// No description provided for @providerEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Email / Password'**
  String get providerEmailPassword;

  /// No description provided for @providerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get providerPhone;

  /// No description provided for @feedbackPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type your feedback'**
  String get feedbackPrompt;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get feedbackHint;

  /// No description provided for @feedbackSentExample.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent (example)'**
  String get feedbackSentExample;

  /// No description provided for @facebookPage.
  ///
  /// In en, this message translates to:
  /// **'Facebook Page'**
  String get facebookPage;

  /// No description provided for @facebookPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add real link here'**
  String get facebookPlaceholder;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'thaitanapooh@email.com'**
  String get supportEmail;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notificationsEnableTitle;

  /// No description provided for @notificationsEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind before the scheduled time'**
  String get notificationsEnableSubtitle;

  /// No description provided for @rateThanksTitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your support!'**
  String get rateThanksTitle;

  /// No description provided for @rateNoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In the next step, this can open the real Store page.'**
  String get rateNoteSubtitle;

  /// No description provided for @goToStore.
  ///
  /// In en, this message translates to:
  /// **'Open Store page'**
  String get goToStore;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @rateSnackExample.
  ///
  /// In en, this message translates to:
  /// **'Example: Open Store page'**
  String get rateSnackExample;

  /// No description provided for @remindBefore.
  ///
  /// In en, this message translates to:
  /// **'Remind before'**
  String get remindBefore;

  /// No description provided for @themeApplyAllApp.
  ///
  /// In en, this message translates to:
  /// **'Change the app theme'**
  String get themeApplyAllApp;

  /// No description provided for @themeChooseHint.
  ///
  /// In en, this message translates to:
  /// **'Choose: Light / Dark'**
  String get themeChooseHint;

  /// No description provided for @themeLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Bright background, easy to read'**
  String get themeLightDesc;

  /// No description provided for @themeDarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Modern dark look, easier on eyes at night'**
  String get themeDarkDesc;

  /// No description provided for @themeNote.
  ///
  /// In en, this message translates to:
  /// **'Note: The app will save your choice and apply it immediately.'**
  String get themeNote;

  /// No description provided for @drawerAppTitle.
  ///
  /// In en, this message translates to:
  /// **'To Do List'**
  String get drawerAppTitle;

  /// No description provided for @drawerAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your tasks easily'**
  String get drawerAppSubtitle;

  /// No description provided for @drawerMenuSection.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get drawerMenuSection;

  /// No description provided for @drawerTodo.
  ///
  /// In en, this message translates to:
  /// **'To-do'**
  String get drawerTodo;

  /// No description provided for @drawerCategorySection.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get drawerCategorySection;

  /// No description provided for @drawerCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get drawerCategoriesTitle;

  /// No description provided for @drawerCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a category to view'**
  String get drawerCategoriesSubtitle;

  /// No description provided for @drawerCatWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get drawerCatWork;

  /// No description provided for @drawerCatWorkSub.
  ///
  /// In en, this message translates to:
  /// **'View all work tasks'**
  String get drawerCatWorkSub;

  /// No description provided for @drawerCatTodo.
  ///
  /// In en, this message translates to:
  /// **'To-do'**
  String get drawerCatTodo;

  /// No description provided for @drawerCatTodoSub.
  ///
  /// In en, this message translates to:
  /// **'To-do and starred items'**
  String get drawerCatTodoSub;

  /// No description provided for @drawerCatPlan.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get drawerCatPlan;

  /// No description provided for @drawerCatPlanSub.
  ///
  /// In en, this message translates to:
  /// **'Scheduled / planned tasks'**
  String get drawerCatPlanSub;

  /// No description provided for @drawerCatImportant.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get drawerCatImportant;

  /// No description provided for @drawerCatImportantSub.
  ///
  /// In en, this message translates to:
  /// **'Upcoming deadlines / urgent tasks'**
  String get drawerCatImportantSub;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items on {date}'**
  String calendarItemsTitle(String date);

  /// No description provided for @calendarEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No items today. Tap + to add one.'**
  String get calendarEmptyHint;

  /// No description provided for @addItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemTitle;

  /// No description provided for @typeItemHint.
  ///
  /// In en, this message translates to:
  /// **'Type an item...'**
  String get typeItemHint;

  /// No description provided for @selectedDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected day'**
  String get selectedDayLabel;

  /// No description provided for @setTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get setTimeLabel;

  /// No description provided for @timeInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter time'**
  String get timeInputTitle;

  /// No description provided for @timeInputHint.
  ///
  /// In en, this message translates to:
  /// **'HH:mm e.g. 09:30'**
  String get timeInputHint;

  /// No description provided for @timeInputInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter time as HH:mm (e.g. 09:30, 18:05)'**
  String get timeInputInvalid;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title or category...'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchEmpty;

  /// No description provided for @todoAllTitle.
  ///
  /// In en, this message translates to:
  /// **'To-do (Starred included)'**
  String get todoAllTitle;

  /// No description provided for @categoryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No items in this category.\nTap + to add.'**
  String get categoryEmptyHint;

  /// No description provided for @addInCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to “{category}”'**
  String addInCategoryTitle(String category);

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @pickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick time'**
  String get pickTime;

  /// No description provided for @timeInvalidHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter time in HH:mm (e.g. 09:30, 18:05)'**
  String get timeInvalidHint;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'To-Do List'**
  String get appTitle;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeFuture.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get homeFuture;

  /// No description provided for @homeOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get homeOverdue;

  /// No description provided for @homeDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get homeDone;

  /// No description provided for @emptyHome.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet.\nTap + to add one.'**
  String get emptyHome;

  /// No description provided for @emptyToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks for today'**
  String get emptyToday;

  /// No description provided for @emptyFuture.
  ///
  /// In en, this message translates to:
  /// **'No upcoming tasks'**
  String get emptyFuture;

  /// No description provided for @emptyOverdue.
  ///
  /// In en, this message translates to:
  /// **'No overdue tasks'**
  String get emptyOverdue;

  /// No description provided for @emptyDone.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks'**
  String get emptyDone;

  /// No description provided for @addTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTaskTitle;

  /// No description provided for @addTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Type your task...'**
  String get addTaskHint;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due: {dt}'**
  String dueLabel(String dt);

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get chooseDate;

  /// No description provided for @enterTime.
  ///
  /// In en, this message translates to:
  /// **'Enter time'**
  String get enterTime;

  /// No description provided for @nearDueAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get nearDueAllTitle;

  /// No description provided for @nearDueAllEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks due soon'**
  String get nearDueAllEmpty;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} items'**
  String itemsCount(int n);

  /// No description provided for @overviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTitle;

  /// No description provided for @overviewDoneCard.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks'**
  String get overviewDoneCard;

  /// No description provided for @overviewPendingCard.
  ///
  /// In en, this message translates to:
  /// **'Pending tasks'**
  String get overviewPendingCard;

  /// No description provided for @overviewPieTitle.
  ///
  /// In en, this message translates to:
  /// **'Task distribution'**
  String get overviewPieTitle;

  /// No description provided for @overviewEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get overviewEmptyAll;

  /// No description provided for @overviewNext30Title.
  ///
  /// In en, this message translates to:
  /// **'Tasks in 30 days'**
  String get overviewNext30Title;

  /// No description provided for @overviewNext30Empty.
  ///
  /// In en, this message translates to:
  /// **'No tasks in 30 days'**
  String get overviewNext30Empty;

  /// No description provided for @overviewCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get overviewCountLabel;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusDone;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusNearDue.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get statusNearDue;

  /// No description provided for @addItemHint.
  ///
  /// In en, this message translates to:
  /// **'Type an item...'**
  String get addItemHint;

  /// No description provided for @nowText.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowText;

  /// No description provided for @okText.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okText;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @timeAndReminder.
  ///
  /// In en, this message translates to:
  /// **'Time & reminder'**
  String get timeAndReminder;

  /// No description provided for @remindAt.
  ///
  /// In en, this message translates to:
  /// **'Remind at'**
  String get remindAt;

  /// No description provided for @reminderType.
  ///
  /// In en, this message translates to:
  /// **'Reminder type'**
  String get reminderType;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @addSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add subtask'**
  String get addSubtask;

  /// No description provided for @addSubtaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Add subtask'**
  String get addSubtaskTitle;

  /// No description provided for @addSubtaskHint.
  ///
  /// In en, this message translates to:
  /// **'Type subtask...'**
  String get addSubtaskHint;

  /// No description provided for @addText.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addText;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get deleteTaskTitle;

  /// No description provided for @deleteTaskBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteTaskBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @duplicatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Duplicated'**
  String get duplicatedSnack;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notDone.
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get notDone;

  /// No description provided for @remindOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get remindOnTime;

  /// No description provided for @remindMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{m} min before'**
  String remindMinutesBefore(int m);

  /// No description provided for @remindHoursBefore.
  ///
  /// In en, this message translates to:
  /// **'{h} hr before'**
  String remindHoursBefore(int h);

  /// No description provided for @remindDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'{d} day before'**
  String remindDaysBefore(int d);

  /// No description provided for @remindTypeNotify.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get remindTypeNotify;

  /// No description provided for @remindTypeSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get remindTypeSound;

  /// No description provided for @remindTypeVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get remindTypeVibrate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
