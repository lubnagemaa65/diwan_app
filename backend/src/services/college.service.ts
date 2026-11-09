import { College, Prisma } from '@prisma/client';
import httpStatus from 'http-status';
import prisma from '../client';
import ApiError from '../utils/ApiError';

/**
 * Create a college
 */
const createCollege = async (name: string): Promise<College> => {
  return prisma.college.create({
    data: { name }
  });
};

/**
 * Query for colleges
 */
const queryColleges = async (
  filter: object,
  options: {
    limit?: number;
    page?: number;
    sortBy?: string;
    sortType?: 'asc' | 'desc';
  }
): Promise<College[]> => {
  const page = options.page ?? 1;
  const limit = options.limit ?? 10;
  const sortBy = options.sortBy;
  const sortType = options.sortType ?? 'desc';

  return prisma.college.findMany({
    where: filter,
    skip: (page - 1) * limit,
    take: limit,
    orderBy: sortBy ? { [sortBy]: sortType } : undefined
  });
};

/**
 * Get college by id
 */
const getCollegeById = async (id: number): Promise<College | null> => {
  return prisma.college.findUnique({ where: { id } });
};

/**
 * Update college by id
 */
const updateCollegeById = async (
  collegeId: number,
  updateBody: Prisma.CollegeUpdateInput
): Promise<College> => {
  const college = await getCollegeById(collegeId);
  if (!college) {
    throw new ApiError(httpStatus.NOT_FOUND, 'College not found');
  }
  return prisma.college.update({
    where: { id: collegeId },
    data: updateBody
  });
};

/**
 * Delete college by id
 */
const deleteCollegeById = async (collegeId: number): Promise<College> => {
  const college = await getCollegeById(collegeId);
  if (!college) {
    throw new ApiError(httpStatus.NOT_FOUND, 'College not found');
  }
  await prisma.college.delete({ where: { id: collegeId } });
  return college;
};

export default {
  createCollege,
  queryColleges,
  getCollegeById,
  updateCollegeById,
  deleteCollegeById
};