import { Body, Controller, Param, Post } from '@nestjs/common';
import { PublishersService } from './publishers.service';

@Controller('publishers')
export class PublishersController {
  constructor(private readonly publishersService: PublishersService) {}

  @Post()
  async create(@Body() body: { name: string; domain: string }) {
    return this.publishersService.create(body);
  }

  @Post(':id/verify')
  async verify(@Param('id') id: string) {
    return this.publishersService.verify(id);
  }
}
