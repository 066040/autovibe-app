import { BadRequestException, Body, Controller, Get, Post } from '@nestjs/common';
import { ReactionsService } from './reactions.service';

@Controller()
export class ReactionsController {
  constructor(private readonly reactions: ReactionsService) {}

  @Post('likes/toggle')
  toggleLike(@Body() body: any) {
    const articleId = body?.articleId;
    if (!articleId || typeof articleId !== 'string') {
      throw new BadRequestException('articleId is required');
    }
    return this.reactions.toggleLikeByDemo(articleId);
  }

  @Post('saved/toggle')
  toggleSaved(@Body() body: any) {
    const articleId = body?.articleId;
    if (!articleId || typeof articleId !== 'string') {
      throw new BadRequestException('articleId is required');
    }
    return this.reactions.toggleSavedByDemo(articleId);
  }

  @Get('me/likes')
  myLikes() {
    return this.reactions.getMyLikesByDemo();
  }

  @Get('me/saved')
  mySaved() {
    return this.reactions.getMySavedByDemo();
  }
}
