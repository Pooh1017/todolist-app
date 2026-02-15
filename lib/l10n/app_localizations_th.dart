// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get settings => 'ตั้งค่า';

  @override
  String get language => 'ภาษา';

  @override
  String get thai => 'ไทย';

  @override
  String get english => 'English';

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get sectionCustomize => 'ปรับแต่ง';

  @override
  String get sectionDateTime => 'วันที่ & เวลา';

  @override
  String get sectionAbout => 'เกี่ยวกับ';

  @override
  String get account => 'บัญชี';

  @override
  String get theme => 'ธีม';

  @override
  String get notificationsAndReminder => 'การแจ้งเตือน & เตือนความจำ';

  @override
  String get dateFormat => 'รูปแบบวันที่';

  @override
  String get defaultReminder => 'ค่าเริ่มต้นการแจ้งเตือน';

  @override
  String get shareApp => 'แบ่งปันแอพ';

  @override
  String get rate5Stars => 'ให้ดาว';

  @override
  String get contactUs => 'ติดต่อเรา';

  @override
  String get feedback => 'ความคิดเห็น';

  @override
  String get system => 'ตามระบบ';

  @override
  String get light => 'สว่าง';

  @override
  String get dark => 'มืด';

  @override
  String get onText => 'เปิด';

  @override
  String get offText => 'ปิด';

  @override
  String get dateFmtDmySlash => 'วัน/เดือน/ปี';

  @override
  String get dateFmtMdySlash => 'เดือน/วัน/ปี';

  @override
  String get dateFmtYmdDash => 'ปี-เดือน-วัน';

  @override
  String get dateFmtDmyDash => 'วัน-เดือน-ปี';

  @override
  String versionLabel(String v) {
    return 'เวอร์ชัน: $v';
  }

  @override
  String minutes(int m) {
    return '$m นาที';
  }

  @override
  String shareMessage(String link) {
    return 'ลองใช้แอพ To Do List: $link';
  }

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get save => 'บันทึก';

  @override
  String get ok => 'ตกลง';

  @override
  String get now => 'ตอนนี้';

  @override
  String get send => 'ส่ง';

  @override
  String get username => 'ชื่อผู้ใช้';

  @override
  String get email => 'อีเมล';

  @override
  String get userId => 'User ID';

  @override
  String get signedInWith => 'เข้าสู่ระบบด้วย';

  @override
  String get notSetName => 'ยังไม่ได้ตั้งชื่อ';

  @override
  String get logoutConfirmTitle => 'ออกจากระบบ?';

  @override
  String get logoutConfirmBody => 'คุณต้องการออกจากระบบตอนนี้หรือไม่?';

  @override
  String get providerGoogle => 'Google';

  @override
  String get providerEmailPassword => 'อีเมล / รหัสผ่าน';

  @override
  String get providerPhone => 'เบอร์โทรศัพท์';

  @override
  String get feedbackPrompt => 'พิมพ์ความคิดเห็นของคุณ';

  @override
  String get feedbackHint => 'เขียนข้อความ...';

  @override
  String get feedbackSentExample => 'ส่งความคิดเห็นแล้ว (ตัวอย่าง)';

  @override
  String get facebookPage => 'เพจ Facebook';

  @override
  String get facebookPlaceholder => 'สามารถเพิ่มลิงก์จริงได้';

  @override
  String get supportEmail => 'thaitanapooh@email.com';

  @override
  String get notificationsTitle => 'การแจ้งเตือน';

  @override
  String get notificationsEnableTitle => 'เปิดการแจ้งเตือน';

  @override
  String get notificationsEnableSubtitle => 'แจ้งเตือนก่อนถึงเวลาที่ตั้งไว้';

  @override
  String get rateThanksTitle => 'ขอบคุณสำหรับการสนับสนุน!';

  @override
  String get rateNoteSubtitle => 'จะต่อไปหน้า Store จริงได้ในขั้นต่อไป';

  @override
  String get goToStore => 'ไปที่หน้า Store';

  @override
  String get goBack => 'กลับไปก่อน';

  @override
  String get rateSnackExample => 'ตัวอย่าง: ไปหน้า Store';

  @override
  String get remindBefore => 'เตือนล่วงหน้า';

  @override
  String get themeApplyAllApp => 'เปลี่ยนธีมทั้งแอพ';

  @override
  String get themeChooseHint => 'เลือกได้: สว่าง / มืด';

  @override
  String get themeLightDesc => 'พื้นหลังสว่าง อ่านง่าย สบายตา';

  @override
  String get themeDarkDesc => 'ดำอมฟ้า ดูทันสมัย ถนอมสายตากลางคืน';

  @override
  String get themeNote =>
      'หมายเหตุ: ระบบจะบันทึกค่าที่คุณเลือกไว้ และนำไปใช้ทันที';

  @override
  String get drawerAppTitle => 'To Do List';

  @override
  String get drawerAppSubtitle => 'จัดการงานของคุณแบบง่าย ๆ';

  @override
  String get drawerMenuSection => 'เมนู';

  @override
  String get drawerTodo => 'สิ่งที่ต้องทำ';

  @override
  String get drawerCategorySection => 'ประเภท';

  @override
  String get drawerCategoriesTitle => 'ประเภท';

  @override
  String get drawerCategoriesSubtitle => 'เลือกหมวดที่ต้องการดู';

  @override
  String get drawerCatWork => 'งาน';

  @override
  String get drawerCatWorkSub => 'ดูรายการงานทั้งหมด';

  @override
  String get drawerCatTodo => 'สิ่งที่ต้องทำ';

  @override
  String get drawerCatTodoSub => 'รายการที่ต้องทำและรายการสำคัญ';

  @override
  String get drawerCatPlan => 'ที่วางแผนไว้';

  @override
  String get drawerCatPlanSub => 'งานที่นัดหมาย/วางแผนไว้';

  @override
  String get drawerCatImportant => 'ใกล้ครบกำหนด';

  @override
  String get drawerCatImportantSub => 'งานที่ใกล้ถึงกำหนด/ต้องรีบทำ';

  @override
  String get calendarTitle => 'ปฏิทิน';

  @override
  String calendarItemsTitle(String date) {
    return 'รายการ $date';
  }

  @override
  String get calendarEmptyHint => 'ไม่มีรายการในวันนี้ กด + เพื่อเพิ่ม';

  @override
  String get addItemTitle => 'เพิ่มรายการ';

  @override
  String get typeItemHint => 'พิมพ์รายการ...';

  @override
  String get selectedDayLabel => 'วันเลือก';

  @override
  String get setTimeLabel => 'ใส่เวลา';

  @override
  String get timeInputTitle => 'ใส่เวลา';

  @override
  String get timeInputHint => 'HH:mm เช่น 09:30';

  @override
  String get timeInputInvalid => 'กรุณาใส่เวลาเป็น HH:mm (เช่น 09:30, 18:05)';

  @override
  String get searchTitle => 'ค้นหา';

  @override
  String get searchHint => 'ค้นหาจากชื่อหรือหมวด...';

  @override
  String get searchEmpty => 'ไม่พบรายการ';

  @override
  String get todoAllTitle => 'สิ่งที่ต้องทำ (รวมดาว)';

  @override
  String get categoryEmptyHint => 'ยังไม่มีรายการในหมวดนี้\nกด + เพื่อเพิ่ม';

  @override
  String addInCategoryTitle(String category) {
    return 'เพิ่มในหมวด “$category”';
  }

  @override
  String get pickDate => 'เลือกวันที่';

  @override
  String get pickTime => 'ใส่เวลา';

  @override
  String get timeInvalidHint => 'กรุณาใส่เวลาเป็น HH:mm (เช่น 09:30, 18:05)';

  @override
  String get appTitle => 'To Do List';

  @override
  String get homeToday => 'วันนี้';

  @override
  String get homeFuture => 'งานถัดไป';

  @override
  String get homeOverdue => 'เลยกำหนด';

  @override
  String get homeDone => 'เสร็จแล้ว';

  @override
  String get emptyHome => 'ยังไม่มีรายการ\nกด + เพื่อเพิ่มงาน';

  @override
  String get emptyToday => 'ยังไม่มีงานวันนี้';

  @override
  String get emptyFuture => 'ยังไม่มีงานถัดไป';

  @override
  String get emptyOverdue => 'ยังไม่มีงานเลยกำหนด';

  @override
  String get emptyDone => 'ยังไม่มีงานที่เสร็จแล้ว';

  @override
  String get addTaskTitle => 'เพิ่มรายการ';

  @override
  String get addTaskHint => 'พิมพ์สิ่งที่ต้องทำ...';

  @override
  String dueLabel(String dt) {
    return 'กำหนด: $dt';
  }

  @override
  String get chooseDate => 'เลือกวันที่';

  @override
  String get enterTime => 'ใส่เวลา';

  @override
  String get nearDueAllTitle => 'ใกล้ครบกำหนด';

  @override
  String get nearDueAllEmpty => 'ยังไม่มีงานที่ใกล้ครบกำหนด';

  @override
  String itemsCount(int n) {
    return '$n รายการ';
  }

  @override
  String get overviewTitle => 'ภาพรวม';

  @override
  String get overviewDoneCard => 'งานที่เสร็จสมบูรณ์';

  @override
  String get overviewPendingCard => 'งานที่รอดำเนินการ';

  @override
  String get overviewPieTitle => 'สัดส่วนงานทั้งหมด';

  @override
  String get overviewEmptyAll => 'ยังไม่มีงานในระบบ';

  @override
  String get overviewNext30Title => 'งานใน 30 วัน';

  @override
  String get overviewNext30Empty => 'ไม่มีงานใน 30 วัน';

  @override
  String get overviewCountLabel => 'จำนวนงาน';

  @override
  String get statusDone => 'เสร็จแล้ว';

  @override
  String get statusOverdue => 'เลยกำหนด';

  @override
  String get statusInProgress => 'รอดำเนินการ';

  @override
  String get statusNearDue => 'ใกล้ครบกำหนด';

  @override
  String get addItemHint => 'พิมพ์รายการ...';

  @override
  String get nowText => 'ตอนนี้';

  @override
  String get okText => 'ตกลง';

  @override
  String get dueDate => 'วันที่ครบกำหนด';

  @override
  String get timeAndReminder => 'เวลา & แจ้งเตือน';

  @override
  String get remindAt => 'การแจ้งเตือนที่';

  @override
  String get reminderType => 'ประเภทการแจ้งเตือน';

  @override
  String get note => 'หมายเหตุ';

  @override
  String get addSubtask => 'เพิ่มงานย่อย';

  @override
  String get addSubtaskTitle => 'เพิ่มงานย่อย';

  @override
  String get addSubtaskHint => 'พิมพ์งานย่อย...';

  @override
  String get addText => 'เพิ่ม';

  @override
  String get close => 'ปิด';

  @override
  String get deleteTaskTitle => 'ลบรายการนี้?';

  @override
  String get deleteTaskBody => 'การลบจะไม่สามารถกู้คืนได้';

  @override
  String get delete => 'ลบ';

  @override
  String get duplicate => 'สร้างสำเนา';

  @override
  String get duplicatedSnack => 'สร้างสำเนาแล้ว';

  @override
  String get completed => 'เสร็จแล้ว';

  @override
  String get notDone => 'ยังไม่เสร็จ';

  @override
  String get remindOnTime => 'ตรงเวลา';

  @override
  String remindMinutesBefore(int m) {
    return '$m นาที ก่อน';
  }

  @override
  String remindHoursBefore(int h) {
    return '$h ชม. ก่อน';
  }

  @override
  String remindDaysBefore(int d) {
    return '$d วัน ก่อน';
  }

  @override
  String get remindTypeNotify => 'การแจ้งเตือน';

  @override
  String get remindTypeSound => 'เสียง';

  @override
  String get remindTypeVibrate => 'สั่น';
}
