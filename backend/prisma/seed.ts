import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import { Pool } from "pg";
import * as crypto from "crypto";

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  throw new Error("DATABASE_URL is missing. Check backend .env");
}

// ✅ Driver Adapter ile PrismaClient
const pool = new Pool({ connectionString: DATABASE_URL });
const adapter = new PrismaPg(pool);

// PrismaClientOptions sende adapter istiyor → doğru olan bu
const prisma = new PrismaClient({ adapter });

function sha256(text: string) {
  return crypto.createHash("sha256").update(text).digest("hex");
}

async function main() {
  // Demo user
  const demoEmail = "demo@autovibe.local";

  const user = await prisma.user.upsert({
    where: { email: demoEmail },
    update: {},
    create: {
      email: demoEmail,
      passwordHash: sha256("demo123"),
      name: "Demo User",
      emailVerified: true,
    },
  });

  // Publisher + Source
  const pub = await prisma.publisher.upsert({
    where: { domain: "autovibe.local" },
    update: {},
    create: {
      name: "AutoVibe",
      domain: "autovibe.local",
      token: "demo-token-autovibe",
      verified: true,
    },
  });

  const source = await prisma.source.upsert({
    where: { url: "https://autovibe.local/demo" },
    update: { publisherId: pub.id, isActive: true },
    create: {
      name: "AutoVibe Demo",
      type: "demo",
      url: "https://autovibe.local/demo",
      publisherId: pub.id,
      isActive: true,
    },
  });

  // Demo articles
  const a1 = await prisma.article.upsert({
    where: { url: "https://autovibe.local/a/m3-e46" },
    update: {},
    create: {
      sourceId: source.id,
      title: "M3 E46 track day 🔥",
      url: "https://autovibe.local/a/m3-e46",
      summary: "Demo reel/article",
      language: "tr",
      publishedAt: new Date(),
    },
  });

  const a2 = await prisma.article.upsert({
    where: { url: "https://autovibe.local/a/night-drive" },
    update: {},
    create: {
      sourceId: source.id,
      title: "Gece sürüşü • city lights",
      url: "https://autovibe.local/a/night-drive",
      summary: "Demo reel/article",
      language: "tr",
      publishedAt: new Date(),
    },
  });

  const a3 = await prisma.article.upsert({
    where: { url: "https://autovibe.local/a/detailing" },
    update: {},
    create: {
      sourceId: source.id,
      title: "Detaylı yıkama sonrası ✨",
      url: "https://autovibe.local/a/detailing",
      summary: "Demo reel/article",
      language: "tr",
      publishedAt: new Date(),
    },
  });

  console.log("DEMO_EMAIL=", demoEmail);
  console.log("DEMO_USER_ID=", user.id);
  console.log("DEMO_ARTICLE_IDS=", a1.id, a2.id, a3.id);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
