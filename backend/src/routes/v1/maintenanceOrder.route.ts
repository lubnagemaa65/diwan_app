import express from 'express';
import auth from '../../middlewares/auth';
import validate from '../../middlewares/validate';
import { maintenanceOrderValidation } from '../../validations';
import { maintenanceOrderController } from '../../controllers';

const router = express.Router();

router
  .route('/')
  .post(
    auth('submitMaintenanceRequest'),
    validate(maintenanceOrderValidation.createMaintenanceOrder),
    maintenanceOrderController.createMaintenanceOrder
  )
  .get(
    auth('submitMaintenanceRequest'),
    validate(maintenanceOrderValidation.getMaintenanceOrders),
    maintenanceOrderController.getMaintenanceOrders
  );

router.get(
  '/:orderId/triage-suggestion',
  auth('viewDevices'),
  maintenanceOrderController.getTriageSuggestion
);

router
  .route('/:orderId')
  .get(
    auth('viewDevices'),
    validate(maintenanceOrderValidation.getMaintenanceOrder),
    maintenanceOrderController.getMaintenanceOrder
  )
  .patch(
    auth('manageMaintenanceOrders'),
    validate(maintenanceOrderValidation.updateMaintenanceOrder),
    maintenanceOrderController.updateMaintenanceOrder
  )
  .delete(
    auth('manageMaintenanceOrders'),
    validate(maintenanceOrderValidation.deleteMaintenanceOrder),
    maintenanceOrderController.deleteMaintenanceOrder
  );
  

export default router;