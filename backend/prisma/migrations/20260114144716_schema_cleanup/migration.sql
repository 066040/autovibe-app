-- CreateIndex
CREATE INDEX "Article_sourceId_idx" ON "Article"("sourceId");

-- CreateIndex
CREATE INDEX "Article_createdAt_idx" ON "Article"("createdAt");

-- CreateIndex
CREATE INDEX "Comment_status_createdAt_idx" ON "Comment"("status", "createdAt");

-- CreateIndex
CREATE INDEX "CommentLike_createdAt_idx" ON "CommentLike"("createdAt");

-- CreateIndex
CREATE INDEX "PasswordResetCode_createdAt_idx" ON "PasswordResetCode"("createdAt");

-- CreateIndex
CREATE INDEX "Source_publisherId_idx" ON "Source"("publisherId");

-- CreateIndex
CREATE INDEX "Source_isActive_idx" ON "Source"("isActive");

-- CreateIndex
CREATE INDEX "User_createdAt_idx" ON "User"("createdAt");
