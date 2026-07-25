import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { LicenseModule } from './license/license.module';
import { FinesModule } from './fines/fines.module';
import { QrModule } from './qr/qr.module';
import { OfficersModule } from './officers/officers.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ScheduleModule.forRoot(),
    PrismaModule,
    AuthModule,
    UsersModule,
    LicenseModule,
    FinesModule,
    QrModule,
    OfficersModule, // <-- මෙය Add කරන්න
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
