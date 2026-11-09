import express from 'express';
import authRoute from './auth.route';
import userRoute from './user.route';
import collegeRoute from './college.route';
import employeeRoute from './employee.route';
import computerRoute from './computer.route';
import printerRoute from './printer.route';
import maintenanceOrderRoute from './maintenanceOrder.route';
import docsRoute from './docs.route';
import config from '../../config/config';
import activityLogRoute from './activityLog.route';

const router = express.Router();

const defaultRoutes = [
  {
    path: '/auth',
    route: authRoute
  },
  {
    path: '/users',
    route: userRoute
  },
  {
    path: '/colleges',
    route: collegeRoute
  },
  {
    path: '/employees',
    route: employeeRoute
  },
  {
  path: '/computers',
  route: computerRoute
},
{
  path: '/printers',
  route: printerRoute
},
{
  path: '/maintenance-orders',
  route: maintenanceOrderRoute
},
{
  path: '/activity-logs',
  route: activityLogRoute
}
];

const devRoutes = [
  // routes available only in development mode
  {
    path: '/docs',
    route: docsRoute
  }
];

defaultRoutes.forEach((route) => {
  router.use(route.path, route.route);
});

/* istanbul ignore next */
if (config.env === 'development') {
  devRoutes.forEach((route) => {
    router.use(route.path, route.route);
  });
}

export default router;