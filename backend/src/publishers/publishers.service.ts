import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PublishersService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Admin/debug için publisher listesini döner.
   * GET /publishers eklediysen controller burayı çağırır.
   */
  async list() {
    return this.prisma.publisher.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * POST /publishers
   * Yeni publisher oluşturur, domain unique ise 409 döner.
   */
  async create(input: { name: string; domain: string }) {
    const name = (input?.name ?? '').trim();
    const domain = (input?.domain ?? '').trim().toLowerCase();

    if (!name || !domain) {
      // İstersen burada BadRequestException da kullanabilirsin
      throw new ConflictException('name and domain are required');
    }

    // basit normalize (http/https yazılırsa kaldır)
    const normalizedDomain = domain.replace(/^https?:\/\//, '').replace(/\/+$/, '');

    // token üretimi (basit/istikrarlı): verify kaydı için DB’ye yazıyoruz
    const token = `carnews-verify=${this.randomHex(32)}`;

    try {
      return await this.prisma.publisher.create({
        data: {
          name,
          domain: normalizedDomain,
          token,
          verified: false,
        },
      });
    } catch (e: any) {
      // Unique constraint -> 409
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        throw new ConflictException('Publisher already exists (domain must be unique).');
      }
      throw e;
    }
  }

  /**
   * POST /publishers/:id/verify
   * Şimdilik: publisher varsa verified=true yapar.
   * (İleride domain doğrulama meta/txt ile gerçek verification ekleriz.)
   */
  async verify(id: string) {
    const publisher = await this.prisma.publisher.findUnique({ where: { id } });
    if (!publisher) throw new NotFoundException('Publisher not found');

    const updated = await this.prisma.publisher.update({
      where: { id },
      data: { verified: true },
    });

    return { ok: true, publisher: updated };
  }

  private randomHex(bytes: number) {
    // Node.js built-in crypto kullanmadan da çalışsın diye basit bir üretim:
    // (istersen crypto.randomBytes ile güçlendiririz)
    const chars = 'abcdef0123456789';
    let out = '';
    for (let i = 0; i < bytes * 2; i++) out += chars[Math.floor(Math.random() * chars.length)];
    return out;
  }
}
