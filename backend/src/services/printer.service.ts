import { Printer, Prisma } from '@prisma/client';
import httpStatus from 'http-status';
import prisma from '../client';
import ApiError from '../utils/ApiError';


/**
 * Generate the next Printer ID for a given college
 * Format: COL{collegeId padded to 2 digits}-PR{counter padded to 3 digits}
 */
const generatePrinterId = async (collegeId: number): Promise<string> => {
  const collegePart = `COL${String(collegeId).padStart(2, '0')}`;

  const count = await prisma.printer.count({
    where: { collegeId }
  });

  const nextNumber = count + 1;
  const printerPart = `PR${String(nextNumber).padStart(3, '0')}`;

  return `${collegePart}-${printerPart}`;
};

/**
 * Create a printer
 */
const createPrinter = async (data: {
  type: string;
  status?: Printer['status'];
  collegeId: number;
}): Promise<Printer> => {
  const college = await prisma.college.findUnique({ where: { id: data.collegeId } });
  if (!college) {
    throw new ApiError(httpStatus.BAD_REQUEST, 'College not found');
  }

  const id = await generatePrinterId(data.collegeId);

  return prisma.printer.create({
    data: {
      ...data,
      id
    }
  });
};

/**
 * Query for printers
 */
const queryPrinters = async (
  filter: { id?: string; [key: string]: any },
  options: {
    limit?: number;
    page?: number;
    sortBy?: string;
    sortType?: 'asc' | 'desc';
  }
): Promise<Printer[]> => {
  const page = options.page ?? 1;
  const limit = options.limit ?? 10;
  const sortBy = options.sortBy;
  const sortType = options.sortType ?? 'desc';

  const { id, ...rest } = filter;
  const where: any = { ...rest };
  if (id) {
    where.id = { contains: id, mode: 'insensitive' };
  }

  return prisma.printer.findMany({
    where,
    include: {
      college: { select: { id: true, name: true } }
    },
    skip: (page - 1) * limit,
    take: limit,
    orderBy: sortBy ? { [sortBy]: sortType } : undefined
  });
};

/**
 * Get printer by id
 */
const getPrinterById = async (id: string): Promise<Printer | null> => {
  return prisma.printer.findUnique({
    where: { id },
    include: {
      college: { select: { id: true, name: true } }
    }
  });
};

/**
 * Update printer by id
 */
const updatePrinterById = async (
  printerId: string,
  updateBody: Prisma.PrinterUncheckedUpdateInput
): Promise<Printer> => {
  const printer = await prisma.printer.findUnique({ where: { id: printerId } });
  if (!printer) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Printer not found');
  }

  return prisma.printer.update({
    where: { id: printerId },
    data: updateBody
  });
};

/**
 * Delete printer by id
 */
const deletePrinterById = async (printerId: string): Promise<Printer> => {
  const printer = await prisma.printer.findUnique({ where: { id: printerId } });
  if (!printer) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Printer not found');
  }
  await prisma.printer.delete({ where: { id: printerId } });
  return printer;
};

export default {
  createPrinter,
  queryPrinters,
  getPrinterById,
  updatePrinterById,
  deletePrinterById
};