import httpStatus from 'http-status';
import pick from '../utils/pick';
import ApiError from '../utils/ApiError';
import catchAsync from '../utils/catchAsync';
import { collegeService } from '../services';
import { activityLogService } from '../services';

const createCollege = catchAsync(async (req, res) => {
  const { name } = req.body;
  const college = await collegeService.createCollege(name);
  await activityLogService.logActivity((req.user as { id: number }).id, `أضاف كلية جديدة: ${name}`);
  res.status(httpStatus.CREATED).send(college);
});

const getColleges = catchAsync(async (req, res) => {
  const filter = pick(req.query, ['name']);
  const options = pick(req.query, ['sortBy', 'limit', 'page']);
  const result = await collegeService.queryColleges(filter, options);
  res.send(result);
});

const getCollege = catchAsync(async (req, res) => {
  const college = await collegeService.getCollegeById(Number(req.params.collegeId));
  if (!college) {
    throw new ApiError(httpStatus.NOT_FOUND, 'College not found');
  }
  res.send(college);
});

const updateCollege = catchAsync(async (req, res) => {
  const college = await collegeService.updateCollegeById(Number(req.params.collegeId), req.body);
  await activityLogService.logActivity((req.user as { id: number }).id, `عدّل بيانات الكلية رقم: ${req.params.collegeId}`);
  res.send(college);
});

const deleteCollege = catchAsync(async (req, res) => {
  await collegeService.deleteCollegeById(Number(req.params.collegeId));
  await activityLogService.logActivity((req.user as { id: number }).id, `حذف الكلية رقم: ${req.params.collegeId}`);
  res.status(httpStatus.NO_CONTENT).send();
});

export default {
  createCollege,
  getColleges,
  getCollege,
  updateCollege,
  deleteCollege
};