import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ArticlesService {
  constructor(private prisma: PrismaService) {}

  /**
   * Feed/Discover listesi için:
   * - publishedAt desc, id desc
   * - cursor pagination (id)
   */
  async list(opts: { cursor?: string; limit: number }) {
    const limit = Math.min(Math.max(opts.limit ?? 20, 1), 50);
    const cursor = opts.cursor;

    const rows = await this.prisma.article.findMany({
      orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      select: {
        id: true,
        title: true,
        url: true,
        summary: true,
        imageUrl: true,
        publishedAt: true,
        createdAt: true,
        commentsCount: true,

        // curl çıktındaki source objesi için
        source: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    const hasMore = rows.length > limit;
    const data = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore ? data[data.length - 1].id : null;

    return { data, nextCursor };
  }

  /**
   * Article detail ekranı için
   */
  async getOne(articleId: string) {
    const a = await this.prisma.article.findUnique({
      where: { id: articleId },
      select: {
        id: true,
        title: true,
        url: true,
        summary: true,
        imageUrl: true,
        publishedAt: true,
        createdAt: true,
        commentsCount: true,
        source: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    if (!a) throw new NotFoundException('Article not found');
    return a;
  }
}
