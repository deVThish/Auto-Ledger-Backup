import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service'; // Path eka hariyata danna

@Injectable()
export class QrService {
  constructor(private prisma: PrismaService) {}

  async generateQrSession(userId: string) {
    const session = await this.prisma.qrSession.create({
      data: {
        userId: userId,
        status: 'PENDING',
      },
    });
    return { qrToken: session.id };
  }

  async scanQr(sessionId: string) {
    const session = await this.prisma.qrSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      throw new NotFoundException('Invalid QR Code');
    }

    const currentTime = new Date();

    if (session.status === 'EXPIRED') {
      throw new BadRequestException('This QR code has expired.');
    }

    if (session.status === 'PENDING') {
      const expiresAt = new Date(currentTime.getTime() + 10 * 60000);
      const updatedSession = await this.prisma.qrSession.update({
        where: { id: sessionId },
        data: {
          status: 'ACTIVE',
          firstScannedAt: currentTime,
          expiresAt: expiresAt,
        },
      });

      return {
        success: true,
        message: 'Scan successful. Timer started.',
        userId: updatedSession.userId,
      };
    }

    if (session.status === 'ACTIVE') {
      if (currentTime > session.expiresAt) {
        await this.prisma.qrSession.update({
          where: { id: sessionId },
          data: { status: 'EXPIRED' },
        });
        throw new BadRequestException('This QR code has expired.');
      }

      return {
        success: true,
        message: 'Scan successful. Valid within 10 mins.',
        userId: session.userId,
      };
    }
  }
}
