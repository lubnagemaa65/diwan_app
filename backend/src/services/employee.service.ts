import { Employee, Prisma } from '@prisma/client';
import httpStatus from 'http-status';
import prisma from '../client';
import ApiError from '../utils/ApiError';

/**
 * Create an employee
 */
const createEmployee = async (data: {
  firstName: string;
  fatherName: string;
  lastName: string;
  userId: number;
  collegeId: number;
}): Promise<Employee> => {
  const user = await prisma.user.findUnique({ where: { id: data.userId } });
  if (!user) {
    throw new ApiError(httpStatus.BAD_REQUEST, 'User not found');
  }

  const existingEmployee = await prisma.employee.findUnique({ where: { userId: data.userId } });
  if (existingEmployee) {
    throw new ApiError(httpStatus.BAD_REQUEST, 'This user is already linked to an employee');
  }

  const college = await prisma.college.findUnique({ where: { id: data.collegeId } });
  if (!college) {
    throw new ApiError(httpStatus.BAD_REQUEST, 'College not found');
  }

  return prisma.employee.create({ data });
};

/**
 * Query for employees
 */
const queryEmployees = async (
  filter: object,
  options: {
    limit?: number;
    page?: number;
    sortBy?: string;
    sortType?: 'asc' | 'desc';
  }
): Promise<Employee[]> => {
  const page = options.page ?? 1;
  const limit = options.limit ?? 10;
  const sortBy = options.sortBy;
  const sortType = options.sortType ?? 'desc';

  return prisma.employee.findMany({
    where: filter,
    include: {
      user: { select: { id: true, email: true, role: true } },
      college: { select: { id: true, name: true } }
    },
    skip: (page - 1) * limit,
    take: limit,
    orderBy: sortBy ? { [sortBy]: sortType } : undefined
  });
};

/**
 * Get employee by id
 */
const getEmployeeById = async (id: number): Promise<Employee | null> => {
  return prisma.employee.findUnique({
    where: { id },
    include: {
      user: { select: { id: true, email: true, role: true } },
      college: { select: { id: true, name: true } }
    }
  });
};

/**
 * Update employee by id
 */
const updateEmployeeById = async (
  employeeId: number,
  updateBody: Prisma.EmployeeUncheckedUpdateInput
): Promise<Employee> => {
  const employee = await prisma.employee.findUnique({ where: { id: employeeId } });
  if (!employee) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Employee not found');
  }

  if (updateBody.collegeId) {
    const college = await prisma.college.findUnique({ where: { id: updateBody.collegeId as number } });
    if (!college) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'College not found');
    }
  }

  return prisma.employee.update({
    where: { id: employeeId },
    data: updateBody
  });
};

/**
 * Delete employee by id
 */
const deleteEmployeeById = async (employeeId: number): Promise<Employee> => {
  const employee = await prisma.employee.findUnique({ where: { id: employeeId } });
  if (!employee) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Employee not found');
  }
  await prisma.employee.delete({ where: { id: employeeId } });
  return employee;
};

export default {
  createEmployee,
  queryEmployees,
  getEmployeeById,
  updateEmployeeById,
  deleteEmployeeById
};