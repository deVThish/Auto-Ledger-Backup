import { Module } from '@nestjs/common';
import { FinesService } from './fines.service';
import { FinesController } from './fines.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { ActiveShiftGuard } from '../common/guard/active-shift.guard';

@Module({
  imports: [PrismaModule],
  controllers: [FinesController],
  providers: [FinesService, ActiveShiftGuard],
  exports: [FinesService],
})
export class FinesModule {}
