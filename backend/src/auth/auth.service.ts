import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';

import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

import { EmailService } from '../email/email.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly email: EmailService,
  ) {}

  // --------------------
  // Helpers
  // --------------------

  private normalizeEmail(email: string) {
    return (email ?? '').trim().toLowerCase();
  }

  private generateCode6(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  private async signToken(user: { id: string; email: string }) {
    return this.jwt.signAsync({ sub: user.id, email: user.email });
  }

  // --------------------
  // REGISTER / LOGIN
  // --------------------

  async register(dto: RegisterDto) {
    const email = this.normalizeEmail(dto.email);
    if (!email) throw new BadRequestException('Email gerekli.');

    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists) throw new BadRequestException('Bu email zaten kayıtlı.');

    if (!dto.password || dto.password.length < 6) {
      throw new BadRequestException('Şifre en az 6 karakter olmalı.');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        // emailVerified default false (schema)
      },
      select: { id: true, email: true, emailVerified: true },
    });

    // ✅ Kayıt sonrası email doğrulama kodu yolla (mock)
    // Kullanıcı "otomatik login yok" istiyor -> token yine dönüyor olabilir.
    // Sen token döndürmeye devam ediyorsun diye aynen bıraktım.
    await this.requestEmailVerifyCode(email);

    const token = await this.signToken(user);
    return { user, token };
  }

  async login(dto: LoginDto) {
    const email = this.normalizeEmail(dto.email);
    if (!email) throw new BadRequestException('Email gerekli.');

    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw new UnauthorizedException('Email veya şifre hatalı.');

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Email veya şifre hatalı.');

    const token = await this.signToken({ id: user.id, email: user.email });

    return {
      user: {
        id: user.id,
        email: user.email,
        emailVerified: user.emailVerified,
      },
      token,
    };
  }

  // --------------------
  // EMAIL VERIFY (NEW)
  // --------------------

  /**
   * Email doğrulama kodu üretir ve mail atar (mock).
   * Güvenlik: kullanıcı yoksa sessizce return.
   */
  async requestEmailVerifyCode(emailRaw: string) {
    const email = this.normalizeEmail(emailRaw);
    if (!email) return;

    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) return;

    // zaten doğrulanmışsa gerek yok
    if (user.emailVerified) return;

    // önceki açık kodları kapat
    await this.prisma.emailVerifyCode.updateMany({
      where: { email, used: false },
      data: { used: true },
    });

    const code = this.generateCode6();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await this.prisma.emailVerifyCode.create({
      data: { email, code, expiresAt },
    });

    await this.email.sendEmailVerificationCode(email, code);
  }

  /**
   * Kod doğruysa user.emailVerified=true yapar ve kodu used=true yapar.
   */
  async confirmEmailVerifyCode(emailRaw: string, codeRaw: string) {
    const email = this.normalizeEmail(emailRaw);
    const code = (codeRaw ?? '').trim();
    if (!email || !code) {
      throw new BadRequestException('Email ve kod gerekli.');
    }

    const now = new Date();

    const row = await this.prisma.emailVerifyCode.findFirst({
      where: {
        email,
        code,
        used: false,
        expiresAt: { gt: now },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!row) {
      throw new BadRequestException('Kod geçersiz veya süresi dolmuş.');
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { email },
        data: { emailVerified: true },
      }),
      this.prisma.emailVerifyCode.update({
        where: { id: row.id },
        data: { used: true },
      }),
    ]);
  }

  // --------------------
  // PASSWORD RESET (EXISTING)
  // --------------------

  /**
   * Email gir → kod üret → DB’ye yaz → mail at (mock)
   * Güvenlik: user yoksa sessizce return
   */
  async requestPasswordReset(emailRaw: string) {
    const email = this.normalizeEmail(emailRaw);
    if (!email) return;

    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) return;

    await this.prisma.passwordResetCode.updateMany({
      where: { email, used: false },
      data: { used: true },
    });

    const code = this.generateCode6();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await this.prisma.passwordResetCode.create({
      data: { email, code, expiresAt },
    });

    await this.email.sendPasswordResetCode(email, code);
  }

  async verifyPasswordResetCode(emailRaw: string, codeRaw: string) {
    const email = this.normalizeEmail(emailRaw);
    const code = (codeRaw ?? '').trim();
    if (!email || !code) {
      throw new BadRequestException('Email ve kod gerekli.');
    }

    const now = new Date();

    const row = await this.prisma.passwordResetCode.findFirst({
      where: {
        email,
        code,
        used: false,
        expiresAt: { gt: now },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!row) {
      throw new BadRequestException('Kod geçersiz veya süresi dolmuş.');
    }
  }

  async confirmPasswordReset(emailRaw: string, codeRaw: string, newPassword: string) {
    const email = this.normalizeEmail(emailRaw);
    const code = (codeRaw ?? '').trim();

    if (!email || !code) {
      throw new BadRequestException('Email ve kod gerekli.');
    }

    if (!newPassword || newPassword.length < 6) {
      throw new BadRequestException('Şifre en az 6 karakter olmalı.');
    }

    const now = new Date();

    const row = await this.prisma.passwordResetCode.findFirst({
      where: {
        email,
        code,
        used: false,
        expiresAt: { gt: now },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!row) {
      throw new BadRequestException('Kod geçersiz veya süresi dolmuş.');
    }

    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      await this.prisma.passwordResetCode.update({
        where: { id: row.id },
        data: { used: true },
      });
      throw new BadRequestException('Kullanıcı bulunamadı.');
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: user.id },
        data: { passwordHash },
      }),
      this.prisma.passwordResetCode.update({
        where: { id: row.id },
        data: { used: true },
      }),
    ]);
  }
}
