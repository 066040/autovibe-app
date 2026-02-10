-- 1) VISIBLE + PENDING yorumları say ve Article.commentsCount'u güncelle
UPDATE "Article" a
SET "commentsCount" = sub.cnt
FROM (
  SELECT "articleId", COUNT(*)::int AS cnt
  FROM "Comment"
  WHERE "status" IN ('VISIBLE','PENDING')
  GROUP BY "articleId"
) sub
WHERE a.id = sub."articleId";

-- 2) Yorumu olmayanları 0'a çek (NULL kalmasın)
UPDATE "Article"
SET "commentsCount" = 0
WHERE "commentsCount" IS NULL;

-- 3) Negatifleri sıfırla (geçmişte -4 vs olduysa)
UPDATE "Article"
SET "commentsCount" = 0
WHERE "commentsCount" < 0;
