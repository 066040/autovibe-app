import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    // 1. Veritabanı bağlantı havuzunu oluşturuyoruz
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    
    // 2. Prisma'nın istediği o 'adapter' nesnesini hazırlıyoruz
    const adapter = new PrismaPg(pool);

    // 3. PrismaClient'a (super) bu adapter'ı veriyoruz
    // TypeScript kızmasın diye 'as any' ile geçiyoruz
    super({
      adapter,
      log: ['query', 'info', 'warn', 'error'],
    } as any);
  }

  async onModuleInit() {
    // Artık 'client' hatası vermeyecek çünkü yukarıda adapter'ı verdik
    await this.$connect();
    console.log('🚀 Prisma 7 Adapter üzerinden bağlandı!');
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}