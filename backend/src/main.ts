import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
	app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  const port = process.env.PORT ?? 3000;

  // 🔥 KRİTİK SATIR
  await app.listen(port, '0.0.0.0');

  console.log(`🚀 Backend running on http://0.0.0.0:${port}`);
}
bootstrap();
