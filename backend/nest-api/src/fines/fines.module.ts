import { Module } from '@nestjs/common';
import { FinesService } from './fines.service';
import { FinesController } from './fines.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { JwtModule } from '@nestjs/jwt';

@Module({
  imports: [
    PrismaModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'defaultSecretKey',
    }),
  ],
  controllers: [FinesController],
  providers: [FinesService],
  exports: [FinesService],
})
export class FinesModule {}
