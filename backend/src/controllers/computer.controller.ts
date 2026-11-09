import httpStatus from 'http-status';
import pick from '../utils/pick';
import ApiError from '../utils/ApiError';
import catchAsync from '../utils/catchAsync';
import { computerService } from '../services';
import { activityLogService } from '../services';

const createComputer = catchAsync(async (req, res) => {
  const computer = await computerService.createComputer(req.body);
  await activityLogService.logActivity((req.user as { id: number }).id, `أضاف حاسوباً جديداً: ${computer.id}`);
  res.status(httpStatus.CREATED).send(computer);
});

const getComputers = catchAsync(async (req, res) => {
  const filter = pick(req.query, ['id','collegeId', 'employeeId', 'status', 'type']);
  const options = pick(req.query, ['sortBy', 'limit', 'page']);
  const result = await computerService.queryComputers(filter, options);
  res.send(result);
});

const getComputer = catchAsync(async (req, res) => {
  const computer = await computerService.getComputerById(req.params.computerId);
  if (!computer) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Computer not found');
  }
  res.send(computer);
});

const updateComputer = catchAsync(async (req, res) => {
  const computer = await computerService.updateComputerById(req.params.computerId, req.body);
  await activityLogService.logActivity((req.user as { id: number }).id, `عدّل بيانات الحاسوب: ${req.params.computerId}`);
  res.send(computer);
});

const deleteComputer = catchAsync(async (req, res) => {
  await computerService.deleteComputerById(req.params.computerId);
  await activityLogService.logActivity((req.user as { id: number }).id, `حذف الحاسوب: ${req.params.computerId}`);
  res.status(httpStatus.NO_CONTENT).send();
});

export default {
  createComputer,
  getComputers,
  getComputer,
  updateComputer,
  deleteComputer
};