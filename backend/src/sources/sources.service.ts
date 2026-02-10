import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

// Node 18+ global fetch var. Eğer sende yoksa söyle, node-fetch ekleriz.
type DiscoveredFeed = { title?: string; url: string };

@Injectable()
export class SourcesService {
  constructor(private readonly prisma: PrismaService) {}

  async list() {
    return this.prisma.source.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        _count: { select: { articles: true } },
      },
    });
  }

  async create(body: { name: string; url: string; type?: string }) {
    const name = (body?.name ?? '').trim();
    const url = (body?.url ?? '').trim();
    const type = (body?.type ?? 'rss').trim();

    if (!name) throw new BadRequestException('name is required');
    if (!url) throw new BadRequestException('url is required');

    return this.prisma.source.create({
      data: {
        name,
        url,
        type,
        isActive: true,
      },
    });
  }

  async setActive(id: string, isActive: boolean) {
    return this.prisma.source.update({
      where: { id },
      data: { isActive: !!isActive },
    });
  }

  // ✅ YENİ: PATCH /sources/:id  (publisherId bağlamak dahil)
  async update(
    id: string,
    data: {
      name?: string;
      url?: string;
      type?: string;
      isActive?: boolean;
      publisherId?: string | null;
    },
  ) {
    if (!id) throw new BadRequestException('id is required');

    return this.prisma.source.update({
      where: { id },
      data: {
        ...(data.name !== undefined ? { name: data.name } : {}),
        ...(data.url !== undefined ? { url: data.url } : {}),
        ...(data.type !== undefined ? { type: data.type } : {}),
        ...(data.isActive !== undefined ? { isActive: data.isActive } : {}),
        ...(data.publisherId !== undefined ? { publisherId: data.publisherId } : {}),
      },
    });
  }

  /**
   * ✅ POST /sources/discover
   * Verilen website için RSS feed keşfeder ve Source olarak ekler.
   * Basit yöntem:
   *  - website/rss, website/feed, website/feed.xml gibi yaygın url'leri dener
   *  - ana sayfayı çekip <link rel="alternate" type="application/rss+xml"> arar
   */
  async discoverAndCreate(website: string) {
    const site = this.normalizeWebsite(website);
    if (!site) throw new BadRequestException('website is required');

    const discovered = await this.discoverFeeds(site);

    if (discovered.length === 0) {
      return {
        ok: false,
        website: site,
        created: 0,
        feeds: [],
        message: 'No feeds discovered',
      };
    }

    // DB’ye ekle (aynı url varsa createMany skipDuplicates işe yarar)
    const toCreate = discovered.map((f) => ({
      name: f.title || this.prettyHost(site),
      type: 'rss',
      url: f.url,
      isActive: true,
    }));

    const res = await this.prisma.source.createMany({
      data: toCreate,
      skipDuplicates: true,
    });

    return {
      ok: true,
      website: site,
      created: res.count,
      feeds: discovered,
    };
  }

  // --------------------
  // Helpers
  // --------------------

  private normalizeWebsite(website: string) {
    let w = (website ?? '').trim();
    if (!w) return '';
    if (!/^https?:\/\//i.test(w)) w = `https://${w}`;
    // trailing slash temizle
    w = w.replace(/\/+$/, '');
    return w;
  }

  private prettyHost(website: string) {
    try {
      const u = new URL(website);
      return u.host;
    } catch {
      return website;
    }
  }

  private async discoverFeeds(website: string): Promise<DiscoveredFeed[]> {
    const results: DiscoveredFeed[] = [];
    const tried = new Set<string>();

    const pushUnique = (url: string, title?: string) => {
      const cleaned = url.trim();
      if (!cleaned) return;
      if (tried.has(cleaned)) return;
      tried.add(cleaned);
      results.push({ url: cleaned, title });
    };

    // 1) Yaygın feed yollarını dene
    const commonPaths = ['/rss', '/rss.xml', '/feed', '/feed.xml', '/atom.xml'];
    for (const p of commonPaths) {
      pushUnique(`${website}${p}`, `${this.prettyHost(website)} (${p})`);
    }

    // 2) Ana sayfadan <link rel="alternate" ...> yakala
    const html = await this.tryFetchText(website);
    if (html) {
      const links = this.extractAlternateFeeds(html, website);
      for (const l of links) pushUnique(l.url, l.title);
    }

    // 3) Gerçekten feed mi kontrol et (hafif doğrulama)
    const verified: DiscoveredFeed[] = [];
    for (const f of results) {
      const ok = await this.looksLikeFeed(f.url);
      if (ok) verified.push(f);
    }

    // Aynı url’leri tekrar temizle
    const uniq = new Map<string, DiscoveredFeed>();
    for (const f of verified) uniq.set(f.url, f);
    return Array.from(uniq.values());
  }

  private extractAlternateFeeds(html: string, baseUrl: string): DiscoveredFeed[] {
    const out: DiscoveredFeed[] = [];

    // Çok basit regex (HTML parser istemiyoruz)
    const linkTagRegex = /<link\s+[^>]*>/gi;
    const hrefRegex = /href\s*=\s*["']([^"']+)["']/i;
    const relRegex = /rel\s*=\s*["']([^"']+)["']/i;
    const typeRegex = /type\s*=\s*["']([^"']+)["']/i;
    const titleRegex = /title\s*=\s*["']([^"']+)["']/i;

    const tags = html.match(linkTagRegex) ?? [];
    for (const tag of tags) {
      const rel = (tag.match(relRegex)?.[1] ?? '').toLowerCase();
      const type = (tag.match(typeRegex)?.[1] ?? '').toLowerCase();

      if (!rel.includes('alternate')) continue;
      if (!(type.includes('rss') || type.includes('atom') || type.includes('xml'))) continue;

      const href = tag.match(hrefRegex)?.[1];
      if (!href) continue;

      const title = tag.match(titleRegex)?.[1];

      try {
        const abs = new URL(href, baseUrl).toString();
        out.push({ url: abs, title });
      } catch {
        // ignore
      }
    }

    return out;
  }

  private async looksLikeFeed(url: string) {
    const txt = await this.tryFetchText(url);
    if (!txt) return false;

    const head = txt.slice(0, 2000).toLowerCase();
    // RSS/Atom işaretleri
    if (head.includes('<rss')) return true;
    if (head.includes('<feed')) return true; // atom
    if (head.includes('<rdf:rdf')) return true;
    return false;
  }

  private async tryFetchText(url: string) {
    try {
      const res = await fetch(url, {
        method: 'GET',
        redirect: 'follow',
        headers: {
          'User-Agent': 'CarNewsBot/1.0 (+local-dev)',
          Accept: 'text/html,application/rss+xml,application/atom+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      });

      if (!res.ok) return '';
      const ct = res.headers.get('content-type')?.toLowerCase() ?? '';
      // html veya xml geliyorsa okuyalım
      if (!(ct.includes('html') || ct.includes('xml') || ct.includes('rss') || ct.includes('atom') || ct.includes('text'))) {
        // yine de bazen feed yanlış content-type döner; okuyup bakmak faydalı
      }
      return await res.text();
    } catch {
      return '';
    }
  }
}
