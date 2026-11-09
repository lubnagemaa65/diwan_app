import httpStatus from 'http-status';
import pick from '../utils/pick';
import ApiError from '../utils/ApiError';
import catchAsync from '../utils/catchAsync';
import { printerService } from '../services';
import { activityLogService } from '../services';

const createPrinter = catchAsync(async (req, res) => {
  const printer = await printerService.createPrinter(req.body);
  await activityLogService.logActivity((req.user as { id: number }).id, `أضاف طابعة جديدة: ${printer.id}`);
  res.status(httpStatus.CREATED).send(printer);
});

const getPrinters = catchAsync(async (req, res) => {
  const filter = pick(req.query, ['id','collegeId', 'status']);
  const options = pick(req.query, ['sortBy', 'limit', 'page']);
  const result = await printerService.queryPrinters(filter, options);
  res.send(result);
});

const getPrinter = catchAsync(async (req, res) => {
  const printer = await printerService.getPrinterById(req.params.printerId);
  if (!printer) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Printer not found');
  }
  res.send(printer);
});

const updatePrinter = catchAsync(async (req, res) => {
  const printer = await printerService.updatePrinterById(req.params.printerId, req.body);
  await activityLogService.logActivity((req.user as { id: number }).id, `عدّل بيانات الطابعة: ${req.params.printerId}`);
  res.send(printer);
});

const deletePrinter = catchAsync(async (req, res) => {
  await printerService.deletePrinterById(req.params.printerId);
  await activityLogService.logActivity((req.user as { id: number }).id, `حذف الطابعة: ${req.params.printerId}`);
  res.status(httpStatus.NO_CONTENT).send();
});

export default {
  createPrinter,
  getPrinters,
  getPrinter,
  updatePrinter,
  deletePrinter
};