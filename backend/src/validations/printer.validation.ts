import Joi from 'joi';
import { DeviceStatus } from '@prisma/client';

const createPrinter = {
  body: Joi.object().keys({
    type: Joi.string().required(),
    status: Joi.string().valid(...Object.values(DeviceStatus)),
    collegeId: Joi.number().integer().required()
  })
};

const getPrinters = {
  query: Joi.object().keys({
    id: Joi.string(),
    collegeId: Joi.number().integer(),
    status: Joi.string().valid(...Object.values(DeviceStatus)),
    sortBy: Joi.string(),
    limit: Joi.number().integer(),
    page: Joi.number().integer()
  })
};

const getPrinter = {
  params: Joi.object().keys({
    printerId: Joi.string().required()
  })
};

const updatePrinter = {
  params: Joi.object().keys({
    printerId: Joi.string().required()
  }),
  body: Joi.object()
    .keys({
      type: Joi.string(),
      status: Joi.string().valid(...Object.values(DeviceStatus))
    })
    .min(1)
};

const deletePrinter = {
  params: Joi.object().keys({
    printerId: Joi.string().required()
  })
};

export default {
  createPrinter,
  getPrinters,
  getPrinter,
  updatePrinter,
  deletePrinter
};