import Joi from 'joi';

const getActivityLogs = {
  query: Joi.object().keys({
    userId: Joi.number().integer(),
    sortBy: Joi.string(),
    limit: Joi.number().integer(),
    page: Joi.number().integer()
  })
};

export default {
  getActivityLogs
};