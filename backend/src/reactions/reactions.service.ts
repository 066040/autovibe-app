import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ReactionsService {
  constructor(private prisma: PrismaService) {}

  private demoEmail = 'demo@autovibe.local';

  private async demoUserId() {
    const u = await this.prisma.user.findUnique({
      where: { email: this.demoEmail },
      select: { id: true },
    });
    if (!u) throw new NotFoundException('Demo user not found. Run prisma db seed.');
    return u.id;
  }

  async toggleLikeByDemo(articleId: string) {
    const userId = await this.demoUserId();

    const a = await this.prisma.article.findUnique({
      where: { id: articleId },
      select: { id: true },
    });
    if (!a) throw new NotFoundException('Article not found');

    const exists = await this.prisma.like.findUnique({
      where: { userId_articleId: { userId, articleId } },
      select: { id: true },
    });

    let liked: boolean;
    if (exists) {
      await this.prisma.like.delete({
        where: { userId_articleId: { userId, articleId } },
      });
      liked = false;
    } else {
      await this.prisma.like.create({ data: { userId, articleId } });
      liked = true;
    }

    const likesCount = await this.prisma.like.count({ where: { articleId } });
    return { liked, likesCount };
  }

  async toggleSavedByDemo(articleId: string) {
    const userId = await this.demoUserId();

    const a = await this.prisma.article.findUnique({
      where: { id: articleId },
      select: { id: true },
    });
    if (!a) throw new NotFoundException('Article not found');

    const exists = await this.prisma.saved.findUnique({
      where: { userId_articleId: { userId, articleId } },
      select: { id: true },
    });

    let saved: boolean;
    if (exists) {
      await this.prisma.saved.delete({
        where: { userId_articleId: { userId, articleId } },
      });
      saved = false;
    } else {
      await this.prisma.saved.create({ data: { userId, articleId } });
      saved = true;
    }

    return { saved };
  }

  async getMyLikesByDemo() {
    const userId = await this.demoUserId();
    const rows = await this.prisma.like.findMany({
      where: { userId },
      select: { articleId: true },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => r.articleId);
  }

  async getMySavedByDemo() {
    const userId = await this.demoUserId();
    const rows = await this.prisma.saved.findMany({
      where: { userId },
      select: { articleId: true },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => r.articleId);
  }
}
