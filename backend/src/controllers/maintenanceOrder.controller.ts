import httpStatus from 'http-status';
import pick from '../utils/pick';
import ApiError from '../utils/ApiError';
import catchAsync from '../utils/catchAsync';
import { maintenanceOrderService } from '../services';
import { Role } from '@prisma/client';
import { aiService } from '../services';
import { activityLogService } from '../services';

const getTriageSuggestion = catchAsync(async (req, res) => {
  const order = await maintenanceOrderService.getMaintenanceOrderById(Number(req.params.orderId));
  if (!order) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Maintenance order not found');
  }
  const deviceType = order.computer?.type || order.printer?.type || 'جهاز';
  const suggestion = await aiService.getTriageSuggestion(order.problemDescription, deviceType);
  res.send({ suggestion });
});

const createMaintenanceOrder = catchAsync(async (req, res) => {
  const order = await maintenanceOrderService.createMaintenanceOrder(req.body, req.user as { id: number; role: Role });
  const deviceId = order.computerId || order.printerId;
  await activityLogService.logActivity((req.user as { id: number }).id, `أنشأ طلب صيانة جديد لجهاز: ${deviceId}`);
  res.status(httpStatus.CREATED).send(order);
});

const getMaintenanceOrders = catchAsync(async (req, res) => {
  const query = pick(req.query, [
    'status',
    'type',
    'technicianId',
    'requestedById',
    'computerId',
    'printerId',
    'deviceId',
    'collegeId',
    'dateFrom',
    'dateTo'
  ]);
  const options = pick(req.query, ['sortBy', 'limit', 'page']);
  const result = await maintenanceOrderService.queryMaintenanceOrders(
    query,
    options,
    req.user as { id: number; role: Role }
  );
  res.send(result);
});

const getMaintenanceOrder = catchAsync(async (req, res) => {
  const order = await maintenanceOrderService.getMaintenanceOrderById(Number(req.params.orderId));
  if (!order) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Maintenance order not found');
  }
  res.send(order);
});

const updateMaintenanceOrder = catchAsync(async (req, res) => {
  const order = await maintenanceOrderService.updateMaintenanceOrderById(Number(req.params.orderId), req.body);
  await activityLogService.logActivity((req.user as { id: number }).id, `عدّل طلب الصيانة رقم: ${req.params.orderId}`);
  res.send(order);
});

const deleteMaintenanceOrder = catchAsync(async (req, res) => {
  await maintenanceOrderService.deleteMaintenanceOrderById(Number(req.params.orderId));
  await activityLogService.logActivity((req.user as { id: number }).id, `حذف طلب الصيانة رقم: ${req.params.orderId}`);
  res.status(httpStatus.NO_CONTENT).send();
});

export default {
  createMaintenanceOrder,
  getMaintenanceOrders,
  getMaintenanceOrder,
  updateMaintenanceOrder,
  deleteMaintenanceOrder,
   getTriageSuggestion
};