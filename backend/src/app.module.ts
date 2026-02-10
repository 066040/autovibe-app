import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SourcesModule } from './sources/sources.module';
import { RssModule } from './rss/rss.module';
import { ArticlesModule } from './articles/articles.module';
import { ScheduleModule } from '@nestjs/schedule';
import { PublishersModule } from './publishers/publishers.module';
import { CommentsModule } from './comments/comments.module';
import { AuthModule } from './auth/auth.module';
import { ReactionsModule } from './reactions/reactions.module';
import { NewsModule } from './news/news.module';
@Module({
  imports: [SourcesModule, RssModule, ArticlesModule,ScheduleModule.forRoot(),PublishersModule,CommentsModule,AuthModule, ReactionsModule, NewsModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
