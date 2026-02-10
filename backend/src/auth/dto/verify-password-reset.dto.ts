import { IsEmail, IsString, Length } from 'class-validator';

export class VerifyPasswordResetDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(4, 10)
  code!: string;
}
