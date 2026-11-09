import Joi from 'joi';

const createEmployee = {
  body: Joi.object().keys({
    firstName: Joi.string().required(),
    fatherName: Joi.string().required(),
    lastName: Joi.string().required(),
    userId: Joi.number().integer().required(),
    collegeId: Joi.number().integer().required()
  })
};

const getEmployees = {
  query: Joi.object().keys({
    collegeId: Joi.number().integer(),
    sortBy: Joi.string(),
    limit: Joi.number().integer(),
    page: Joi.number().integer()
  })
};

const getEmployee = {
  params: Joi.object().keys({
    employeeId: Joi.number().integer().required()
  })
};

const updateEmployee = {
  params: Joi.object().keys({
    employeeId: Joi.number().integer().required()
  }),
  body: Joi.object()
    .keys({
      firstName: Joi.string(),
      fatherName: Joi.string(),
      lastName: Joi.string(),
      collegeId: Joi.number().integer()
    })
    .min(1)
};

const deleteEmployee = {
  params: Joi.object().keys({
    employeeId: Joi.number().integer().required()
  })
};

export default {
  createEmployee,
  getEmployees,
  getEmployee,
  updateEmployee,
  deleteEmployee
};