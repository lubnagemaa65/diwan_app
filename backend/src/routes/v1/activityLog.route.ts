import express from 'express';
import auth from '../../middlewares/auth';
import validate from '../../middlewares/validate';
import { activityLogValidation } from '../../validations';
import { activityLogController } from '../../controllers';

const router = express.Router();

router.get(
  '/',
  auth('manageUsers'),
  validate(activityLogValidation.getActivityLogs),
  activityLogController.getActivityLogs
);

export default router;