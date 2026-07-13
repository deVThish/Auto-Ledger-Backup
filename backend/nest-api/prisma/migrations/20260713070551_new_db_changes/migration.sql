-- AlterEnum
ALTER TYPE "License_Status" ADD VALUE 'TEMPORARY';

-- AlterTable
ALTER TABLE "Driving_License" ADD COLUMN     "has_100_Revoke" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "has_24_Suspension" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "has_50_Suspension" BOOLEAN NOT NULL DEFAULT false;
