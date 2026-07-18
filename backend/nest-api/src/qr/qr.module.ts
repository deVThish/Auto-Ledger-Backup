import { Module } from '@nestjs/common';
import { QrService } from './qr.service';
import { QrController } from './qr.controller';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  controllers: [QrController],
  providers: [QrService, PrismaService],
  exports: [QrService],
})
export class QrModule {}
