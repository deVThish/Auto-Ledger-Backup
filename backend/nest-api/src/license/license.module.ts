import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { LicenseController } from './license.controller';
import { LicenseService } from './license.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [HttpModule, PrismaModule],
  controllers: [LicenseController],
  providers: [LicenseService],
})
export class LicenseModule {}
