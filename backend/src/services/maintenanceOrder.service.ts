import { MaintenanceOrder, Prisma, Role } from '@prisma/client';
import httpStatus from 'http-status';
import prisma from '../client';
import ApiError from '../utils/ApiError';

type MaintenanceOrderWithRelations = Prisma.MaintenanceOrderGetPayload<{
  include: typeof includeRelations;
}>;

const includeRelations = {
  computer: { select: { id: true, type: true } },
  printer: { select: { id: true, type: true } },
  requestedBy: { select: { id: true, firstName: true, lastName: true } },
  technician: { select: { id: true, name: true, email: true } }
};

/**
 * Create a maintenance order
 */
const createMaintenanceOrder = async (
  data: {
    type: MaintenanceOrder['type'];
    problemDescription: string;
    requestedById: number;
    computerId?: string;
    printerId?: string;
    technicianId?: number;
  },
  requestingUser: { id: number; role: Role }
): Promise<MaintenanceOrder> => {
let requestedById = data.requestedById;

if (requestingUser.role === Role.EMPLOYEE) {
  const ownEmployee = await prisma.employee.findUnique({
    where: { userId: requestingUser.id }
  });
  if (!ownEmployee) {
    throw new ApiError(httpStatus.BAD_REQUEST, 'No employee record linked to this user');
  }
  requestedById = ownEmployee.id;
} else if (!requestedById) {
  throw new ApiError(httpStatus.BAD_REQUEST, 'requestedById is required');
}

  const employee = await prisma.employee.findUnique({ where: { id: requestedById } });
  if (!employee) {
    throw new ApiError(httpStatus.BAD_REQUEST, 'Employee not found');
  }

  if (data.computerId) {
    const computer = await prisma.computer.findUnique({ where: { id: data.computerId } });
    if (!computer) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Computer not found');
    }
  }

  if (data.printerId) {
    const printer = await prisma.printer.findUnique({ where: { id: data.printerId } });
    if (!printer) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Printer not found');
    }
  }

  if (data.technicianId) {
    const technician = await prisma.user.findUnique({ where: { id: data.technicianId } });
    if (!technician || technician.role !== Role.TECHNICIAN) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Technician not found or user is not a technician');
    }
  }

  return prisma.maintenanceOrder.create({
    data: { ...data, requestedById },
    include: includeRelations
  });
};

/**
 * Query for maintenance orders
 */
const queryMaintenanceOrders = async (
  query: {
    status?: string;
    type?: string;
    technicianId?: number;
    requestedById?: number;
    computerId?: string;
    printerId?: string;
    deviceId?: string;
    collegeId?: number;
    dateFrom?: string;
    dateTo?: string;
  },
  options: {
    limit?: number;
    page?: number;
    sortBy?: string;
    sortType?: 'asc' | 'desc';
  },
  requestingUser: { id: number; role: Role }
): Promise<MaintenanceOrderWithRelations[]> => {
  const page = options.page ?? 1;
  const limit = options.limit ?? 10;
  const sortBy = options.sortBy;
  const sortType = options.sortType ?? 'desc';

  const { collegeId, dateFrom, dateTo, deviceId, ...rest } = query;
  const where: any = { ...rest };
  const andConditions: any[] = [];

  if (collegeId) {
    andConditions.push({
      OR: [
        { computer: { collegeId: Number(collegeId) } },
        { printer: { collegeId: Number(collegeId) } }
      ]
    });
  }

  if (deviceId) {
    andConditions.push({
      OR: [
        { computerId: { contains: deviceId, mode: 'insensitive' } },
        { printerId: { contains: deviceId, mode: 'insensitive' } }
      ]
    });
  }

  if (andConditions.length) {
    where.AND = andConditions;
  }

  if (dateFrom || dateTo) {
    where.date = {};
    if (dateFrom) where.date.gte = new Date(dateFrom);
    if (dateTo) where.date.lte = new Date(dateTo);
  }

  if (requestingUser.role === Role.EMPLOYEE) {
    const ownEmployee = await prisma.employee.findUnique({
      where: { userId: requestingUser.id }
    });
    where.requestedById = ownEmployee?.id ?? -1;
  }

  return prisma.maintenanceOrder.findMany({
    where,
    include: includeRelations,
    skip: (page - 1) * limit,
    take: limit,
    orderBy: sortBy ? { [sortBy]: sortType } : { date: 'desc' }
  });
};

/**
 * Get maintenance order by id
 */
const getMaintenanceOrderById = async (id: number): Promise<MaintenanceOrderWithRelations | null> => {
  return prisma.maintenanceOrder.findUnique({
    where: { id },
    include: includeRelations
  });
};

/**
 * Update maintenance order by id
 */
const updateMaintenanceOrderById = async (
  orderId: number,
  updateBody: Prisma.MaintenanceOrderUncheckedUpdateInput
): Promise<MaintenanceOrder> => {
  const order = await prisma.maintenanceOrder.findUnique({ where: { id: orderId } });
  if (!order) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Maintenance order not found');
  }

  if (updateBody.technicianId) {
    const technician = await prisma.user.findUnique({
      where: { id: updateBody.technicianId as number }
    });
    if (!technician || technician.role !== Role.TECHNICIAN) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Technician not found or user is not a technician');
    }
  }

  return prisma.maintenanceOrder.update({
    where: { id: orderId },
    data: updateBody,
    include: includeRelations
  });
};

/**
 * Delete maintenance order by id
 */
const deleteMaintenanceOrderById = async (orderId: number): Promise<MaintenanceOrder> => {
  const order = await prisma.maintenanceOrder.findUnique({ where: { id: orderId } });
  if (!order) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Maintenance order not found');
  }
  await prisma.maintenanceOrder.delete({ where: { id: orderId } });
  return order;
};

export default {
  createMaintenanceOrder,
  queryMaintenanceOrders,
  getMaintenanceOrderById,
  updateMaintenanceOrderById,
  deleteMaintenanceOrderById
};