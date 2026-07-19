import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

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

  async getQrStatus(sessionId: string) {
    const session = await this.prisma.qrSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      throw new NotFoundException('Invalid QR Code');
    }

    const currentTime = new Date();
    let status = session.status;

    if (status === 'ACTIVE' && currentTime > session.expiresAt) {
      await this.prisma.qrSession.update({
        where: { id: sessionId },
        data: { status: 'EXPIRED' },
      });
      status = 'EXPIRED';
    }

    return {
      status: status,
      expiresAt: session.expiresAt,
      scanned: status === 'ACTIVE' || status === 'EXPIRED',
    };
  }

  async scanQr(sessionId: string) {
    const session = await this.prisma.qrSession.findUnique({
      where: { id: sessionId },
      include: {
        user: {
          include: {
            license: {
              include: {
                vehicleCategories: true,
                fines: {
                  where: {
                    status: { in: ['PENDING', 'OVERDUE', 'COURT_CASE'] },
                  },
                  take: 5,
                  orderBy: { issue_At: 'desc' },
                },
              },
            },
          },
        },
      },
    });

    if (!session) {
      throw new NotFoundException('Invalid QR Code');
    }

    if (!session.user || !session.user.license) {
      throw new BadRequestException('No active license found for this user.');
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
        include: {
          user: {
            include: {
              license: {
                include: {
                  vehicleCategories: true,
                },
              },
            },
          },
        },
      });

      const license = updatedSession.user.license;

      return {
        success: true,
        message: 'Scan successful. Timer started.',
        sessionId: updatedSession.id,
        expiresAt: updatedSession.expiresAt,
        driver: {
          userId: updatedSession.user.user_Id,
          name: updatedSession.user.name,
          nic: updatedSession.user.nic_No,
          email: updatedSession.user.email,
          license: {
            licenseId: license.license_Id,
            licenseNo: license.license_No,
            fullName: license.full_Name,
            status: license.status,
            points: license.points,
            address: license.address,
            bloodGroup: license.blood_Group,
            dateOfBirth: license.date_of_birth,
            issueDate: license.issue_Date,
            image: license.image,
            suspendedUntil: license.suspended_Until,
            has24Suspension: license.has_24_Suspension,
            has50Suspension: license.has_50_Suspension,
            has100Revoke: license.has_100_Revoke,
            vehicleCategories: license.vehicleCategories,
          },
        },
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

      const license = session.user.license;

      return {
        success: true,
        message: 'Scan successful. Valid within 10 mins.',
        sessionId: session.id,
        expiresAt: session.expiresAt,
        driver: {
          userId: session.user.user_Id,
          name: session.user.name,
          nic: session.user.nic_No,
          email: session.user.email,
          license: {
            licenseId: license.license_Id,
            licenseNo: license.license_No,
            fullName: license.full_Name,
            status: license.status,
            points: license.points,
            address: license.address,
            bloodGroup: license.blood_Group,
            dateOfBirth: license.date_of_birth,
            issueDate: license.issue_Date,
            image: license.image,
            suspendedUntil: license.suspended_Until,
            has24Suspension: license.has_24_Suspension,
            has50Suspension: license.has_50_Suspension,
            has100Revoke: license.has_100_Revoke,
            vehicleCategories: license.vehicleCategories,
          },
        },
      };
    }
  }
}
