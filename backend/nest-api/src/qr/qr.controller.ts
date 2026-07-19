import { Controller, Post, Body, Param, Get } from '@nestjs/common';
import { QrService } from './qr.service';

@Controller('qr')
export class QrController {
  constructor(private readonly qrService: QrService) {}

  @Post('generate')
  async generateQr(@Body('userId') userId: string) {
    return this.qrService.generateQrSession(userId);
  }

  @Get('status/:sessionId')
  async getQrStatus(@Param('sessionId') sessionId: string): Promise<{
    status: string;
    expiresAt: Date | null;
    scanned: boolean;
  }> {
    return await this.qrService.getQrStatus(sessionId);
  }

  @Post('scan/:sessionId')
  async scanQrCode(@Param('sessionId') sessionId: string) {
    return this.qrService.scanQr(sessionId);
  }
}
