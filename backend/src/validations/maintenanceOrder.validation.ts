import Joi from 'joi';
import { MaintenanceType, MaintenanceOrderStatus } from '@prisma/client';

const createMaintenanceOrder = {
  body: Joi.object()
    .keys({
      type: Joi.string().valid(...Object.values(MaintenanceType)).required(),
      problemDescription: Joi.string().required(),
      requestedById: Joi.number().integer(),
      computerId: Joi.string(),
      printerId: Joi.string(),
      technicianId: Joi.number().integer()
    })
    .xor('computerId', 'printerId')
};

const getMaintenanceOrders = {
  query: Joi.object().keys({
    status: Joi.string().valid(...Object.values(MaintenanceOrderStatus)),
    type: Joi.string().valid(...Object.values(MaintenanceType)),
    technicianId: Joi.number().integer(),
    requestedById: Joi.number().integer(),
    computerId: Joi.string(),
    printerId: Joi.string(),
    deviceId: Joi.string(),
    collegeId: Joi.number().integer(),
    dateFrom: Joi.date(),
    dateTo: Joi.date(),
    sortBy: Joi.string(),
    limit: Joi.number().integer(),
    page: Joi.number().integer()
  })
};

const getMaintenanceOrder = {
  params: Joi.object().keys({
    orderId: Joi.number().integer().required()
  })
};

const updateMaintenanceOrder = {
  params: Joi.object().keys({
    orderId: Joi.number().integer().required()
  }),
  body: Joi.object()
    .keys({
      type: Joi.string().valid(...Object.values(MaintenanceType)),
      problemDescription: Joi.string(),
      status: Joi.string().valid(...Object.values(MaintenanceOrderStatus)),
      technicianId: Joi.number().integer().allow(null)
    })
    .min(1)
};

const deleteMaintenanceOrder = {
  params: Joi.object().keys({
    orderId: Joi.number().integer().required()
  })
};

export default {
  createMaintenanceOrder,
  getMaintenanceOrders,
  getMaintenanceOrder,
  updateMaintenanceOrder,
  deleteMaintenanceOrder
};