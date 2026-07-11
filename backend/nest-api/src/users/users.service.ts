import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getUserById(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { user_Id: userId },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async updateUserDevice(userId: string, newDeviceId: string) {
    return this.prisma.user.update({
      where: { user_Id: userId },
      data: { device_Id: newDeviceId },
    });
  }

  async verifyEmail(userId: string) {
    return this.prisma.user.update({
      where: { user_Id: userId },
      data: { isEmailVerified: true },
    });
  }
}
