-- CreateEnum
CREATE TYPE "ComputerType" AS ENUM ('DESKTOP', 'LAPTOP');

-- CreateEnum
CREATE TYPE "DiskType" AS ENUM ('SATA', 'IDE');

-- CreateEnum
CREATE TYPE "GraphicsCardType" AS ENUM ('INTEGRATED', 'SEPARATE');

-- CreateEnum
CREATE TYPE "DeviceStatus" AS ENUM ('ACTIVE', 'DISABLED', 'MAINTENANCE');

-- CreateTable
CREATE TABLE "Computer" (
    "id" TEXT NOT NULL,
    "type" "ComputerType" NOT NULL,
    "processor" TEXT NOT NULL,
    "motherboard" TEXT NOT NULL,
    "hardDiskType" "DiskType" NOT NULL,
    "hardDiskSpace" TEXT NOT NULL,
    "ramType" TEXT NOT NULL,
    "graphicsCard" "GraphicsCardType" NOT NULL,
    "status" "DeviceStatus" NOT NULL DEFAULT 'ACTIVE',
    "collegeId" INTEGER NOT NULL,
    "employeeId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Computer_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Computer" ADD CONSTRAINT "Computer_collegeId_fkey" FOREIGN KEY ("collegeId") REFERENCES "College"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Computer" ADD CONSTRAINT "Computer_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "Employee"("id") ON DELETE SET NULL ON UPDATE CASCADE;
