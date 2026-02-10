import { Controller, Get, Query } from "@nestjs/common";
import { NewsService } from "./news.service";
import { NewsQueryDto } from "./dto/news-query.dto";

@Controller("news")
export class NewsController {
  constructor(private readonly news: NewsService) {}

  @Get()
  list(@Query() q: NewsQueryDto) {
    return this.news.list(q);
  }
}
