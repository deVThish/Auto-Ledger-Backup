import { Controller, Post, Body, Param } from '@nestjs/common';
import { QrService } from './qr.service';

@Controller('qr')
export class QrController {
  constructor(private readonly qrService: QrService) {}

  @Post('generate')
  async generateQr(@Body('userId') userId: string) {
    return this.qrService.generateQrSession(userId);
  }

  @Post('scan/:sessionId')
  async scanQrCode(@Param('sessionId') sessionId: string) {
    return this.qrService.scanQr(sessionId);
  }
}
