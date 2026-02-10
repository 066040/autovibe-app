import { Injectable } from "@nestjs/common";
import { PrismaService } from "../prisma/prisma.service";
import { NewsQueryDto } from "./dto/news-query.dto";

function parseCursor(cursor?: string) {
  if (!cursor) return null;
  const [iso, id] = cursor.split("|");
  if (!iso || !id) return null;
  const d = new Date(iso);
  if (isNaN(d.getTime())) return null;
  return { createdAt: d, id };
}

function makeCursor(createdAt: Date, id: string) {
  return `${createdAt.toISOString()}|${id}`;
}

@Injectable()
export class NewsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(q: NewsQueryDto) {
    const limit = Math.min(Math.max(q.limit ?? 20, 1), 50);
    const cursor = parseCursor(q.cursor);

    const where: any = {};

    // category filter
    if (q.category && q.category.trim() && q.category !== "Öne Çıkanlar") {
      where.category = q.category;
    }

    // search filter
    const search = q.q?.trim();
    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { summary: { contains: search, mode: "insensitive" } },
        { source: { name: { contains: search, mode: "insensitive" } } },
      ];
    }

    // cursor pagination: createdAt desc, id desc
    if (cursor) {
      where.AND = [
        ...(where.AND ?? []),
        {
          OR: [
            { createdAt: { lt: cursor.createdAt } },
            { createdAt: cursor.createdAt, id: { lt: cursor.id } },
          ],
        },
      ];
    }

    const rows = await this.prisma.article.findMany({
      where,
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      take: limit + 1,
      select: {
        id: true,
        title: true,
        summary: true,
        imageUrl: true,
        url: true,
        category: true,
        publishedAt: true,
        createdAt: true,
        source: { select: { name: true, type: true } },
      },
    });

    const hasMore = rows.length > limit;
    const slice = hasMore ? rows.slice(0, limit) : rows;

    const nextCursor = hasMore
      ? makeCursor(slice[slice.length - 1].createdAt, slice[slice.length - 1].id)
      : null;

    // Flutter için “publishedAt null ise createdAt döndür”
    const items = slice.map((a) => ({
      id: a.id,
      title: a.title,
      summary: a.summary ?? "",
      source: a.source?.name ?? "AutoNews",
      category: a.category ?? "Öne Çıkanlar",
      imageUrl: a.imageUrl,
      url: a.url,
      publishedAt: (a.publishedAt ?? a.createdAt).toISOString(),
    }));

    return { items, nextCursor };
  }
}
