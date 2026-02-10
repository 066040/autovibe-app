import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';

import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

import { RequestPasswordResetDto } from './dto/request-password-reset.dto';
import { VerifyPasswordResetDto } from './dto/verify-password-reset.dto';
import { ConfirmPasswordResetDto } from './dto/confirm-password-reset.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  // --------------------
  // REGISTER / LOGIN
  // --------------------

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  // --------------------
  // PASSWORD RESET
  // --------------------

  // Email gir → kod üret + mail at (mock)
  @Post('password-reset/request')
  async requestPasswordReset(@Body() dto: RequestPasswordResetDto) {
    await this.auth.requestPasswordReset(dto.email);
    // güvenlik: user var/yok sızdırmıyoruz
    return { ok: true };
  }

  // Kod doğru mu? (ekran geçişi için)
  @Post('password-reset/verify')
  async verifyPasswordReset(@Body() dto: VerifyPasswordResetDto) {
    await this.auth.verifyPasswordResetCode(dto.email, dto.code);
    return { ok: true };
  }

  // Yeni şifre belirle
  @Post('password-reset/confirm')
  async confirmPasswordReset(@Body() dto: ConfirmPasswordResetDto) {
    await this.auth.confirmPasswordReset(dto.email, dto.code, dto.newPassword);
    return { ok: true };
  }

  // --------------------
  // EMAIL VERIFY (NEW)
  // --------------------

  // Email doğrulama kodu iste (resend de buradan)
  @Post('email/verify/request')
  async requestEmailVerify(@Body() body: { email: string }) {
    await this.auth.requestEmailVerifyCode(body.email);
    return { ok: true };
  }

  // Kod onayla → user.emailVerified=true
  @Post('email/verify/confirm')
  async confirmEmailVerify(@Body() body: { email: string; code: string }) {
    await this.auth.confirmEmailVerifyCode(body.email, body.code);
    return { ok: true };
  }
}
