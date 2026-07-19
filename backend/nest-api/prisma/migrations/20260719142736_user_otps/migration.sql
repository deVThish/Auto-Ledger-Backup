-- AlterTable
ALTER TABLE "User" ADD COLUMN     "device_Otp" TEXT,
ADD COLUMN     "device_Otp_Expires_At" TIMESTAMP(3),
ADD COLUMN     "registration_Otp" TEXT,
ADD COLUMN     "registration_Otp_Expires_At" TIMESTAMP(3);
