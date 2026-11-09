import express from 'express';
import auth from '../../middlewares/auth';
import validate from '../../middlewares/validate';
import { employeeValidation } from '../../validations';
import { employeeController } from '../../controllers';

const router = express.Router();

router
  .route('/')
  .post(auth('manageEmployees'), validate(employeeValidation.createEmployee), employeeController.createEmployee)
  .get(auth('viewDevices'), validate(employeeValidation.getEmployees), employeeController.getEmployees);

router
  .route('/:employeeId')
  .get(auth('viewDevices'), validate(employeeValidation.getEmployee), employeeController.getEmployee)
  .patch(auth('manageEmployees'), validate(employeeValidation.updateEmployee), employeeController.updateEmployee)
  .delete(auth('manageEmployees'), validate(employeeValidation.deleteEmployee), employeeController.deleteEmployee);

export default router;