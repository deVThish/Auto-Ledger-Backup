-- CreateEnum
CREATE TYPE "QrSessionStatus" AS ENUM ('PENDING', 'ACTIVE', 'EXPIRED');

-- CreateTable
CREATE TABLE "QrSession" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" "QrSessionStatus" NOT NULL DEFAULT 'PENDING',
    "firstScannedAt" TIMESTAMP(3),
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "QrSession_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "QrSession" ADD CONSTRAINT "QrSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("user_Id") ON DELETE RESTRICT ON UPDATE CASCADE;
