import { IsEmail, IsString, Length, MinLength } from 'class-validator';

export class ConfirmPasswordResetDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(4, 10)
  code!: string;

  @IsString()
  @MinLength(6)
  newPassword!: string;
}
