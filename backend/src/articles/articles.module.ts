import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ArticlesController } from './articles.controller';

@Module({
  imports: [PrismaModule],
  controllers: [ArticlesController],
})
export class ArticlesModule {}
