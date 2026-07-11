/*
  Warnings:

  - You are about to drop the column `isPhoneVerified` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `mobile_Phone_No` on the `User` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[email]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `traffic_Officer_Id` to the `QR_Scan_History` table without a default value. This is not possible if the table is not empty.
  - Added the required column `issued_By` to the `Temporary_License` table without a default value. This is not possible if the table is not empty.
  - Added the required column `email` to the `User` table without a default value. This is not possible if the table is not empty.

*/
-- AlterEnum
ALTER TYPE "Fine_Status" ADD VALUE 'COURT_CASE';

-- DropIndex
DROP INDEX "User_mobile_Phone_No_key";

-- AlterTable
ALTER TABLE "Driving_License" ADD COLUMN     "suspended_Until" TIMESTAMP(3),
ALTER COLUMN "points" SET DEFAULT 0;

-- AlterTable
ALTER TABLE "QR_Scan_History" ADD COLUMN     "traffic_Officer_Id" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "Temporary_License" ADD COLUMN     "issued_By" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "User" DROP COLUMN "isPhoneVerified",
DROP COLUMN "mobile_Phone_No",
ADD COLUMN     "email" TEXT NOT NULL,
ADD COLUMN     "isEmailVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "reset_Otp" TEXT,
ADD COLUMN     "reset_Otp_Expires_At" TIMESTAMP(3);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- AddForeignKey
ALTER TABLE "QR_Scan_History" ADD CONSTRAINT "QR_Scan_History_traffic_Officer_Id_fkey" FOREIGN KEY ("traffic_Officer_Id") REFERENCES "Traffic_Officer"("traffic_Officer_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Temporary_License" ADD CONSTRAINT "Temporary_License_issued_By_fkey" FOREIGN KEY ("issued_By") REFERENCES "Traffic_Officer"("traffic_Officer_Id") ON DELETE RESTRICT ON UPDATE CASCADE;
