/*
  Warnings:

  - A unique constraint covering the columns `[triggering_Fine_Id]` on the table `Driving_License` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `head_Id` to the `Fine` table without a default value. This is not possible if the table is not empty.
  - Added the required column `head_Id` to the `QR_Scan_History` table without a default value. This is not possible if the table is not empty.
  - Added the required column `head_Id` to the `Shift` table without a default value. This is not possible if the table is not empty.
  - Added the required column `head_Id` to the `Temporary_License` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Driving_License" ADD COLUMN     "triggering_Fine_Id" TEXT;

-- AlterTable
ALTER TABLE "Fine" ADD COLUMN     "head_Id" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "QR_Scan_History" ADD COLUMN     "head_Id" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "Shift" ADD COLUMN     "head_Id" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "Temporary_License" ADD COLUMN     "head_Id" TEXT NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "Driving_License_triggering_Fine_Id_key" ON "Driving_License"("triggering_Fine_Id");

-- AddForeignKey
ALTER TABLE "QR_Scan_History" ADD CONSTRAINT "QR_Scan_History_head_Id_fkey" FOREIGN KEY ("head_Id") REFERENCES "Divisional_Head"("divisional_Head_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Driving_License" ADD CONSTRAINT "Driving_License_triggering_Fine_Id_fkey" FOREIGN KEY ("triggering_Fine_Id") REFERENCES "Fine"("fine_Id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Temporary_License" ADD CONSTRAINT "Temporary_License_head_Id_fkey" FOREIGN KEY ("head_Id") REFERENCES "Divisional_Head"("divisional_Head_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Shift" ADD CONSTRAINT "Shift_head_Id_fkey" FOREIGN KEY ("head_Id") REFERENCES "Divisional_Head"("divisional_Head_Id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Fine" ADD CONSTRAINT "Fine_head_Id_fkey" FOREIGN KEY ("head_Id") REFERENCES "Divisional_Head"("divisional_Head_Id") ON DELETE RESTRICT ON UPDATE CASCADE;
