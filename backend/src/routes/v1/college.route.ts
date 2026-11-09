import express from 'express';
import auth from '../../middlewares/auth';
import validate from '../../middlewares/validate';
import { collegeValidation } from '../../validations';
import { collegeController } from '../../controllers';

const router = express.Router();

router
  .route('/')
  .post(auth('manageColleges'), validate(collegeValidation.createCollege), collegeController.createCollege)
  .get(auth('viewDevices'), validate(collegeValidation.getColleges), collegeController.getColleges);

router
  .route('/:collegeId')
  .get(auth('viewDevices'), validate(collegeValidation.getCollege), collegeController.getCollege)
  .patch(auth('manageColleges'), validate(collegeValidation.updateCollege), collegeController.updateCollege)
  .delete(auth('manageColleges'), validate(collegeValidation.deleteCollege), collegeController.deleteCollege);

export default router;