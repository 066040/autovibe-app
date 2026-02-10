import { IsInt, IsOptional, IsString, Max, Min } from "class-validator";
import { Transform } from "class-transformer";

export class NewsQueryDto {
  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  q?: string;

  // cursor: "2026-01-19T00:00:00.000Z|ckxyz..."
  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;
}
