import { Module } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ReactionsController } from './reactions.controller';
import { ReactionsService } from './reactions.service';

@Module({
  controllers: [ReactionsController],
  providers: [ReactionsService, PrismaService],
})
export class ReactionsModule {}
