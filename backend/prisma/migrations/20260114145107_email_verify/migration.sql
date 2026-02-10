-- AlterTable
ALTER TABLE "User" ADD COLUMN     "emailVerified" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "EmailVerifyCode" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "used" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EmailVerifyCode_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "EmailVerifyCode_email_idx" ON "EmailVerifyCode"("email");

-- CreateIndex
CREATE INDEX "EmailVerifyCode_email_code_idx" ON "EmailVerifyCode"("email", "code");

-- CreateIndex
CREATE INDEX "EmailVerifyCode_expiresAt_idx" ON "EmailVerifyCode"("expiresAt");

-- CreateIndex
CREATE INDEX "EmailVerifyCode_createdAt_idx" ON "EmailVerifyCode"("createdAt");
