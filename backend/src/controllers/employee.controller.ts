import httpStatus from 'http-status';
import pick from '../utils/pick';
import ApiError from '../utils/ApiError';
import catchAsync from '../utils/catchAsync';
import { employeeService } from '../services';
import { activityLogService } from '../services';

const createEmployee = catchAsync(async (req, res) => {
  const employee = await employeeService.createEmployee(req.body);
  await activityLogService.logActivity((req.user as { id: number }).id, `أضاف موظف جديد: ${req.body.firstName} ${req.body.lastName}`);
  res.status(httpStatus.CREATED).send(employee);
});

const getEmployees = catchAsync(async (req, res) => {
  const filter = pick(req.query, ['collegeId']);
  const options = pick(req.query, ['sortBy', 'limit', 'page']);
  const result = await employeeService.queryEmployees(filter, options);
  res.send(result);
});

const getEmployee = catchAsync(async (req, res) => {
  const employee = await employeeService.getEmployeeById(Number(req.params.employeeId));
  if (!employee) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Employee not found');
  }
  res.send(employee);
});

const updateEmployee = catchAsync(async (req, res) => {
  const employee = await employeeService.updateEmployeeById(
    Number(req.params.employeeId),
    req.body
  );
  await activityLogService.logActivity((req.user as { id: number }).id, `عدّل بيانات الموظف رقم: ${req.params.employeeId}`);
  res.send(employee);
});

const deleteEmployee = catchAsync(async (req, res) => {
  await employeeService.deleteEmployeeById(Number(req.params.employeeId));
  await activityLogService.logActivity((req.user as { id: number }).id, `حذف الموظف رقم: ${req.params.employeeId}`);
  res.status(httpStatus.NO_CONTENT).send();
});

export default {
  createEmployee,
  getEmployees,
  getEmployee,
  updateEmployee,
  deleteEmployee
};