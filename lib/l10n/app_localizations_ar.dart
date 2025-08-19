// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'محفظة ستاك';

  @override
  String get walletsTab => 'المحافظ';

  @override
  String get exchangeTab => 'التبادل';

  @override
  String get buyTab => 'شراء';

  @override
  String get settingsTab => 'الإعدادات';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get addressBookTitle => 'دفتر العناوين';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get walletViewTitle => 'المحفظة';

  @override
  String get sendTitle => 'إرسال';

  @override
  String get sendFromTitle => 'إرسال من';

  @override
  String get receiveTitle => 'استقبال';

  @override
  String get swapTitle => 'تبديل';

  @override
  String get tokensTitle => 'الرموز المميزة';

  @override
  String get saveButton => 'حفظ';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get continueButton => 'متابعة';

  @override
  String get editButton => 'تعديل';

  @override
  String get deleteButton => 'حذف';

  @override
  String get nextButton => 'التالي';

  @override
  String get closeButton => 'إغلاق';

  @override
  String get okButton => 'موافق';

  @override
  String get yesButton => 'نعم';

  @override
  String get noButton => 'لا';

  @override
  String get copyButton => 'نسخ';

  @override
  String get sendButton => 'إرسال';

  @override
  String get receiveButton => 'استقبال';

  @override
  String get addButton => 'إضافة';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get amountLabel => 'المبلغ';

  @override
  String get addressLabel => 'العنوان';

  @override
  String get feeLabel => 'الرسوم';

  @override
  String get noteLabel => 'ملاحظة';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get searchHint => 'البحث...';

  @override
  String get enterPasswordHint => 'أدخل كلمة المرور';

  @override
  String get enterAmountHint => '0.00';

  @override
  String get optionalHint => 'اختياري';

  @override
  String get requiredFieldError => 'هذا الحقل مطلوب';

  @override
  String get invalidEmailError => 'يرجى إدخال عنوان بريد إلكتروني صحيح';

  @override
  String get invalidAddressError => 'يرجى إدخال عنوان صحيح';

  @override
  String get insufficientFundsError => 'أموال غير كافية';

  @override
  String get networkError => 'فشل في الاتصال بالشبكة';

  @override
  String get transactionFailed => 'فشلت المعاملة';

  @override
  String get loadingStatus => 'جاري التحميل...';

  @override
  String get processingStatus => 'جاري المعالجة...';

  @override
  String get syncingStatus => 'جاري المزامنة...';

  @override
  String get completedStatus => 'مكتمل';

  @override
  String get pendingStatus => 'معلق';

  @override
  String get confirmedStatus => 'مؤكد';

  @override
  String get wallets => 'المحافظ';

  @override
  String get settings => 'الإعدادات';

  @override
  String get exchange => 'التبادل';

  @override
  String get buy => 'شراء';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get contractDetails => 'تفاصيل العقد';

  @override
  String get contractAddress => 'عنوان العقد';

  @override
  String get symbolLabel => 'الرمز';

  @override
  String get typeLabel => 'النوع';

  @override
  String get decimalsLabel => 'الكسور العشرية';

  @override
  String get name => 'الاسم';

  @override
  String get youCanChangeItLaterInSettings => 'يمكنك تغييره لاحقاً في الإعدادات';

  @override
  String get easyCrypto => 'عملة رقمية سهلة';

  @override
  String get recommended => 'موصى به';

  @override
  String get incognito => 'مجهول';

  @override
  String get privacyConscious => 'واعي للخصوصية';

  @override
  String get welcomeTagline => 'محفظة متعددة العملات ومفتوحة المصدر للجميع';

  @override
  String get getStartedButton => 'ابدأ';

  @override
  String createNewWalletButton(String appPrefix) {
    return 'إنشاء $appPrefix جديد';
  }

  @override
  String restoreFromBackupButton(String appPrefix) {
    return 'استعادة من نسخة احتياطية $appPrefix';
  }

  @override
  String privacyAgreementText(String appName) {
    return 'باستخدام $appName، فإنك توافق على ';
  }

  @override
  String get termsOfServiceLinkText => 'شروط الخدمة';

  @override
  String get privacyAgreementConjunction => ' و ';

  @override
  String get privacyPolicyLinkText => 'سياسة الخصوصية';

  @override
  String get enterPinTitle => 'أدخل رقم التعريف الشخصي';

  @override
  String get useBiometricsButton => 'استخدم القياسات الحيوية';

  @override
  String get loadingWalletsMessage => 'جاري تحميل المحافظ...';

  @override
  String get incorrectPinTryAgainError => 'رقم التعريف الشخصي غير صحيح. يرجى المحاولة مرة أخرى';

  @override
  String incorrectPinThrottleError(String waitTime) {
    return 'تم إدخال رقم التعريف الشخصي بشكل خاطئ مرات كثيرة. يرجى الانتظار $waitTime';
  }
}
