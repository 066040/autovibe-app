import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
    Locale('tr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AutoNews'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AutoNews'**
  String get appTitle;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'All automotive news in one feed.'**
  String get authTagline;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get nameLabel;

  /// No description provided for @loginBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginBtn;

  /// No description provided for @registerBtn.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get registerBtn;

  /// No description provided for @forgotCta.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotCta;

  /// No description provided for @goToRegister.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get goToRegister;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get goToLogin;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @feedLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get feedLoadFailedTitle;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noContentYet.
  ///
  /// In en, this message translates to:
  /// **'No content yet.'**
  String get noContentYet;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendCodeWithSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend ({seconds}s)'**
  String resendCodeWithSeconds(int seconds);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get codeLabel;

  /// No description provided for @codeEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter the code.'**
  String get codeEnter;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmNewPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get invalidEmail;

  /// No description provided for @passwordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordMin;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Try again.'**
  String get networkError;

  /// No description provided for @successLogin.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully.'**
  String get successLogin;

  /// No description provided for @successRegister.
  ///
  /// In en, this message translates to:
  /// **'Account created. Verify your email.'**
  String get successRegister;

  /// No description provided for @successCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to your email.'**
  String get successCodeSent;

  /// No description provided for @successPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get successPasswordReset;

  /// No description provided for @emailVerifiedToast.
  ///
  /// In en, this message translates to:
  /// **'Email verified ✅'**
  String get emailVerifiedToast;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} AutoNews'**
  String copyright(int year);

  /// No description provided for @profileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'AutoNews User'**
  String get profileDefaultName;

  /// No description provided for @profileDefaultBio.
  ///
  /// In en, this message translates to:
  /// **'No bio yet.'**
  String get profileDefaultBio;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get liked;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @noSavedItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved items yet.'**
  String get noSavedItemsYet;

  /// No description provided for @noLikedItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No liked items yet.'**
  String get noLikedItemsYet;

  /// No description provided for @emptySavedDesc.
  ///
  /// In en, this message translates to:
  /// **'Saved articles will appear here.'**
  String get emptySavedDesc;

  /// No description provided for @emptyLikedDesc.
  ///
  /// In en, this message translates to:
  /// **'Liked items will appear here.'**
  String get emptyLikedDesc;

  /// No description provided for @avatarCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Avatar'**
  String get avatarCropTitle;

  /// No description provided for @coverCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Cover'**
  String get coverCropTitle;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @carNewsAccount.
  ///
  /// In en, this message translates to:
  /// **'AutoNews Account'**
  String get carNewsAccount;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Engineer'**
  String get displayNameHint;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutHint.
  ///
  /// In en, this message translates to:
  /// **'Tell something about you'**
  String get aboutHint;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @reader.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get reader;

  /// No description provided for @journalist.
  ///
  /// In en, this message translates to:
  /// **'Journalist'**
  String get journalist;

  /// No description provided for @publisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get publisher;

  /// No description provided for @avatarPath.
  ///
  /// In en, this message translates to:
  /// **'Avatar path'**
  String get avatarPath;

  /// No description provided for @coverPath.
  ///
  /// In en, this message translates to:
  /// **'Cover path'**
  String get coverPath;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @clearPath.
  ///
  /// In en, this message translates to:
  /// **'Clear Path'**
  String get clearPath;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, bio, images and role'**
  String get editProfileSubtitle;

  /// No description provided for @publisherJournalistVerification.
  ///
  /// In en, this message translates to:
  /// **'Journalist/Publisher Verification'**
  String get publisherJournalistVerification;

  /// No description provided for @publisherJournalistVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply and verification steps'**
  String get publisherJournalistVerificationSubtitle;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get chooseAppLanguage;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get notificationsSubtitle;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacySubtitle;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @termsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsSubtitle;

  /// No description provided for @aboutCarNews.
  ///
  /// In en, this message translates to:
  /// **'About AutoNews'**
  String get aboutCarNews;

  /// No description provided for @aboutCarNewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version and app information'**
  String get aboutCarNewsSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get logoutSubtitle;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You are about to sign out.'**
  String get logoutConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
