/*
  Warnings:

  - The primary key for the `Fine` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `dueDate` on the `Fine` table. All the data in the column will be lost.
  - You are about to drop the column `id` on the `Fine` table. All the data in the column will be lost.
  - You are about to drop the column `issuedAt` on the `Fine` table. All the data in the column will be lost.
  - You are about to drop the column `licenseId` on the `Fine` table. All the data in the column will be lost.
  - You are about to drop the column `offenseCategoryId` on the `Fine` table. All the data in the column will be lost.
  - You are about to drop the column `officerId` on the `Fine` table. All the data in the column will be lost.
  - The `status` column on the `Fine` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The primary key for the `Shift` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `endTime` on the `Shift` table. All the data in the column will be lost.
  - You are about to drop the column `id` on the `Shift` table. All the data in the column will be lost.
  - You are about to drop the column `isActive` on the `Shift` table. All the data in the column will be lost.
  - You are about to drop the column `officerId` on the `Shift` table. All the data in the column will be lost.
  - You are about to drop the column `startTime` on the `Shift` table. All the data in the column will be lost.
  - The primary key for the `User` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `id` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `nic` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `phoneNumber` on the `User` table. All the data in the column will be lost.
  - You are about to drop the `District` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `License` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `OffenseCategory` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Officer` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[nic_No]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[mobile_Phone_No]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - The required column `fine_Id` was added to the `Fine` table with a prisma-level default value. This is not possible if the table is not empty. Please add this column as optional, then populate it before making it required.
  - Added the required column `license_Id` to the `Fine` table without a default value. This is not possible if the table is not empty.
  - Added the required column `traffic_Officer_Id` to the `Fine` table without a default value. This is not possible if the table is not empty.
  - Added the required column `date` to the `Shift` table without a default value. This is not possible if the table is not empty.
  - Added the required column `end_Time` to the `Shift` table without a default value. This is not possible if the table is not empty.
  - The required column `shift_Id` was added to the `Shift` table with a prisma-level default value. This is not possible if the table is not empty. Please add this column as optional, then populate it before making it required.
  - Added the required column `start_Time` to the `Shift` table without a default value. This is not possible if the table is not empty.
  - Added the required column `traffic_Officer_Id` to the `Shift` table without a default value. This is not possible if the table is not empty.
  - Added the required column `mobile_Phone_No` to the `User` table without a default value. This is not possible if the table is not empty.
  - Added the required column `nic_No` to the `User` table without a default value. This is not possible if the table is not empty.
  - Added the required column `password` to the `User` table without a default value. This is not possible if the table is not empty.
  - The required column `user_Id` was added to the `User` table with a prisma-level default value. This is not possible if the table is not empty. Please add this column as optional, then populate it before making it required.

*/
-- CreateEnum
CREATE TYPE "License_Status" AS ENUM ('ACTIVE', 'SUSPENDED', 'EXPIRED', 'REVOKED');

-- CreateEnum
CREATE TYPE "Fine_Status" AS ENUM ('PENDING', 'PAID', 'OVERDUE');

-- CreateEnum
CREATE TYPE "Payment_Status" AS ENUM ('PENDING', 'COMPLETED', 'FAILED');

-- CreateEnum
CREATE TYPE "Officer_Role" AS ENUM ('TRAFFIC_OFFICER', 'DIVISIONAL_HEAD');

-- DropForeignKey
ALTER TABLE "Fine" DROP CONSTRAINT "Fine_licenseId_fkey";

-- DropForeignKey
ALTER TABLE "Fine" DROP CONSTRAINT "Fine_offenseCategoryId_fkey";

-- DropForeignKey
ALTER TABLE "Fine" DROP CONSTRAINT "Fine_officerId_fkey";

-- DropForeignKey
ALTER TABLE "License" DROP CONSTRAINT "License_userId_fkey";

-- DropForeignKey
ALTER TABLE "Officer" DROP CONSTRAINT "Officer_districtId_fkey";

-- DropForeignKey
ALTER TABLE "Shift" DROP CONSTRAINT "Shift_officerId_fkey";

-- DropIndex
DROP INDEX "User_nic_key";

-- DropIndex
DROP INDEX "User_phoneNumber_key";

-- AlterTable
ALTER TABLE "Fine" DROP CONSTRAINT "Fine_pkey",
DROP COLUMN "dueDate",
DROP COLUMN "id",
DROP COLUMN "issuedAt",
DROP COLUMN "licenseId",
DROP COLUMN "offenseCategoryId",
DROP COLUMN "officerId",
ADD COLUMN     "comment" TEXT,
ADD COLUMN     "due_Date" TIMESTAMP(3),
ADD COLUMN     "fine_Id" TEXT NOT NULL,
ADD COLUMN     "issue_At" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "license_Id" TEXT NOT NULL,
ADD COLUMN     "traffic_Officer_Id" TEXT NOT NULL,
DROP COLUMN "status",
ADD COLUMN     "status" "Fine_Status" NOT NULL DEFAULT 'PENDING',
ADD CONSTRAINT "Fine_pkey" PRIMARY KEY ("fine_Id");

-- AlterTable
ALTER TABLE "Shift" DROP CONSTRAINT "Shift_pkey",
DROP COLUMN "endTime",
DROP COLUMN "id",
DROP COLUMN "isActive",
DROP COLUMN "officerId",
DROP COLUMN "startTime",
ADD COLUMN     "date" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "end_Time" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "is_Active" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "location" TEXT,
ADD COLUMN     "shift_Id" TEXT NOT NULL,
ADD COLUMN     "start_Time" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "traffic_Officer_Id" TEXT NOT NULL,
ADD CONSTRAINT "Shift_pkey" PRIMARY KEY ("shift_Id");

-- AlterTable
ALTER TABLE "User" DROP CONSTRAINT "User_pkey",
DROP COLUMN "id",
DROP COLUMN "nic",
DROP COLUMN "phoneNumber",
ADD COLUMN     "device_Id" TEXT,
ADD COLUMN     "isPhoneVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "mobile_Phone_No" TEXT NOT NULL,
ADD COLUMN     "nic_No" TEXT NOT NULL,
ADD COLUMN     "password" TEXT NOT NULL,
ADD COLUMN     "user_Id" TEXT NOT NULL,
ADD CONSTRAINT "User_pkey" PRIMARY KEY ("user_Id");

-- DropTable
DROP TABLE "District";

-- DropTable
DROP TABLE "License";

-- DropTable
DROP TABLE "OffenseCategory";

-- DropTable
DROP TABLE "Officer";

-- DropEnum
DROP TYPE "FineStatus";

-- DropEnum
DROP TYPE "LicenseStatus";

-- DropEnum
DROP TYPE "OfficerRole";

-- CreateTable
CREATE TABLE "QR_Scan_History" (
    "scan_Id" TEXT NOT NULL,
    "qr_Token" TEXT NOT NULL,
    "scan_Time" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "traffic_Officer_Name" TEXT NOT NULL,
    "driver_Name" TEXT NOT NULL,
    "location" TEXT,
    "license_Id" TEXT NOT NULL,

    CONSTRAINT "QR_Scan_History_pkey" PRIMARY KEY ("scan_Id")
);

-- CreateTable
CREATE TABLE "DMT_Admin" (
    "dmt_Admin_Id" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "password" TEXT NOT NULL,

    CONSTRAINT "DMT_Admin_pkey" PRIMARY KEY ("dmt_Admin_Id")
);

-- CreateTable
CREATE TABLE "Police_Admin" (
    "police_Admin_Id" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "password" TEXT NOT NULL,

    CONSTRAINT "Police_Admin_pkey" PRIMARY KEY ("police_Admin_Id")
);

-- CreateTable
CREATE TABLE "Driving_License" (
    "license_Id" TEXT NOT NULL,
    "license_No" TEXT NOT NULL,
    "full_Name" TEXT NOT NULL,
    "nic_No" TEXT NOT NULL,
    "status" "License_Status" NOT NULL DEFAULT 'ACTIVE',
    "image" TEXT,
    "points" INTEGER NOT NULL DEFAULT 24,
    "address" TEXT NOT NULL,
    "date_of_birth" TIMESTAMP(3) NOT NULL,
    "blood_Group" TEXT NOT NULL,
    "issue_Date" TIMESTAMP(3) NOT NULL,
    "user_Id" TEXT NOT NULL,
    "dmt_Admin_Id" TEXT NOT NULL,

    CONSTRAINT "Driving_License_pkey" PRIMARY KEY ("license_Id")
);

-- CreateTable
CREATE TABLE "License_Vehicle_Category" (
    "category_Id" TEXT NOT NULL,
    "vehicle_Class" TEXT NOT NULL,
    "issue_Date" TIMESTAMP(3) NOT NULL,
    "expiry_Date" TIMESTAMP(3) NOT NULL,
    "restriction" TEXT,
    "license_Id" TEXT NOT NULL,

    CONSTRAINT "License_Vehicle_Category_pkey" PRIMARY KEY ("category_Id")
);

-- CreateTable
CREATE TABLE "Temporary_License" (
    "temporary_License_Id" TEXT NOT NULL,
    "issue_Date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiry_Date" TIMESTAMP(3) NOT NULL,
    "license_Id" TEXT NOT NULL,

    CONSTRAINT "Temporary_License_pkey" PRIMARY KEY ("temporary_License_Id")
);

-- CreateTable
CREATE TABLE "Division" (
    "division_Id" TEXT NOT NULL,
    "division_Name" TEXT NOT NULL,
    "police_Admin_Id" TEXT NOT NULL,

    CONSTRAINT "Division_pkey" PRIMARY KEY ("division_Id")
);

-- CreateTable
CREATE TABLE "Divisional_Head" (
    "divisional_Head_Id" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" "Officer_Role" NOT NULL DEFAULT 'DIVISIONAL_HEAD',
    "password" TEXT NOT NULL,
    "is_Active" BOOLEAN NOT NULL DEFAULT true,
    "reset_Otp" TEXT,
    "reset_Otp_Expires_At" TIMESTAMP(3),
    "division_Id" TEXT NOT NULL,

    CONSTRAINT "Divisional_Head_pkey" PRIMARY KEY ("divisional_Head_Id")
);

-- CreateTable
CREATE TABLE "Traffic_Officer" (
    "traffic_Officer_Id" TEXT NOT NULL,
    "badge_No" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" "Officer_Role" NOT NULL DEFAULT 'TRAFFIC_OFFICER',
    "password" TEXT NOT NULL,
    "reset_Otp" TEXT,
    "reset_Otp_Expires_At" TIMESTAMP(3),
    "divisional_Head_Id" TEXT NOT NULL,

    CONSTRAINT "Traffic_Officer_pkey" PRIMARY KEY ("traffic_Officer_Id")
);

-- CreateTable
CREATE TABLE "Offence_Category" (
    "offense_Id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "points_Value" INTEGER NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "is_Active" BOOLEAN NOT NULL DEFAULT true,
    "is_Court_Case" BOOLEAN NOT NULL DEFAULT false,
    "police_Admin_Id" TEXT NOT NULL,

    CONSTRAINT "Offence_Category_pkey" PRIMARY KEY ("offense_Id")
);

-- CreateTable
CREATE TABLE "Fine_Offence" (
    "fine_Id" TEXT NOT NULL,
    "offense_Id" TEXT NOT NULL,

    CONSTRAINT "Fine_Offence_pkey" PRIMARY KEY ("fine_Id","offense_Id")
);

-- CreateTable
CREATE TABLE "Payment" (
    "payment_Id" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "paidTime" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" "Payment_Status" NOT NULL DEFAULT 'COMPLETED',
    "fine_Id" TEXT NOT NULL,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("payment_Id")
);

-- CreateIndex
CREATE UNIQUE INDEX "DMT_Admin_username_key" ON "DMT_Admin"("username");

-- CreateIndex
CREATE UNIQUE INDEX "Police_Admin_username_key" ON "Police_Admin"("username");

-- CreateIndex
CREATE UNIQUE INDEX "Driving_License_license_No_key" ON "Driving_License"("license_No");

-- CreateIndex
CREATE UNIQUE INDEX "Driving_License_nic_No_key" ON "Driving_License"("nic_No");

-- CreateIndex
CREATE UNIQUE INDEX "Driving_License_user_Id_key" ON "Driving_License"("user_Id");

-- CreateIndex
CREATE UNIQUE INDEX "Division_division_Name_key" ON "Division"("division_Name");

-- CreateIndex
CREATE UNIQUE INDEX "Divisional_Head_username_key" ON "Divisional_Head"("username");

-- CreateIndex
CREATE UNIQUE INDEX "Divisional_Head_email_key" ON "Divisional_Head"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Traffic_Officer_badge_No_key" ON "Traffic_Officer"("badge_No");

-- CreateIndex
CREATE UNIQUE INDEX "Traffic_Officer_email_key" ON "Traffic_Officer"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Offence_Category_code_key" ON "Offence_Category"("code");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_fine_Id_key" ON "Payment"("fine_Id");

-- CreateIndex
CREATE UNIQUE INDEX "User_nic_No_key" ON "User"("nic_No");

-- CreateIndex
CREATE UNIQUE INDEX "User_mobile_Phone_No_key" ON "User"("mobile_Phone_No");

-- AddForeignKey
ALTER TABLE "QR_Scan_History" ADD CONSTRAINT "QR_Scan_History_license_Id_fkey" FOREIGN KEY ("license_Id") REFERENCES "Driving_License"("license_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Driving_License" ADD CONSTRAINT "Driving_License_user_Id_fkey" FOREIGN KEY ("user_Id") REFERENCES "User"("user_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Driving_License" ADD CONSTRAINT "Driving_License_dmt_Admin_Id_fkey" FOREIGN KEY ("dmt_Admin_Id") REFERENCES "DMT_Admin"("dmt_Admin_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "License_Vehicle_Category" ADD CONSTRAINT "License_Vehicle_Category_license_Id_fkey" FOREIGN KEY ("license_Id") REFERENCES "Driving_License"("license_Id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Temporary_License" ADD CONSTRAINT "Temporary_License_license_Id_fkey" FOREIGN KEY ("license_Id") REFERENCES "Driving_License"("license_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Division" ADD CONSTRAINT "Division_police_Admin_Id_fkey" FOREIGN KEY ("police_Admin_Id") REFERENCES "Police_Admin"("police_Admin_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Divisional_Head" ADD CONSTRAINT "Divisional_Head_division_Id_fkey" FOREIGN KEY ("division_Id") REFERENCES "Division"("division_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Traffic_Officer" ADD CONSTRAINT "Traffic_Officer_divisional_Head_Id_fkey" FOREIGN KEY ("divisional_Head_Id") REFERENCES "Divisional_Head"("divisional_Head_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Shift" ADD CONSTRAINT "Shift_traffic_Officer_Id_fkey" FOREIGN KEY ("traffic_Officer_Id") REFERENCES "Traffic_Officer"("traffic_Officer_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Offence_Category" ADD CONSTRAINT "Offence_Category_police_Admin_Id_fkey" FOREIGN KEY ("police_Admin_Id") REFERENCES "Police_Admin"("police_Admin_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Fine" ADD CONSTRAINT "Fine_license_Id_fkey" FOREIGN KEY ("license_Id") REFERENCES "Driving_License"("license_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Fine" ADD CONSTRAINT "Fine_traffic_Officer_Id_fkey" FOREIGN KEY ("traffic_Officer_Id") REFERENCES "Traffic_Officer"("traffic_Officer_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Fine_Offence" ADD CONSTRAINT "Fine_Offence_fine_Id_fkey" FOREIGN KEY ("fine_Id") REFERENCES "Fine"("fine_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Fine_Offence" ADD CONSTRAINT "Fine_Offence_offense_Id_fkey" FOREIGN KEY ("offense_Id") REFERENCES "Offence_Category"("offense_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_fine_Id_fkey" FOREIGN KEY ("fine_Id") REFERENCES "Fine"("fine_Id") ON DELETE RESTRICT ON UPDATE CASCADE;
