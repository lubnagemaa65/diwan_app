import Joi from 'joi';
import { ComputerType, DiskType, GraphicsCardType, DeviceStatus } from '@prisma/client';

const createComputer = {
  body: Joi.object().keys({
    type: Joi.string().valid(...Object.values(ComputerType)).required(),
    processor: Joi.string().required(),
    motherboard: Joi.string().required(),
    hardDiskType: Joi.string().valid(...Object.values(DiskType)).required(),
    hardDiskSpace: Joi.string().required(),
    ramType: Joi.string().required(),
    graphicsCard: Joi.string().valid(...Object.values(GraphicsCardType)).required(),
    status: Joi.string().valid(...Object.values(DeviceStatus)),
    collegeId: Joi.number().integer().required(),
    employeeId: Joi.number().integer().allow(null)
  })
};

const getComputers = {
  query: Joi.object().keys({
    id: Joi.string(),
    collegeId: Joi.number().integer(),
    employeeId: Joi.number().integer(),
    status: Joi.string().valid(...Object.values(DeviceStatus)),
    type: Joi.string().valid(...Object.values(ComputerType)),
    sortBy: Joi.string(),
    limit: Joi.number().integer(),
    page: Joi.number().integer()
  })
};

const getComputer = {
  params: Joi.object().keys({
    computerId: Joi.string().required()
  })
};

const updateComputer = {
  params: Joi.object().keys({
    computerId: Joi.string().required()
  }),
  body: Joi.object()
    .keys({
      type: Joi.string().valid(...Object.values(ComputerType)),
      processor: Joi.string(),
      motherboard: Joi.string(),
      hardDiskType: Joi.string().valid(...Object.values(DiskType)),
      hardDiskSpace: Joi.string(),
      ramType: Joi.string(),
      graphicsCard: Joi.string().valid(...Object.values(GraphicsCardType)),
      status: Joi.string().valid(...Object.values(DeviceStatus)),
      employeeId: Joi.number().integer().allow(null)
    })
    .min(1)
};

const deleteComputer = {
  params: Joi.object().keys({
    computerId: Joi.string().required()
  })
};

export default {
  createComputer,
  getComputers,
  getComputer,
  updateComputer,
  deleteComputer
};