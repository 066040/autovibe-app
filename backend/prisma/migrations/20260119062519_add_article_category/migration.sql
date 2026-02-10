-- AlterTable
ALTER TABLE "Article" ADD COLUMN     "category" TEXT NOT NULL DEFAULT 'Öne Çıkanlar';

-- CreateIndex
CREATE INDEX "Article_category_idx" ON "Article"("category");
