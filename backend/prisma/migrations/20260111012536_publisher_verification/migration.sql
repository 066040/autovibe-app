-- AlterTable
ALTER TABLE "Source" ADD COLUMN     "publisherId" TEXT;

-- CreateTable
CREATE TABLE "Publisher" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "verified" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Publisher_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Publisher_domain_key" ON "Publisher"("domain");

-- CreateIndex
CREATE UNIQUE INDEX "Publisher_token_key" ON "Publisher"("token");

-- AddForeignKey
ALTER TABLE "Source" ADD CONSTRAINT "Source_publisherId_fkey" FOREIGN KEY ("publisherId") REFERENCES "Publisher"("id") ON DELETE SET NULL ON UPDATE CASCADE;
