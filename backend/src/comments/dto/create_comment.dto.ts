import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateCommentDto {
  @IsString()
  @MaxLength(2000)
  text!: string;

  @IsOptional()
  @IsString()
  parentId?: string;
}
