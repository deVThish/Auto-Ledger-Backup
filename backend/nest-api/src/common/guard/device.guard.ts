import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { PrismaService } from '../../prisma/prisma.service';

interface AuthenticatedRequest extends Request {
  user: {
    id: string;
  };
}

@Injectable()
export class DeviceGuard implements CanActivate {
  constructor(
    private prisma: PrismaService,
    private reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const skipDeviceCheck = this.reflector.get<boolean>(
      'skipDeviceCheck',
      context.getHandler(),
    );
    if (skipDeviceCheck) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const user = request.user;

    if (!user || !user.id) {
      throw new UnauthorizedException('Unauthorized');
    }

    const deviceIdFromHeader = request.headers['device-id'];
    if (!deviceIdFromHeader || typeof deviceIdFromHeader !== 'string') {
      throw new UnauthorizedException({
        code: 'DEVICE_MISMATCH',
        message: 'Device ID not provided.',
      });
    }

    const dbUser = await this.prisma.user.findUnique({
      where: { user_Id: user.id },
      select: { device_Id: true },
    });

    if (!dbUser) {
      return true;
    }

    const storedDeviceId = dbUser.device_Id;

    if (!storedDeviceId || storedDeviceId !== deviceIdFromHeader) {
      throw new UnauthorizedException({
        code: 'DEVICE_MISMATCH',
        message: 'Device ID mismatch. Please verify your device.',
      });
    }

    return true;
  }
}
