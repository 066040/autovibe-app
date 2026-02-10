// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'AutoNews';

  @override
  String get appTitle => 'AutoNews';

  @override
  String get authTagline => 'Otomobil dünyası, tek akışta.';

  @override
  String get loginTitle => 'Giriş Yap';

  @override
  String get registerTitle => 'Kayıt Ol';

  @override
  String get verifyEmailTitle => 'E-postanı Doğrula';

  @override
  String get forgotTitle => 'Şifremi Unuttum';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get nameLabel => 'Ad Soyad';

  @override
  String get loginBtn => 'Giriş';

  @override
  String get registerBtn => 'Hesap Oluştur';

  @override
  String get forgotCta => 'Şifreni mi unuttun?';

  @override
  String get goToRegister => 'Kayıt ol';

  @override
  String get goToLogin => 'Giriş yap';

  @override
  String get noAccount => 'Hesabın yok mu?';

  @override
  String get haveAccount => 'Zaten hesabın var mı?';

  @override
  String get refresh => 'Yenile';

  @override
  String get feedLoadFailedTitle => 'Yüklenemedi';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get noContentYet => 'Henüz içerik yok.';

  @override
  String get sendCode => 'Kod Gönder';

  @override
  String get verify => 'Doğrula';

  @override
  String get resendCode => 'Kodu tekrar gönder';

  @override
  String resendCodeWithSeconds(int seconds) {
    return 'Tekrar gönder (${seconds}s)';
  }

  @override
  String get codeLabel => 'Doğrulama Kodu';

  @override
  String get codeEnter => 'Kodu gir.';

  @override
  String get newPassword => 'Yeni Şifre';

  @override
  String get confirmNewPassword => 'Yeni Şifre (Tekrar)';

  @override
  String get resetPassword => 'Şifreyi Sıfırla';

  @override
  String get or => 'veya';

  @override
  String get requiredField => 'Bu alan zorunlu.';

  @override
  String get invalidEmail => 'Geçerli bir e-posta gir.';

  @override
  String get passwordMin => 'Şifre en az 6 karakter olmalı.';

  @override
  String get passwordMismatch => 'Şifreler eşleşmiyor.';

  @override
  String get networkError => 'Bağlantı hatası. Tekrar dene.';

  @override
  String get successLogin => 'Giriş başarılı.';

  @override
  String get successRegister => 'Kayıt başarılı. E-postanı doğrula.';

  @override
  String get successCodeSent => 'Kod e-postana gönderildi.';

  @override
  String get successPasswordReset => 'Şifren güncellendi.';

  @override
  String get emailVerifiedToast => 'E-posta doğrulandı ✅';

  @override
  String copyright(int year) {
    return '© $year AutoNews';
  }

  @override
  String get profileDefaultName => 'AutoNews Kullanıcısı';

  @override
  String get profileDefaultBio => 'Henüz bio yok.';

  @override
  String get saved => 'Kaydedilenler';

  @override
  String get liked => 'Beğenilenler';

  @override
  String get grid => 'Izgara';

  @override
  String get list => 'Liste';

  @override
  String get noSavedItemsYet => 'Henüz kaydedilen yok.';

  @override
  String get noLikedItemsYet => 'Henüz beğenilen yok.';

  @override
  String get emptySavedDesc => 'Haberleri kaydettiğinde burada görünecek.';

  @override
  String get emptyLikedDesc => 'Beğendiğin içerikler burada görünecek.';

  @override
  String get avatarCropTitle => 'Profil Fotoğrafını Kırp';

  @override
  String get coverCropTitle => 'Kapak Fotoğrafını Kırp';

  @override
  String get profileSaved => 'Profil kaydedildi.';

  @override
  String get editProfileTitle => 'Profili Düzenle';

  @override
  String get save => 'Kaydet';

  @override
  String get carNewsAccount => 'AutoNews Hesabı';

  @override
  String get displayName => 'Görünen Ad';

  @override
  String get displayNameHint => 'Örn: Mühendis';

  @override
  String get required => 'Zorunlu';

  @override
  String get about => 'Hakkında';

  @override
  String get aboutHint => 'Kendinden kısaca bahset';

  @override
  String get website => 'Web sitesi';

  @override
  String get role => 'Rol';

  @override
  String get reader => 'Okuyucu';

  @override
  String get journalist => 'Gazeteci';

  @override
  String get publisher => 'Yayıncı';

  @override
  String get avatarPath => 'Avatar yolu';

  @override
  String get coverPath => 'Kapak yolu';

  @override
  String get saveProfile => 'Profili Kaydet';

  @override
  String get clearPath => 'Yolu Temizle';

  @override
  String get settings => 'Ayarlar';

  @override
  String get account => 'Hesap';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get editProfileSubtitle => 'Ad, bio, görseller ve rol';

  @override
  String get publisherJournalistVerification => 'Gazeteci/Yayıncı Doğrulama';

  @override
  String get publisherJournalistVerificationSubtitle =>
      'Başvuru ve doğrulama işlemleri';

  @override
  String get appSection => 'Uygulama';

  @override
  String get language => 'Dil';

  @override
  String get chooseAppLanguage => 'Uygulama dilini seç';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get notificationsSubtitle => 'Bildirim tercihlerini yönet';

  @override
  String get aboutSection => 'Hakkında';

  @override
  String get privacy => 'Gizlilik';

  @override
  String get privacySubtitle => 'Gizlilik politikası';

  @override
  String get terms => 'Şartlar';

  @override
  String get termsSubtitle => 'Kullanım şartları';

  @override
  String get aboutCarNews => 'AutoNews Hakkında';

  @override
  String get aboutCarNewsSubtitle => 'Sürüm ve uygulama bilgileri';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get logoutSubtitle => 'Hesabından çıkış yap';

  @override
  String get logoutConfirmTitle => 'Çıkış yapılsın mı?';

  @override
  String get logoutConfirmBody => 'Hesabından çıkış yapmak üzeresin.';

  @override
  String get cancel => 'İptal';
}
