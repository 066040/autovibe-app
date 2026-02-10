import { Body, Controller, Get, Patch, Param, Post } from '@nestjs/common';
import { SourcesService } from './sources.service';

@Controller('sources')
export class SourcesController {
  constructor(private readonly sourcesService: SourcesService) {}

  @Get()
  list() {
    return this.sourcesService.list();
  }

  @Post()
  create(@Body() body: { name: string; url: string; type?: string }) {
    return this.sourcesService.create(body);
  }

  @Patch(':id/active')
  setActive(@Param('id') id: string, @Body() body: { isActive: boolean }) {
    return this.sourcesService.setActive(id, body.isActive);
  }

  // ✅ YENİ: Source update (publisherId bağlamak için)
  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body()
    body: {
      name?: string;
      url?: string;
      type?: string;
      isActive?: boolean;
      publisherId?: string | null;
    },
  ) {
    return this.sourcesService.update(id, body);
  }

  // ✅ website -> rss keşfet
  @Post('discover')
  discover(@Body() body: { website: string }) {
    return this.sourcesService.discoverAndCreate(body.website);
  }
}
