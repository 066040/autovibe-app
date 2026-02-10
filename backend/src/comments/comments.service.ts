import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCommentDto } from './dto/create_comment.dto';
import * as bcrypt from 'bcrypt';

type ListOpts = { cursor?: string; limit: number };

@Injectable()
export class CommentsService {
  constructor(private prisma: PrismaService) {}

  // auth yokken: tek bir demo user ile çalışacağız
  async getOrCreateDemoUser() {
    const email = 'demo@carnews.local';

    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) return existing;

    const passwordHash = await bcrypt.hash('demo123456', 10);

    return this.prisma.user.create({
      data: {
        name: 'Demo User',
        email,
        passwordHash,
      },
    });
  }

  async listByArticle(articleId: string, opts: ListOpts) {
    const { cursor, limit } = opts;

    const rows = await this.prisma.comment.findMany({
      where: {
        articleId,
        parentId: null,
        status: { in: ['VISIBLE', 'PENDING'] as any },
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: {
        user: { select: { id: true, name: true } },
        replies: {
          where: { status: { in: ['VISIBLE', 'PENDING'] as any } },
          orderBy: [{ createdAt: 'asc' }],
          take: 50,
          include: { user: { select: { id: true, name: true } } },
        },
      },
    });

    // ✅ liked alanını (demo user’a göre) ekle
    const demoUser = await this.getOrCreateDemoUser();

    const ids: string[] = [];
    for (const p of rows as any[]) {
      ids.push(p.id);
      for (const r of (p.replies ?? []) as any[]) ids.push(r.id);
    }

    const likedRows =
      ids.length === 0
        ? []
        : await this.prisma.commentLike.findMany({
            where: { userId: demoUser.id, commentId: { in: ids } },
            select: { commentId: true },
          });

    const likedSet = new Set(likedRows.map((x) => x.commentId));

    const rowsWithLiked = (rows as any[]).map((p) => ({
      ...p,
      liked: likedSet.has(p.id),
      replies: (p.replies ?? []).map((r: any) => ({
        ...r,
        liked: likedSet.has(r.id),
      })),
    }));

    const hasMore = rowsWithLiked.length > limit;
    const data = hasMore ? rowsWithLiked.slice(0, limit) : rowsWithLiked;
    const nextCursor = hasMore ? data[data.length - 1].id : null;

    return { data, nextCursor };
  }

  async countByArticle(articleId: string) {
    const count = await this.prisma.comment.count({
      where: {
        articleId,
        status: { in: ['VISIBLE', 'PENDING'] as any },
      },
    });
    return { count };
  }

  async create(articleId: string, dto: CreateCommentDto) {
    const demoUser = await this.getOrCreateDemoUser();

    const exists = await this.prisma.article.findUnique({ where: { id: articleId } });
    if (!exists) throw new NotFoundException('Article not found');

    if (dto.parentId) {
      const parent = await this.prisma.comment.findUnique({
        where: { id: dto.parentId },
        select: { id: true, articleId: true, status: true },
      });
      if (!parent) throw new NotFoundException('Parent comment not found');
      if (parent.articleId !== articleId) throw new ForbiddenException('Parent mismatch');
      if ((parent.status as any) === 'DELETED') throw new ForbiddenException('Parent deleted');
    }

    // ✅ create + recount aynı transaction içinde
    return this.prisma.$transaction(async (tx) => {
      const created = await tx.comment.create({
        data: {
          articleId,
          userId: demoUser.id,
          parentId: dto.parentId ?? null,
          text: dto.text,
          status: 'VISIBLE' as any,
        },
        include: { user: { select: { id: true, name: true } } },
      });

      const visibleCount = await tx.comment.count({
        where: {
          articleId,
          status: { in: ['VISIBLE', 'PENDING'] as any },
        },
      });

      await tx.article.update({
        where: { id: articleId },
        data: { commentsCount: visibleCount },
      });

      // created objesine liked alanı ekle
      return { ...created, liked: false };
    });
  }

  async softDelete(commentId: string) {
    const demoUser = await this.getOrCreateDemoUser();

    const c = await this.prisma.comment.findUnique({
      where: { id: commentId },
      select: { id: true, userId: true, articleId: true, status: true },
    });
    if (!c) throw new NotFoundException('Comment not found');

    if (c.userId !== demoUser.id) {
      throw new ForbiddenException('Not your comment (demo mode)');
    }

    if ((c.status as any) === 'DELETED') {
      return { ok: true };
    }

    return this.prisma.$transaction(async (tx) => {
      // 1) comment’i soft delete
      await tx.comment.update({
        where: { id: commentId },
        data: { status: 'DELETED' as any, text: '' },
      });

      // 2) parent silinirse reply’ları da soft delete
      await tx.comment.updateMany({
        where: {
          parentId: commentId,
          status: { in: ['VISIBLE', 'PENDING'] as any },
        },
        data: { status: 'DELETED' as any, text: '' },
      });

      // 3) count’u yeniden hesapla
      const visibleCount = await tx.comment.count({
        where: {
          articleId: c.articleId,
          status: { in: ['VISIBLE', 'PENDING'] as any },
        },
      });

      await tx.article.update({
        where: { id: c.articleId },
        data: { commentsCount: visibleCount },
      });

      return { ok: true, commentsCount: visibleCount };
    });
  }

  // --------------------
  // LIKE / UNLIKE
  // --------------------

  async like(commentId: string) {
    const demoUser = await this.getOrCreateDemoUser();

    return this.prisma.$transaction(async (tx) => {
      const c = await tx.comment.findUnique({
        where: { id: commentId },
        select: { id: true, status: true, likesCount: true },
      });
      if (!c) throw new NotFoundException('Comment not found');
      if ((c.status as any) === 'DELETED') throw new ForbiddenException('Comment deleted');

      const existing = await tx.commentLike.findUnique({
        where: { commentId_userId: { commentId, userId: demoUser.id } },
        select: { id: true },
      });

      if (existing) {
        return { ok: true, liked: true, likesCount: c.likesCount };
      }

      await tx.commentLike.create({
        data: { commentId, userId: demoUser.id },
      });

      const updated = await tx.comment.update({
        where: { id: commentId },
        data: { likesCount: { increment: 1 } },
        select: { likesCount: true },
      });

      return { ok: true, liked: true, likesCount: updated.likesCount };
    });
  }

  async unlike(commentId: string) {
    const demoUser = await this.getOrCreateDemoUser();

    return this.prisma.$transaction(async (tx) => {
      const c = await tx.comment.findUnique({
        where: { id: commentId },
        select: { id: true, likesCount: true },
      });
      if (!c) throw new NotFoundException('Comment not found');

      const del = await tx.commentLike.deleteMany({
        where: { commentId, userId: demoUser.id },
      });

      if (del.count > 0) {
        const updated = await tx.comment.update({
          where: { id: commentId },
          data: { likesCount: { decrement: 1 } },
          select: { likesCount: true },
        });

        const safe = updated.likesCount < 0 ? 0 : updated.likesCount;
        if (safe !== updated.likesCount) {
          await tx.comment.update({ where: { id: commentId }, data: { likesCount: 0 } });
        }

        return { ok: true, liked: false, likesCount: safe };
      }

      return { ok: true, liked: false, likesCount: c.likesCount };
    });
  }
}
