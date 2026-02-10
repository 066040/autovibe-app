import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import Parser from 'rss-parser';
import * as cheerio from 'cheerio';
import { Cron } from '@nestjs/schedule';

type FetchResult =
  | { source: string; inserted: number; skipped: number }
  | { source: string; error: true; message: string };

function sanitizeXml(xml: string) {
  // kaçırılmamış '&' => '&amp;'
  return xml.replace(/&(?!(amp|lt|gt|quot|apos|#\d+|#x[0-9A-Fa-f]+);)/g, '&amp;');
}

@Injectable()
export class RssService {
  private readonly logger = new Logger(RssService.name);

  private parser = new Parser({
    timeout: 20000,
  });

  constructor(private prisma: PrismaService) {}

  private async fetchText(url: string, accept: string) {
    const resp = await fetch(url, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36',
        Accept: accept,
        'Accept-Language': 'en-US,en;q=0.9,tr;q=0.8',
      },
    });

    if (!resp.ok) throw new Error(`Status code ${resp.status}`);
    return resp.text();
  }

  private async fetchXml(url: string) {
    const xml = await this.fetchText(
      url,
      'application/rss+xml, application/xml;q=0.9, */*;q=0.8',
    );
    return sanitizeXml(xml);
  }

  private async fetchOgImage(pageUrl: string): Promise<string | null> {
    try {
      const html = await this.fetchText(
        pageUrl,
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      );

      const $ = cheerio.load(html);
      const og =
        $('meta[property="og:image"]').attr('content') ||
        $('meta[name="og:image"]').attr('content') ||
        $('meta[property="twitter:image"]').attr('content') ||
        $('meta[name="twitter:image"]').attr('content') ||
        null;

      return og?.trim() || null;
    } catch {
      return null;
    }
  }

  async fetchAllSources() {
    const sources = await this.prisma.source.findMany({
      where: { isActive: true },
    });

    const results: FetchResult[] = [];

    for (const source of sources) {
      try {
        const xml = await this.fetchXml(source.url);
        const feed: any = await this.parser.parseString(xml);

        let inserted = 0;
        let skipped = 0;

        for (const item of (feed.items || []).slice(0, 50)) {
          const url = item.link?.trim();
          const title = item.title?.trim();

          if (!url || !title) {
            skipped++;
            continue;
          }

          const exists = await this.prisma.article.findFirst({
            where: { url },
            select: { id: true },
          });

          if (exists) {
            skipped++;
            continue;
          }

          const summary =
            (item.contentSnippet as string) ??
            (item.summary as string) ??
            (item.content as string) ??
            (item.description as string) ??
            null;

          const publishedAtRaw =
            (item.isoDate as string) ??
            (item.pubDate as string) ??
            null;

          const publishedAt = publishedAtRaw ? new Date(publishedAtRaw) : null;

          // RSS'ten image bul
          let imageUrl =
            (item.enclosure as any)?.url ??
            (item['media:content'] as any)?.url ??
            (item['media:thumbnail'] as any)?.url ??
            null;

          // RSS'te yoksa OG image çek

          await this.prisma.article.create({
            data: {
              url,
              title,
              summary,
              imageUrl,
              publishedAt,

              // ✅ Article -> Source relation zorunlu olduğu için:
              source: { connect: { id: source.id } },
            } as any,
          });

          inserted++;
        }

        results.push({ source: source.name, inserted, skipped });
      } catch (err: any) {
        this.logger.error(`RSS error (${source.name})`, err);
        results.push({
          source: source.name,
          error: true,
          message: err?.message || String(err),
        });
      }
    }

    return results;
  }
    // ✅ Cron: her 10 dakikada bir RSS çek
  @Cron('*/10 * * * *')
  async cronFetch() {
    await this.fetchAllSources();
  }

  // ✅ Cron: her 15 dakikada bir eksik görselleri doldur
  @Cron('*/15 * * * *')
  async cronFillImages() {
    await this.fillMissingImages(30);
  }

  // ✅ Sonradan imageUrl null olanları topluca doldur
  async fillMissingImages(limit = 50) {
    const take = Math.min(Math.max(limit, 1), 200);

    const articles = await this.prisma.article.findMany({
      where: { imageUrl: null },
      take,
      orderBy: { createdAt: 'desc' },
      select: { id: true, url: true, title: true },
    });

    let filled = 0;
    let skipped = 0;

    for (const a of articles) {
      const img = await this.fetchOgImage(a.url);
      if (!img) {
        skipped++;
        continue;
      }

      await this.prisma.article.update({
        where: { id: a.id },
        data: { imageUrl: img },
      });

      filled++;
    }

    return { checked: articles.length, filled, skipped };
  }
}
