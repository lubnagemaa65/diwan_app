import { ActivityLog } from '@prisma/client';
import prisma from '../client';

/**
 * Log a user activity
 */
const logActivity = async (userId: number, action: string): Promise<void> => {
  try {
    await prisma.activityLog.create({
      data: { userId, action }
    });
  } catch (err) {
    // Logging should never break the actual operation it's attached to
    console.error('Failed to log activity:', err);
  }
};

/**
 * Query activity logs
 */
const queryActivityLogs = async (
  filter: object,
  options: {
    limit?: number;
    page?: number;
    sortBy?: string;
    sortType?: 'asc' | 'desc';
  }
): Promise<ActivityLog[]> => {
  const page = options.page ?? 1;
  const limit = options.limit ?? 20;
  const sortBy = options.sortBy;
  const sortType = options.sortType ?? 'desc';

  return prisma.activityLog.findMany({
    where: filter,
    include: {
      user: { select: { id: true, name: true, email: true } }
    },
    skip: (page - 1) * limit,
    take: limit,
    orderBy: sortBy ? { [sortBy]: sortType } : { createdAt: 'desc' }
  });
};

export default {
  logActivity,
  queryActivityLogs
};