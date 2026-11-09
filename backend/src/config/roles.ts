import { Role } from '@prisma/client';

const allRoles = {
  [Role.EMPLOYEE]: ['viewOwnDevices', 'submitMaintenanceRequest'],
  [Role.TECHNICIAN]: [
    'viewDevices',
    'manageMaintenanceOrders',
    'submitMaintenanceRequest',
    'updateDeviceStatus'
  ],
  [Role.ADMIN]: [
    'manageUsers',
    'getUsers',
    'manageColleges',
    'manageEmployees',
    'manageDevices',
    'viewDevices',
    'manageMaintenanceOrders',
    'submitMaintenanceRequest',
    'updateDeviceStatus'
  ]
};

export const roles = Object.keys(allRoles);
export const roleRights = new Map(Object.entries(allRoles));