import Joi from 'joi';

const createCollege = {
  body: Joi.object().keys({
    name: Joi.string().required()
  })
};

const getColleges = {
  query: Joi.object().keys({
    name: Joi.string(),
    sortBy: Joi.string(),
    limit: Joi.number().integer(),
    page: Joi.number().integer()
  })
};

const getCollege = {
  params: Joi.object().keys({
    collegeId: Joi.number().integer().required()
  })
};

const updateCollege = {
  params: Joi.object().keys({
    collegeId: Joi.number().integer().required()
  }),
  body: Joi.object()
    .keys({
      name: Joi.string()
    })
    .min(1)
};

const deleteCollege = {
  params: Joi.object().keys({
    collegeId: Joi.number().integer().required()
  })
};

export default {
  createCollege,
  getColleges,
  getCollege,
  updateCollege,
  deleteCollege
};