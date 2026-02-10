import { Body, Controller, Delete, Get, Param, Post, Query } from '@nestjs/common';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create_comment.dto';

@Controller('comments')
export class CommentsController {
  constructor(private readonly comments: CommentsService) {}

  // GET /comments/articles/:id/comments?cursor=...&limit=20
  @Get('articles/:id/comments')
  async list(
    @Param('id') articleId: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    const lim = Math.min(parseInt(limit ?? '20', 10) || 20, 50);
    return this.comments.listByArticle(articleId, { cursor, limit: lim });
  }

  // GET /comments/articles/:id/comments/count
  @Get('articles/:id/comments/count')
  async count(@Param('id') articleId: string) {
    return this.comments.countByArticle(articleId);
  }

  // POST /comments/articles/:id/comments
  @Post('articles/:id/comments')
  async create(@Param('id') articleId: string, @Body() dto: CreateCommentDto) {
    return this.comments.create(articleId, dto);
  }

  // DELETE /comments/:id
  @Delete(':id')
  async remove(@Param('id') commentId: string) {
    return this.comments.softDelete(commentId);
  }

  // ✅ POST /comments/:id/like
  @Post(':id/like')
  async like(@Param('id') commentId: string) {
    return this.comments.like(commentId);
  }

  // ✅ DELETE /comments/:id/like
  @Delete(':id/like')
  async unlike(@Param('id') commentId: string) {
    return this.comments.unlike(commentId);
  }
}
