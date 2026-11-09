import express from 'express';
import auth from '../../middlewares/auth';
import validate from '../../middlewares/validate';
import { computerValidation } from '../../validations';
import { computerController } from '../../controllers';

const router = express.Router();

router
  .route('/')
  .post(auth('manageDevices'), validate(computerValidation.createComputer), computerController.createComputer)
  .get(auth('viewDevices'), validate(computerValidation.getComputers), computerController.getComputers);

router
  .route('/:computerId')
  .get(auth('viewDevices'), validate(computerValidation.getComputer), computerController.getComputer)
  .patch(auth('manageDevices'), validate(computerValidation.updateComputer), computerController.updateComputer)
  .delete(auth('manageDevices'), validate(computerValidation.deleteComputer), computerController.deleteComputer);

export default router;