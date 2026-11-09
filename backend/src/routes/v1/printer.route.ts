import express from 'express';
import auth from '../../middlewares/auth';
import validate from '../../middlewares/validate';
import { printerValidation } from '../../validations';
import { printerController } from '../../controllers';

const router = express.Router();

router
  .route('/')
  .post(auth('manageDevices'), validate(printerValidation.createPrinter), printerController.createPrinter)
  .get(auth('viewDevices'), validate(printerValidation.getPrinters), printerController.getPrinters);

router
  .route('/:printerId')
  .get(auth('viewDevices'), validate(printerValidation.getPrinter), printerController.getPrinter)
  .patch(auth('manageDevices'), validate(printerValidation.updatePrinter), printerController.updatePrinter)
  .delete(auth('manageDevices'), validate(printerValidation.deletePrinter), printerController.deletePrinter);

export default router;