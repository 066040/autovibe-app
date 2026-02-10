import { Controller, Post, Get, Query } from '@nestjs/common';
import { RssService } from './rss.service';
import { PrismaService } from '../prisma/prisma.service';

@Controller('rss')
export class RssController {
  constructor(
    private readonly rssService: RssService,
    private readonly prisma: PrismaService,
  ) {}

  @Post('fetch')
  fetchRss() {
    return this.rssService.fetchAllSources();
  }

  @Get('articles')
  async listArticles(@Query('limit') limit?: string) {
    const take = Math.min(parseInt(limit || '30', 10), 200);

    return this.prisma.article.findMany({
      take,
      orderBy: { createdAt: 'desc' },
      include: { source: true },
    });
  }

  // ✅ imageUrl null olanları sonradan doldur
  @Post('fill-images')
  fillImages(@Query('limit') limit?: string) {
    const take = parseInt(limit || '50', 10);
    return this.rssService.fillMissingImages(take);
  }
}
