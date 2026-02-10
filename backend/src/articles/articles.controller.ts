import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Controller('articles')
export class ArticlesController {
  constructor(private prisma: PrismaService) {}

  // /articles/by-ids?ids=a,b,c
  @Get('by-ids')
  async byIds(@Query('ids') idsRaw?: string) {
    if (!idsRaw || typeof idsRaw !== 'string') {
      throw new BadRequestException('ids query param is required');
    }

    const ids = idsRaw
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);

    if (ids.length === 0) {
      throw new BadRequestException('ids is empty');
    }

    const items = await this.prisma.article.findMany({
      where: { id: { in: ids } },
      select: {
        id: true,
        title: true,
        url: true,
        imageUrl: true,
        publishedAt: true,
        createdAt: true,
        source: { select: { name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return items;
  }
}
