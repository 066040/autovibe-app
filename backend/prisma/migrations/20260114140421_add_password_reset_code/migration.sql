-- CreateIndex
CREATE INDEX "PasswordResetCode_email_code_idx" ON "PasswordResetCode"("email", "code");

-- CreateIndex
CREATE INDEX "PasswordResetCode_expiresAt_idx" ON "PasswordResetCode"("expiresAt");
