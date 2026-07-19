import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

interface AuthenticatedRequest extends Request {
  user: {
    id: string;
    role?: string;
  };
}

@Injectable()
export class ActiveShiftGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const user = request.user;

    if (!user || !user.id) {
      throw new ForbiddenException('Unauthorized');
    }

    if (user.role !== 'TRAFFIC_OFFICER') {
      return true;
    }

    const now = new Date();

    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { traffic_Officer_Id: user.id },
      include: {
        shifts: {
          where: {
            is_Active: true,
            start_Time: { lte: now },
            end_Time: { gte: now },
          },
        },
      },
    });

    if (!officer) {
      throw new ForbiddenException('Officer not found');
    }

    if (officer.shifts.length === 0) {
      throw new ForbiddenException(
        'Access Denied: You are not within an active shift schedule.',
      );
    }

    return true;
  }
}
