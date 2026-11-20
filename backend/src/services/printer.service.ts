import { Printer, Prisma } from '@prisma/client';
import httpStatus from 'http-status';
import prisma from '../client';
import ApiError from '../utils/ApiError';

/**
 * Generate the next Printer ID for a given college
 * Format: COL{collegeId padded to 2 digits}-PR{counter padded to 3 digits}
 */
const generatePrinterId = async (
  collegeId: number,
  tx: Prisma.TransactionClient
): Promise<string> => {
  const prefix = `COL${String(collegeId).padStart(2, '0')}-PR`;
  // IDs are globally unique, even if an existing record belongs to another college.
  const printers = await tx.printer.findMany({
    where: { id: { startsWith: prefix } },
    select: { id: true }
  });

  let highest = BigInt(0);
  for (const printer of printers) {
    const suffix = printer.id.slice(prefix.length);
    if (/^\d+$/.test(suffix)) {
      const number = BigInt(suffix);
      if (number > highest) highest = number;
    }
  }

  return `${prefix}${String(highest + BigInt(1)).padStart(3, '0')}`;
};

const isPrinterIdConflict = (error: unknown): boolean => {
  if (!(error instanceof Prisma.PrismaClientKnownRequestError) || error.code !== 'P2002')
    return false;
  const target = error.meta?.target;
  return Array.isArray(target)
    ? target.length === 1 && target[0] === 'id'
    : target === 'id' || target === 'Printer_pkey';
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

  // The college row serializes cooperating creators, including across app instances.
  // Retry only primary-key conflicts from writers that do not take this lock.
  const maxAttempts = 5;
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    try {
      return await prisma.$transaction(
        async (tx) => {
          const colleges = await tx.$queryRaw<{ id: number }[]>`
            SELECT "id" FROM "College" WHERE "id" = ${data.collegeId} FOR NO KEY UPDATE
          `;
          if (colleges.length === 0) {
            throw new ApiError(httpStatus.BAD_REQUEST, 'College not found');
          }
          const id = await generatePrinterId(data.collegeId, tx);
          return tx.printer.create({ data: { ...data, id } });
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted,
          maxWait: 10000,
          timeout: 30000
        }
      );
    } catch (error) {
      if (!isPrinterIdConflict(error) || attempt === maxAttempts - 1) throw error;
    }
  }
  throw new Error('Unable to generate printer ID');
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
