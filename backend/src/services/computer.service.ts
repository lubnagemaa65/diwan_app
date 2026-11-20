import { Computer, Prisma } from '@prisma/client';
import httpStatus from 'http-status';
import prisma from '../client';
import ApiError from '../utils/ApiError';

/**
 * Generate the next Computer ID for a given college
 * Format: COL{collegeId padded to 2 digits}-PC{counter padded to 3 digits}
 */
const generateComputerId = async (
  collegeId: number,
  tx: Prisma.TransactionClient
): Promise<string> => {
  const prefix = `COL${String(collegeId).padStart(2, '0')}-PC`;
  // IDs are globally unique, even if an existing record belongs to another college.
  const computers = await tx.computer.findMany({
    where: { id: { startsWith: prefix } },
    select: { id: true }
  });

  let highest = BigInt(0);
  for (const computer of computers) {
    const suffix = computer.id.slice(prefix.length);
    if (/^\d+$/.test(suffix)) {
      const number = BigInt(suffix);
      if (number > highest) highest = number;
    }
  }

  return `${prefix}${String(highest + BigInt(1)).padStart(3, '0')}`;
};

const isComputerIdConflict = (error: unknown): boolean => {
  if (!(error instanceof Prisma.PrismaClientKnownRequestError) || error.code !== 'P2002')
    return false;
  const target = error.meta?.target;
  return Array.isArray(target)
    ? target.length === 1 && target[0] === 'id'
    : target === 'id' || target === 'Computer_pkey';
};

/**
 * Create a computer
 */
const createComputer = async (data: {
  type: Computer['type'];
  processor: string;
  motherboard: string;
  hardDiskType: Computer['hardDiskType'];
  hardDiskSpace: string;
  ramType: string;
  graphicsCard: Computer['graphicsCard'];
  status?: Computer['status'];
  collegeId: number;
  employeeId?: number | null;
}): Promise<Computer> => {
  const college = await prisma.college.findUnique({ where: { id: data.collegeId } });
  if (!college) {
    throw new ApiError(httpStatus.BAD_REQUEST, 'College not found');
  }

  if (data.employeeId) {
    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Employee not found');
    }
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
          const id = await generateComputerId(data.collegeId, tx);
          return tx.computer.create({ data: { ...data, id } });
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted,
          maxWait: 10000,
          timeout: 30000
        }
      );
    } catch (error) {
      if (!isComputerIdConflict(error) || attempt === maxAttempts - 1) throw error;
    }
  }
  throw new Error('Unable to generate computer ID');
};

/**
 * Query for computers
 */
const queryComputers = async (
  filter: { id?: string; [key: string]: any },
  options: {
    limit?: number;
    page?: number;
    sortBy?: string;
    sortType?: 'asc' | 'desc';
  }
): Promise<Computer[]> => {
  const page = options.page ?? 1;
  const limit = options.limit ?? 10;
  const sortBy = options.sortBy;
  const sortType = options.sortType ?? 'desc';

  const { id, ...rest } = filter;
  const where: any = { ...rest };
  if (id) {
    where.id = { contains: id, mode: 'insensitive' };
  }

  return prisma.computer.findMany({
    where,
    include: {
      college: { select: { id: true, name: true } },
      employee: { select: { id: true, firstName: true, lastName: true } }
    },
    skip: (page - 1) * limit,
    take: limit,
    orderBy: sortBy ? { [sortBy]: sortType } : undefined
  });
};

/**
 * Get computer by id
 */
const getComputerById = async (id: string): Promise<Computer | null> => {
  return prisma.computer.findUnique({
    where: { id },
    include: {
      college: { select: { id: true, name: true } },
      employee: { select: { id: true, firstName: true, lastName: true } }
    }
  });
};

/**
 * Update computer by id
 */
const updateComputerById = async (
  computerId: string,
  updateBody: Prisma.ComputerUncheckedUpdateInput
): Promise<Computer> => {
  const computer = await prisma.computer.findUnique({ where: { id: computerId } });
  if (!computer) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Computer not found');
  }

  if (updateBody.employeeId) {
    const employee = await prisma.employee.findUnique({
      where: { id: updateBody.employeeId as number }
    });
    if (!employee) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Employee not found');
    }
  }

  return prisma.computer.update({
    where: { id: computerId },
    data: updateBody
  });
};

/**
 * Delete computer by id
 */
const deleteComputerById = async (computerId: string): Promise<Computer> => {
  const computer = await prisma.computer.findUnique({ where: { id: computerId } });
  if (!computer) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Computer not found');
  }
  await prisma.computer.delete({ where: { id: computerId } });
  return computer;
};

export default {
  createComputer,
  queryComputers,
  getComputerById,
  updateComputerById,
  deleteComputerById
};
