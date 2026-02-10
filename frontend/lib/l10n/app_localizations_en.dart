// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AutoNews';

  @override
  String get appTitle => 'AutoNews';

  @override
  String get authTagline => 'All automotive news in one feed.';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get verifyEmailTitle => 'Verify Your Email';

  @override
  String get forgotTitle => 'Forgot Password';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get nameLabel => 'Full Name';

  @override
  String get loginBtn => 'Sign In';

  @override
  String get registerBtn => 'Create';

  @override
  String get forgotCta => 'Forgot your password?';

  @override
  String get goToRegister => 'Create one';

  @override
  String get goToLogin => 'Sign in';

  @override
  String get noAccount => 'Don’t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get refresh => 'Refresh';

  @override
  String get feedLoadFailedTitle => 'Load failed';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noContentYet => 'No content yet.';

  @override
  String get sendCode => 'Send Code';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCodeWithSeconds(int seconds) {
    return 'Resend (${seconds}s)';
  }

  @override
  String get codeLabel => 'Verification Code';

  @override
  String get codeEnter => 'Enter the code.';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get or => 'or';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get invalidEmail => 'Enter a valid email.';

  @override
  String get passwordMin => 'Password must be at least 6 characters.';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get networkError => 'Network error. Try again.';

  @override
  String get successLogin => 'Signed in successfully.';

  @override
  String get successRegister => 'Account created. Verify your email.';

  @override
  String get successCodeSent => 'Code sent to your email.';

  @override
  String get successPasswordReset => 'Password updated.';

  @override
  String get emailVerifiedToast => 'Email verified ✅';

  @override
  String copyright(int year) {
    return '© $year AutoNews';
  }

  @override
  String get profileDefaultName => 'AutoNews User';

  @override
  String get profileDefaultBio => 'No bio yet.';

  @override
  String get saved => 'Saved';

  @override
  String get liked => 'Liked';

  @override
  String get grid => 'Grid';

  @override
  String get list => 'List';

  @override
  String get noSavedItemsYet => 'No saved items yet.';

  @override
  String get noLikedItemsYet => 'No liked items yet.';

  @override
  String get emptySavedDesc => 'Saved articles will appear here.';

  @override
  String get emptyLikedDesc => 'Liked items will appear here.';

  @override
  String get avatarCropTitle => 'Crop Avatar';

  @override
  String get coverCropTitle => 'Crop Cover';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get save => 'Save';

  @override
  String get carNewsAccount => 'AutoNews Account';

  @override
  String get displayName => 'Display Name';

  @override
  String get displayNameHint => 'e.g. Engineer';

  @override
  String get required => 'Required';

  @override
  String get about => 'About';

  @override
  String get aboutHint => 'Tell something about you';

  @override
  String get website => 'Website';

  @override
  String get role => 'Role';

  @override
  String get reader => 'Reader';

  @override
  String get journalist => 'Journalist';

  @override
  String get publisher => 'Publisher';

  @override
  String get avatarPath => 'Avatar path';

  @override
  String get coverPath => 'Cover path';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get clearPath => 'Clear Path';

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileSubtitle => 'Name, bio, images and role';

  @override
  String get publisherJournalistVerification =>
      'Journalist/Publisher Verification';

  @override
  String get publisherJournalistVerificationSubtitle =>
      'Apply and verification steps';

  @override
  String get appSection => 'App';

  @override
  String get language => 'Language';

  @override
  String get chooseAppLanguage => 'Choose app language';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Manage notification preferences';

  @override
  String get aboutSection => 'About';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacySubtitle => 'Privacy policy';

  @override
  String get terms => 'Terms';

  @override
  String get termsSubtitle => 'Terms of service';

  @override
  String get aboutCarNews => 'About AutoNews';

  @override
  String get aboutCarNewsSubtitle => 'Version and app information';

  @override
  String get logout => 'Log out';

  @override
  String get logoutSubtitle => 'Sign out of your account';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody => 'You are about to sign out.';

  @override
  String get cancel => 'Cancel';
}
