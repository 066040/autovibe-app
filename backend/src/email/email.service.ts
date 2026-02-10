import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);

  async sendPasswordResetCode(email: string, code: string) {
    // Şimdilik gerçek mail yok: console'a basıyoruz.
    // Sonra SMTP/SendGrid gelince burayı değiştireceğiz.
    this.logger.log(`[MOCK EMAIL] Password reset code -> ${email}: ${code}`);
  }
async sendEmailVerificationCode(email: string, code: string) {
  this.logger.log(`[MOCK EMAIL] Email verify code -> ${email}: ${code}`);
}

}
