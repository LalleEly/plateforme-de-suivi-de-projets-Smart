// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ProjectFlow';

  @override
  String get appTagline => 'إدارة المشاريع والفرق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get create => 'إنشاء';

  @override
  String get edit => 'تعديل';

  @override
  String get save => 'حفظ';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String get loginSubtitle => 'الوصول إلى مساحة عملك';

  @override
  String get registerSubtitle => 'انضم إلى فريقك على ProjectFlow';

  @override
  String get tabLogin => 'تسجيل الدخول';

  @override
  String get tabRegister => 'التسجيل';

  @override
  String get fieldFirstName => 'الاسم الأول';

  @override
  String get fieldLastName => 'الاسم العائلي';

  @override
  String get fieldEmail => 'البريد الإلكتروني';

  @override
  String get fieldPassword => 'كلمة المرور';

  @override
  String get forgotPasswordLink => 'نسيت كلمة المرور؟';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get registerButton => 'إنشاء حسابي';

  @override
  String get restrictedAccessNotice => 'الوصول مخصص للأعضاء المسجلين فقط.';

  @override
  String get errorFillAllFields => 'يرجى ملء جميع الحقول';

  @override
  String get errorPasswordTooShort =>
      'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل';

  @override
  String get errorLoginFailed => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get errorRegisterFailed =>
      'خطأ أثناء التسجيل. ربما يكون هذا البريد الإلكتروني مستخدمًا بالفعل.';

  @override
  String get forgotPasswordAppBarTitle => 'نسيت كلمة المرور';

  @override
  String get resetPasswordStepTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get newPasswordStepTitle => 'كلمة مرور جديدة';

  @override
  String get resetEmailPrompt =>
      'أدخل بريدك الإلكتروني لتلقي رمز إعادة التعيين';

  @override
  String get resetCodePrompt =>
      'أدخل الرمز المستلم عبر البريد الإلكتروني وكلمة المرور الجديدة';

  @override
  String get fieldResetCode => 'الرمز المستلم عبر البريد الإلكتروني';

  @override
  String get fieldNewPassword => 'كلمة مرور جديدة';

  @override
  String get fieldConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get sendCodeButton => 'إرسال الرمز';

  @override
  String get resetPasswordButton => 'إعادة تعيين كلمة المرور';

  @override
  String get resendCodeLink => 'إعادة إرسال الرمز';

  @override
  String get errorEmailRequired => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get errorPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get infoCodeSent => 'تم إرسال رمز إعادة التعيين إلى بريدك الإلكتروني';

  @override
  String get errorSendCodeFailed =>
      'تعذر إرسال الرمز. تحقق من صحة البريد الإلكتروني.';

  @override
  String get errorResetCodeInvalid =>
      'الرمز غير صالح أو منتهي الصلاحية. يرجى طلب رمز جديد.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSubtitle => 'الحساب والمظهر';

  @override
  String get saveSettingsButton => 'حفظ';

  @override
  String get savedButton => 'تم الحفظ!';

  @override
  String get settingsSavedSnack => 'تم حفظ الإعدادات!';

  @override
  String get myAccountSection => 'حسابي';

  @override
  String get emailNotEditable => 'البريد الإلكتروني (غير قابل للتعديل)';

  @override
  String get localOnlyNotice => '* يتم تحديث الاسم الأول والعائلي محليًا فقط.';

  @override
  String get changePasswordSection => 'تغيير كلمة المرور';

  @override
  String get fieldCurrentPassword => 'كلمة المرور الحالية';

  @override
  String get updatePasswordButton => 'تحديث كلمة المرور';

  @override
  String get passwordUpdatedSuccess => 'تم تحديث كلمة المرور بنجاح';

  @override
  String get currentPasswordIncorrect => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get appearanceSection => 'المظهر';

  @override
  String get themeLabel => 'مظهر الواجهة';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeAppliesNotice => 'يتم تطبيق المظهر فورًا على التطبيق بأكمله.';

  @override
  String get languageSection => 'اللغة';

  @override
  String get languageLabel => 'لغة التطبيق';

  @override
  String get languageFrench => 'الفرنسية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get securitySection => 'الأمان';

  @override
  String get accountSecure => 'حساب آمن';

  @override
  String get jwtActive => 'مصادقة JWT نشطة';

  @override
  String get activeStatus => 'نشط';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get logoutDialogTitle => 'تسجيل الخروج';

  @override
  String get logoutDialogContent => 'هل تريد فعلاً تسجيل الخروج؟';

  @override
  String get comingSoonSection => 'ميزات قادمة';

  @override
  String get comingSoonGoogle => 'تسجيل الدخول عبر جوجل (يتطلب Firebase)';

  @override
  String get comingSoonPushNotif => 'الإشعارات الفورية';

  @override
  String get comingSoonEmailChange => 'تغيير البريد الإلكتروني';

  @override
  String get comingSoonExport => 'تصدير البيانات الشخصية';

  @override
  String dashboardGreeting(String name) {
    return 'مرحبًا، $name 👋';
  }

  @override
  String get dashboardTitle => 'لوحة التحكم';

  @override
  String get newProjectButton => 'مشروع جديد';

  @override
  String get memberViewBadge => 'عرض العضو';

  @override
  String get kpiActiveProjects => 'المشاريع النشطة';

  @override
  String get kpiCompletionRate => 'نسبة الإنجاز';

  @override
  String get kpiCompletedTasks => 'المهام المنجزة';

  @override
  String get kpiLoggedHours => 'الساعات المسجلة';

  @override
  String get projectsPortfolioTitle => 'محفظة المشاريع';

  @override
  String get noProjects => 'لا يوجد مشروع';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusPlanning => 'تخطيط';

  @override
  String get statusPaused => 'متوقف';

  @override
  String get statusCompleted => 'منتهٍ';

  @override
  String activeCount(int count) {
    return 'نشط ($count)';
  }

  @override
  String planningCount(int count) {
    return 'تخطيط ($count)';
  }

  @override
  String get teamLoadTitle => 'عبء عمل الفريق';

  @override
  String get noTeamLoadData => 'لا توجد بيانات عبء عمل متاحة';

  @override
  String get alertsTitle => 'التنبيهات';

  @override
  String get noAlerts => 'لا توجد تنبيهات حاليًا';

  @override
  String taskOverdue(String title) {
    return '$title متأخرة';
  }

  @override
  String get newProjectDialogTitle => 'مشروع جديد';

  @override
  String get fieldProjectName => 'اسم المشروع';

  @override
  String get fieldProjectKey => 'الرمز (مثال: PROJ1)';

  @override
  String get fieldDescription => 'الوصف';

  @override
  String get fieldBudget => 'الميزانية (€)';

  @override
  String get fieldHourlyRate => 'السعر بالساعة (€/س)';

  @override
  String get createProjectButton => 'إنشاء المشروع';

  @override
  String get projectCreatedSuccess => 'تم إنشاء المشروع بنجاح!';

  @override
  String errorGeneric(String error) {
    return 'خطأ: $error';
  }

  @override
  String get myTasksTitle => 'مهامي';

  @override
  String tasksAssignedCount(int count) {
    return '$count مهمة مسندة';
  }

  @override
  String get filterAll => 'الكل';

  @override
  String get filterInProgress => 'قيد التنفيذ';

  @override
  String get filterTodo => 'للقيام به';

  @override
  String get filterDone => 'منجزة';

  @override
  String get newTaskButton => 'مهمة جديدة';

  @override
  String get createTaskButton => 'إنشاء مهمة';

  @override
  String get noTasksFound => 'لم يتم العثور على أي مهمة';

  @override
  String get sectionInReview => 'قيد المراجعة';

  @override
  String get sectionBacklog => 'قائمة الانتظار';

  @override
  String get statusDone => 'منجزة';

  @override
  String get statusInProgressLabel => 'قيد التنفيذ';

  @override
  String get statusInReview => 'قيد المراجعة';

  @override
  String get statusTodo => 'للقيام به';

  @override
  String get statusBacklog => 'قائمة الانتظار';

  @override
  String get statusCancelled => 'ملغاة';

  @override
  String statusUpdatedSnack(String status) {
    return 'تم تحديث الحالة: $status';
  }

  @override
  String get changeStatusTitle => 'تغيير الحالة';

  @override
  String get editMenuItem => 'تعديل';

  @override
  String get overdueChip => 'متأخرة';

  @override
  String get newTaskDialogTitle => 'مهمة جديدة';

  @override
  String get editTaskDialogTitle => 'تعديل المهمة';

  @override
  String get fieldTitle => 'العنوان';

  @override
  String get fieldProject => 'المشروع';

  @override
  String get fieldPriority => 'الأولوية';

  @override
  String get selectProjectHint => 'اختر مشروعًا';

  @override
  String get taskCreatedSnack => 'تم إنشاء المهمة!';

  @override
  String get taskEditedSnack => 'تم التعديل!';
}
