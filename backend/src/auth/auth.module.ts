import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';

import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

import { PrismaService } from '../prisma/prisma.service';
import { EmailModule } from '../email/email.module';

@Module({
  imports: [
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'dev-secret-change-me',
      signOptions: { expiresIn: '7d' },
    }),
    EmailModule, // 👈 şifre sıfırlama maili için
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    PrismaService,
  ],
  exports: [
    AuthService, // başka modüller ileride kullanabilir
  ],
})
export class AuthModule {}
