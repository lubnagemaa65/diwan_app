import request from 'supertest';
import bcrypt from 'bcryptjs';
import { randomBytes } from 'crypto';
import { afterAll, beforeAll, describe, expect, test } from '@jest/globals';
import { PrismaClient, Role } from '@prisma/client';

// Never import the app/client until the exact dedicated database has been confirmed.
const TEST_DATABASE_URL = 'postgresql://diwan_test:diwan_test_local@localhost:5432/diwan_test?schema=public';
if (process.env.DATABASE_URL !== TEST_DATABASE_URL || process.env.NODE_ENV !== 'test' || process.env.JWT_SECRET !== 'test_secret') {
  throw new Error('Refusing to run: DATABASE_URL, NODE_ENV or JWT_SECRET is not the dedicated test configuration');
}
const app = require('../../src/app').default;
const prisma: PrismaClient = require('../../src/client').default;

const runId = randomBytes(12).toString('hex');
const prefix = `diwan-it-${runId}`;
const password = 'TestPassword123';
const emails = {
  admin: `${prefix}-admin@example.com`,
  technician: `${prefix}-tech@example.com`,
  employee: `${prefix}-employee@example.com`,
  other: `${prefix}-other@example.com`,
  crud: `${prefix}-crud@example.com`,
  api: `${prefix}-api@example.com`
};
const fixtureCollegeName = `${prefix}-fixture-college`;
const apiCollegeName = `${prefix}-api-college`;
const updatedCollegeName = `${prefix}-updated-college`;
const fixtureComputerId = `${prefix}-fixture-pc`;

let adminId: number;
let technicianId: number;
let employeeUserId: number;
let otherUserId: number;
let crudUserId: number;
let fixtureCollegeId: number;
let employeeId: number;
let otherEmployeeId: number;
let adminToken: string;
let techToken: string;
let employeeToken: string;
let otherToken: string;
let otherRefresh: string;

// A log is emitted only after the HTTP status and body/database assertions pass.
async function step<T>(name: string, operation: () => Promise<T>): Promise<T> {
  try {
    const result = await operation();
    console.log(`PASS ${name}`);
    return result;
  } catch (error) {
    console.error(`FAIL ${name}`);
    throw error;
  }
}

function bearer(token: string): string {
  return `Bearer ${token}`;
}

async function login(email: string, expectedRole: Role): Promise<{ access: string; refresh: string }> {
  return step(`login ${expectedRole} (${email.split('@')[0].split('-').pop()})`, async () => {
    const res = await request(app).post('/v1/auth/login').send({ email, password });
    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({ email, role: expectedRole });
    expect(res.body.user).not.toHaveProperty('password');
    expect(res.body.tokens.access.token).toEqual(expect.any(String));
    expect(res.body.tokens.refresh.token).toEqual(expect.any(String));
    return { access: res.body.tokens.access.token, refresh: res.body.tokens.refresh.token };
  });
}

describe('Diwan real PostgreSQL integration flows', () => {
  beforeAll(async () => {
    const hash = await bcrypt.hash(password, 8);
    const admin = await prisma.user.create({ data: { email: emails.admin, name: `${prefix}-admin`, password: hash, role: Role.ADMIN } });
    adminId = admin.id;
    const tech = await prisma.user.create({ data: { email: emails.technician, name: `${prefix}-tech`, password: hash, role: Role.TECHNICIAN } });
    technicianId = tech.id;
    const employee = await prisma.user.create({ data: { email: emails.employee, name: `${prefix}-employee`, password: hash, role: Role.EMPLOYEE } });
    employeeUserId = employee.id;
    const other = await prisma.user.create({ data: { email: emails.other, name: `${prefix}-other`, password: hash, role: Role.EMPLOYEE } });
    otherUserId = other.id;
    const crud = await prisma.user.create({ data: { email: emails.crud, name: `${prefix}-crud`, password: hash, role: Role.EMPLOYEE } });
    crudUserId = crud.id;
    const college = await prisma.college.create({ data: { name: fixtureCollegeName } });
    fixtureCollegeId = college.id;
    const employeeRecord = await prisma.employee.create({ data: { firstName: 'Test', fatherName: 'Fixture', lastName: 'Employee', userId: employeeUserId, collegeId: fixtureCollegeId } });
    employeeId = employeeRecord.id;
    const otherRecord = await prisma.employee.create({ data: { firstName: 'Other', fatherName: 'Fixture', lastName: 'Employee', userId: otherUserId, collegeId: fixtureCollegeId } });
    otherEmployeeId = otherRecord.id;
    await prisma.computer.create({ data: { id: fixtureComputerId, type: 'DESKTOP', processor: 'Test CPU', motherboard: 'Test board', hardDiskType: 'SATA', hardDiskSpace: '256GB', ramType: 'DDR4', graphicsCard: 'INTEGRATED', collegeId: fixtureCollegeId, employeeId } });
    adminToken = (await login(emails.admin, Role.ADMIN)).access;
    techToken = (await login(emails.technician, Role.TECHNICIAN)).access;
    employeeToken = (await login(emails.employee, Role.EMPLOYEE)).access;
    const otherSession = await login(emails.other, Role.EMPLOYEE);
    otherToken = otherSession.access;
    otherRefresh = otherSession.refresh;
  });

  afterAll(async () => {
    try {
      // Recover by run-specific exact names/emails even if setup or an HTTP step failed.
      // No table-wide deletes, migrations, schema resets, or foreign fixture IDs.
      const users = await prisma.user.findMany({ where: { email: { in: Object.values(emails) } }, select: { id: true } });
      const userIds = users.map((user) => user.id);
      const colleges = await prisma.college.findMany({ where: { name: { in: [fixtureCollegeName, apiCollegeName, updatedCollegeName] } }, select: { id: true } });
      const collegeIds = colleges.map((college) => college.id);
      const employees = await prisma.employee.findMany({ where: { userId: { in: userIds } }, select: { id: true } });
      const employeeIds = employees.map((employee) => employee.id);
      const computers = await prisma.computer.findMany({ where: { collegeId: { in: collegeIds } }, select: { id: true } });
      const computerIds = computers.map((computer) => computer.id);
      const printers = await prisma.printer.findMany({ where: { collegeId: { in: collegeIds } }, select: { id: true } });
      const printerIds = printers.map((printer) => printer.id);
      await prisma.$transaction([
        // If an unrelated record points at our fixtures, FK checks fail rather than deleting it.
        prisma.maintenanceOrder.deleteMany({ where: { requestedById: { in: employeeIds } } }),
        prisma.computer.deleteMany({ where: { id: { in: computerIds } } }),
        prisma.printer.deleteMany({ where: { id: { in: printerIds } } }),
        prisma.employee.deleteMany({ where: { id: { in: employeeIds } } }),
        prisma.token.deleteMany({ where: { userId: { in: userIds } } }),
        prisma.activityLog.deleteMany({ where: { userId: { in: userIds } } }),
        prisma.user.deleteMany({ where: { id: { in: userIds } } }),
        prisma.college.deleteMany({ where: { id: { in: collegeIds } } })
      ]);
      const remainingUsers = await prisma.user.count({ where: { email: { in: Object.values(emails) } } });
      const remainingColleges = await prisma.college.count({ where: { name: { in: [fixtureCollegeName, apiCollegeName, updatedCollegeName] } } });
      expect(remainingUsers).toBe(0);
      expect(remainingColleges).toBe(0);
      console.log('PASS cleanup: run-specific records removed');
    } catch (error) {
      console.error('FAIL cleanup: run-specific records may remain');
      throw error;
    } finally {
      await prisma.$disconnect();
    }
  });

  test('authentication and role boundaries', async () => {
    await step('login rejects wrong password', async () => {
      const res = await request(app).post('/v1/auth/login').send({ email: emails.admin, password: 'WrongPassword123' });
      expect(res.status).toBe(401);
    });
    await step('login rejects unknown account', async () => {
      const res = await request(app).post('/v1/auth/login').send({ email: `${prefix}-missing@example.com`, password });
      expect(res.status).toBe(401);
    });
    await step('login validation rejects missing password', async () => {
      const res = await request(app).post('/v1/auth/login').send({ email: emails.admin });
      expect(res.status).toBe(400);
    });
    await step('protected route rejects missing bearer', async () => {
      expect((await request(app).get('/v1/users')).status).toBe(401);
    });
    await step('protected route rejects invalid bearer', async () => {
      expect((await request(app).get('/v1/users').set('Authorization', bearer('not-a-jwt'))).status).toBe(401);
    });
    await step('protected route rejects refresh token as access token', async () => {
      expect((await request(app).get('/v1/maintenance-orders').set('Authorization', bearer(otherRefresh))).status).toBe(401);
    });
    await step('admin may list users', async () => {
      const res = await request(app).get('/v1/users').query({ name: `${prefix}-admin` }).set('Authorization', bearer(adminToken));
      expect(res.status).toBe(200);
      expect(res.body).toEqual(expect.arrayContaining([expect.objectContaining({ id: adminId, role: 'ADMIN' })]));
    });
    await step('technician and employee cannot list users', async () => {
      for (const token of [techToken, employeeToken]) expect((await request(app).get('/v1/users').set('Authorization', bearer(token))).status).toBe(403);
    });
    await step('technician can view college but cannot create one', async () => {
      expect((await request(app).get(`/v1/colleges/${fixtureCollegeId}`).set('Authorization', bearer(techToken))).status).toBe(200);
      expect((await request(app).post('/v1/colleges').set('Authorization', bearer(techToken)).send({ name: `${prefix}-forbidden` })).status).toBe(403);
      expect(await prisma.college.count({ where: { name: `${prefix}-forbidden` } })).toBe(0);
    });
    await step('employee is denied the general computer route', async () => {
      expect((await request(app).get(`/v1/computers/${fixtureComputerId}`).set('Authorization', bearer(employeeToken))).status).toBe(403);
    });
  });

  test('employee can read own profile but not another user profile', async () => {
    await step('employee cannot read another user profile', async () => {
      expect((await request(app).get(`/v1/users/${otherUserId}`).set('Authorization', bearer(employeeToken))).status).toBe(403);
    });
    // The route's Swagger contract explicitly permits a user to read their own profile.
    await step('employee can read own profile', async () => {
      const res = await request(app).get(`/v1/users/${employeeUserId}`).set('Authorization', bearer(employeeToken));
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ id: employeeUserId, email: emails.employee });
      expect(res.body).not.toHaveProperty('password');
    });
    await step('own profile access does not grant user management', async () => {
      const patch = await request(app).patch(`/v1/users/${employeeUserId}`).set('Authorization', bearer(employeeToken)).send({ name: 'Unauthorized change' });
      const del = await request(app).delete(`/v1/users/${employeeUserId}`).set('Authorization', bearer(employeeToken));
      expect(patch.status).toBe(403);
      expect(del.status).toBe(403);
    });
  });

  test('password reset persists a usable, hashed password', async () => {
    // Generate the normal reset token via the service; no mail server is required.
    const tokenService = require('../../src/services/token.service').default;
    const token: string = await tokenService.generateResetPasswordToken(emails.crud);
    await step('password reset then login with the reset password', async () => {
      const newPassword = 'ResetTestPassword789';
      const res = await request(app).post('/v1/auth/reset-password').query({ token }).send({ password: newPassword });
      expect(res.status).toBe(204);
      const stored = await prisma.user.findUnique({ where: { id: crudUserId } });
      expect(stored).not.toBeNull();
      expect(stored!.password).not.toBe(newPassword);
      expect(await bcrypt.compare(newPassword, stored!.password)).toBe(true);
      expect((await request(app).post('/v1/auth/login').send({ email: emails.crud, password })).status).toBe(401);
      expect((await request(app).post('/v1/auth/login').send({ email: emails.crud, password: newPassword })).status).toBe(200);
    });
  });

  test('user CRUD and duplicate validation', async () => {
    let id = 0;
    await step('blocked user delete preserves existing session tokens', async () => {
      const before = await prisma.token.count({ where: { userId: employeeUserId } });
      expect(before).toBeGreaterThan(0);
      const res = await request(app).delete(`/v1/users/${employeeUserId}`).set('Authorization', bearer(adminToken));
      expect(res.status).not.toBe(204);
      expect(await prisma.user.findUnique({ where: { id: employeeUserId } })).not.toBeNull();
      expect(await prisma.token.count({ where: { userId: employeeUserId } })).toBe(before);
    });
    await step('user CREATE', async () => {
      const res = await request(app).post('/v1/users').set('Authorization', bearer(adminToken)).send({ email: emails.api, password, name: `${prefix}-api`, role: 'EMPLOYEE' });
      expect(res.status).toBe(201);
      expect(res.body).toMatchObject({ email: emails.api, role: 'EMPLOYEE' });
      expect(res.body).not.toHaveProperty('password');
      id = res.body.id;
      expect(id).toEqual(expect.any(Number));
    });
    await step('user duplicate email is rejected', async () => {
      const res = await request(app).post('/v1/users').set('Authorization', bearer(adminToken)).send({ email: emails.api, password, name: `${prefix}-api`, role: 'EMPLOYEE' });
      expect(res.status).toBe(400);
    });
    await step('user READ', async () => {
      const res = await request(app).get(`/v1/users/${id}`).set('Authorization', bearer(adminToken));
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ id, email: emails.api });
      expect(res.body).not.toHaveProperty('password');
    });
    await step('user UPDATE', async () => {
      const res = await request(app).patch(`/v1/users/${id}`).set('Authorization', bearer(adminToken)).send({ name: `${prefix}-api-updated` });
      expect(res.status).toBe(200);
      expect(res.body.name).toBe(`${prefix}-api-updated`);
      expect((await prisma.user.findUnique({ where: { id } }))?.name).toBe(`${prefix}-api-updated`);
    });
    await step('user password UPDATE hashes password and permits only the new login', async () => {
      const newPassword = 'NewTestPassword456';
      const res = await request(app).patch(`/v1/users/${id}`).set('Authorization', bearer(adminToken)).send({ password: newPassword });
      expect(res.status).toBe(200);
      expect(res.body).not.toHaveProperty('password');
      const stored = await prisma.user.findUnique({ where: { id } });
      expect(stored).not.toBeNull();
      expect(stored!.password).not.toBe(newPassword);
      expect(await bcrypt.compare(newPassword, stored!.password)).toBe(true);
      expect((await request(app).post('/v1/auth/login').send({ email: emails.api, password })).status).toBe(401);
      const newLogin = await request(app).post('/v1/auth/login').send({ email: emails.api, password: newPassword });
      expect(newLogin.status).toBe(200);
      expect(newLogin.body.user.id).toBe(id);
      expect(newLogin.body.user).not.toHaveProperty('password');
      expect(newLogin.body.tokens.access.token).toEqual(expect.any(String));
    });
    await step('user DELETE and 404 after deletion', async () => {
      expect((await request(app).delete(`/v1/users/${id}`).set('Authorization', bearer(adminToken))).status).toBe(204);
      expect((await request(app).get(`/v1/users/${id}`).set('Authorization', bearer(adminToken))).status).toBe(404);
    });
  });

  test('college CRUD and input validation', async () => {
    let id = 0;
    await step('college rejects missing name', async () => {
      expect((await request(app).post('/v1/colleges').set('Authorization', bearer(adminToken)).send({})).status).toBe(400);
    });
    await step('college CREATE', async () => {
      const res = await request(app).post('/v1/colleges').set('Authorization', bearer(adminToken)).send({ name: apiCollegeName });
      expect(res.status).toBe(201);
      expect(res.body.name).toBe(apiCollegeName);
      id = res.body.id;
      expect(id).toEqual(expect.any(Number));
    });
    await step('college READ and LIST', async () => {
      const one = await request(app).get(`/v1/colleges/${id}`).set('Authorization', bearer(adminToken));
      const list = await request(app).get('/v1/colleges').query({ name: apiCollegeName }).set('Authorization', bearer(adminToken));
      expect(one.status).toBe(200);
      expect(one.body).toMatchObject({ id, name: apiCollegeName });
      expect(list.status).toBe(200);
      expect(list.body).toEqual(expect.arrayContaining([expect.objectContaining({ id })]));
    });
    await step('college UPDATE', async () => {
      const res = await request(app).patch(`/v1/colleges/${id}`).set('Authorization', bearer(adminToken)).send({ name: updatedCollegeName });
      expect(res.status).toBe(200);
      expect(res.body.name).toBe(updatedCollegeName);
      expect((await prisma.college.findUnique({ where: { id } }))?.name).toBe(updatedCollegeName);
    });
    await step('college DELETE and 404 after deletion', async () => {
      expect((await request(app).delete(`/v1/colleges/${id}`).set('Authorization', bearer(adminToken))).status).toBe(204);
      expect((await request(app).get(`/v1/colleges/${id}`).set('Authorization', bearer(adminToken))).status).toBe(404);
    });
  });

  test('employee CRUD', async () => {
    let id = 0;
    await step('employee CREATE', async () => {
      const res = await request(app).post('/v1/employees').set('Authorization', bearer(adminToken)).send({ firstName: 'Synthetic', fatherName: 'Test', lastName: 'Employee', userId: crudUserId, collegeId: fixtureCollegeId });
      expect(res.status).toBe(201);
      expect(res.body).toMatchObject({ userId: crudUserId, collegeId: fixtureCollegeId });
      id = res.body.id;
    });
    await step('employee duplicate user link is rejected', async () => {
      const res = await request(app).post('/v1/employees').set('Authorization', bearer(adminToken)).send({ firstName: 'Synthetic', fatherName: 'Test', lastName: 'Employee', userId: crudUserId, collegeId: fixtureCollegeId });
      expect(res.status).toBe(400);
    });
    await step('employee READ and LIST', async () => {
      const one = await request(app).get(`/v1/employees/${id}`).set('Authorization', bearer(techToken));
      const list = await request(app).get('/v1/employees').query({ collegeId: fixtureCollegeId }).set('Authorization', bearer(adminToken));
      expect(one.status).toBe(200);
      expect(one.body).toMatchObject({ id, userId: crudUserId });
      expect(list.status).toBe(200);
      expect(list.body).toEqual(expect.arrayContaining([expect.objectContaining({ id })]));
    });
    await step('employee UPDATE', async () => {
      const res = await request(app).patch(`/v1/employees/${id}`).set('Authorization', bearer(adminToken)).send({ firstName: 'Updated' });
      expect(res.status).toBe(200);
      expect(res.body.firstName).toBe('Updated');
      expect((await prisma.employee.findUnique({ where: { id } }))?.firstName).toBe('Updated');
    });
    await step('employee DELETE and 404 after deletion', async () => {
      expect((await request(app).delete(`/v1/employees/${id}`).set('Authorization', bearer(adminToken))).status).toBe(204);
      expect((await request(app).get(`/v1/employees/${id}`).set('Authorization', bearer(adminToken))).status).toBe(404);
    });
  });

  test('computer CRUD and role/enum validation', async () => {
    let id = '';
    const body = { type: 'LAPTOP', processor: 'Synthetic CPU', motherboard: 'Synthetic board', hardDiskType: 'SATA', hardDiskSpace: '512GB', ramType: 'DDR4', graphicsCard: 'INTEGRATED', collegeId: fixtureCollegeId, employeeId };
    await step('computer invalid enum is rejected', async () => {
      expect((await request(app).post('/v1/computers').set('Authorization', bearer(adminToken)).send({ ...body, type: 'INVALID' })).status).toBe(400);
    });
    await step('technician cannot create a computer', async () => {
      expect((await request(app).post('/v1/computers').set('Authorization', bearer(techToken)).send(body)).status).toBe(403);
    });
    await step('computer CREATE', async () => {
      const res = await request(app).post('/v1/computers').set('Authorization', bearer(adminToken)).send(body);
      expect(res.status).toBe(201);
      expect(res.body).toMatchObject({ type: 'LAPTOP', collegeId: fixtureCollegeId, employeeId });
      id = res.body.id;
      expect(id).toEqual(expect.any(String));
    });
    await step('computer READ and LIST as technician', async () => {
      const one = await request(app).get(`/v1/computers/${id}`).set('Authorization', bearer(techToken));
      const list = await request(app).get('/v1/computers').query({ id }).set('Authorization', bearer(techToken));
      expect(one.status).toBe(200);
      expect(one.body).toMatchObject({ id, collegeId: fixtureCollegeId });
      expect(list.status).toBe(200);
      expect(list.body).toEqual(expect.arrayContaining([expect.objectContaining({ id })]));
    });
    await step('computer UPDATE', async () => {
      const res = await request(app).patch(`/v1/computers/${id}`).set('Authorization', bearer(adminToken)).send({ status: 'MAINTENANCE' });
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('MAINTENANCE');
      expect((await prisma.computer.findUnique({ where: { id } }))?.status).toBe('MAINTENANCE');
    });
    await step('computer DELETE and 404 after deletion', async () => {
      expect((await request(app).delete(`/v1/computers/${id}`).set('Authorization', bearer(adminToken))).status).toBe(204);
      expect((await request(app).get(`/v1/computers/${id}`).set('Authorization', bearer(adminToken))).status).toBe(404);
    });
  });

  test('printer CRUD', async () => {
    let id = '';
    await step('printer CREATE', async () => {
      const res = await request(app).post('/v1/printers').set('Authorization', bearer(adminToken)).send({ type: 'Synthetic laser', collegeId: fixtureCollegeId });
      expect(res.status).toBe(201);
      expect(res.body).toMatchObject({ type: 'Synthetic laser', collegeId: fixtureCollegeId });
      id = res.body.id;
      expect(id).toEqual(expect.any(String));
    });
    await step('printer READ and LIST', async () => {
      const one = await request(app).get(`/v1/printers/${id}`).set('Authorization', bearer(techToken));
      const list = await request(app).get('/v1/printers').query({ id }).set('Authorization', bearer(adminToken));
      expect(one.status).toBe(200);
      expect(one.body).toMatchObject({ id, collegeId: fixtureCollegeId });
      expect(list.status).toBe(200);
      expect(list.body).toEqual(expect.arrayContaining([expect.objectContaining({ id })]));
    });
    await step('printer UPDATE', async () => {
      const res = await request(app).patch(`/v1/printers/${id}`).set('Authorization', bearer(adminToken)).send({ status: 'DISABLED' });
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('DISABLED');
      expect((await prisma.printer.findUnique({ where: { id } }))?.status).toBe('DISABLED');
    });
    await step('printer DELETE and 404 after deletion', async () => {
      expect((await request(app).delete(`/v1/printers/${id}`).set('Authorization', bearer(adminToken))).status).toBe(204);
      expect((await request(app).get(`/v1/printers/${id}`).set('Authorization', bearer(adminToken))).status).toBe(404);
    });
  });

  for (const device of [
    {
      kind: 'computer',
      route: '/v1/computers',
      body: () => ({ type: 'DESKTOP', processor: 'Regression CPU', motherboard: 'Regression board', hardDiskType: 'SATA', hardDiskSpace: '256GB', ramType: 'DDR4', graphicsCard: 'INTEGRATED', collegeId: fixtureCollegeId })
    },
    { kind: 'printer', route: '/v1/printers', body: () => ({ type: 'Regression printer', collegeId: fixtureCollegeId }) }
  ]) {
    test(`${device.kind} IDs remain unique after deletion and concurrent creation`, async () => {
      const createdIds: string[] = [];
      await step(`${device.kind} create three initial devices`, async () => {
        for (let i = 0; i < 3; i += 1) {
          const res = await request(app).post(device.route).set('Authorization', bearer(adminToken)).send(device.body());
          expect(res.status).toBe(201);
          expect(res.body.id).toEqual(expect.any(String));
          createdIds.push(res.body.id);
        }
        expect(new Set(createdIds).size).toBe(3);
      });
      await step(`${device.kind} delete middle device then create without ID collision`, async () => {
        const removed = createdIds[1];
        expect((await request(app).delete(`${device.route}/${removed}`).set('Authorization', bearer(adminToken))).status).toBe(204);
        const res = await request(app).post(device.route).set('Authorization', bearer(adminToken)).send(device.body());
        expect(res.status).toBe(201);
        expect(res.body.id).toEqual(expect.any(String));
        expect([createdIds[0], createdIds[2]]).not.toContain(res.body.id);
        createdIds.splice(1, 1);
        createdIds.push(res.body.id);
      });
      await step(`${device.kind} two simultaneous creates both succeed with distinct IDs`, async () => {
        const responses = await Promise.all([
          request(app).post(device.route).set('Authorization', bearer(adminToken)).send(device.body()),
          request(app).post(device.route).set('Authorization', bearer(adminToken)).send(device.body())
        ]);
        for (const res of responses) {
          expect(res.status).toBe(201);
          expect(res.body.id).toEqual(expect.any(String));
          expect(createdIds).not.toContain(res.body.id);
        }
        expect(responses[0].body.id).not.toBe(responses[1].body.id);
        createdIds.push(...responses.map((res) => res.body.id));
      });
      await step(`${device.kind} delete regression devices`, async () => {
        for (const id of createdIds) {
          expect((await request(app).delete(`${device.route}/${id}`).set('Authorization', bearer(adminToken))).status).toBe(204);
        }
      });
    });
  }

  test('maintenance CRUD, scoped listing, and technician permissions', async () => {
    let id = 0;
    let otherOrderId = 0;
    await step('maintenance rejects absent device', async () => {
      const res = await request(app).post('/v1/maintenance-orders').set('Authorization', bearer(employeeToken)).send({ type: 'SOFTWARE', problemDescription: 'Synthetic problem' });
      expect(res.status).toBe(400);
    });
    await step('maintenance CREATE for employee overrides supplied requester', async () => {
      const res = await request(app).post('/v1/maintenance-orders').set('Authorization', bearer(employeeToken)).send({ type: 'SOFTWARE', problemDescription: `${prefix}-own`, computerId: fixtureComputerId, requestedById: otherEmployeeId });
      expect(res.status).toBe(201);
      expect(res.body).toMatchObject({ requestedById: employeeId, computerId: fixtureComputerId, status: 'PENDING' });
      id = res.body.id;
    });
    await step('maintenance CREATE for another employee as admin', async () => {
      const res = await request(app).post('/v1/maintenance-orders').set('Authorization', bearer(adminToken)).send({ type: 'HARDWARE', problemDescription: `${prefix}-other`, computerId: fixtureComputerId, requestedById: otherEmployeeId });
      expect(res.status).toBe(201);
      expect(res.body.requestedById).toBe(otherEmployeeId);
      otherOrderId = res.body.id;
    });
    await step('maintenance employee LIST is scoped even with another requester filter', async () => {
      const own = await request(app).get('/v1/maintenance-orders').set('Authorization', bearer(employeeToken));
      const attempted = await request(app).get('/v1/maintenance-orders').query({ requestedById: otherEmployeeId }).set('Authorization', bearer(employeeToken));
      const other = await request(app).get('/v1/maintenance-orders').set('Authorization', bearer(otherToken));
      for (const response of [own, attempted, other]) expect(response.status).toBe(200);
      expect(own.body).toEqual(expect.arrayContaining([expect.objectContaining({ id })]));
      expect(own.body).not.toEqual(expect.arrayContaining([expect.objectContaining({ id: otherOrderId })]));
      expect(attempted.body).toEqual(expect.arrayContaining([expect.objectContaining({ id })]));
      expect(attempted.body).not.toEqual(expect.arrayContaining([expect.objectContaining({ id: otherOrderId })]));
      expect(other.body).toEqual(expect.arrayContaining([expect.objectContaining({ id: otherOrderId })]));
      expect(other.body).not.toEqual(expect.arrayContaining([expect.objectContaining({ id })]));
    });
    await step('maintenance READ by technician', async () => {
      const res = await request(app).get(`/v1/maintenance-orders/${id}`).set('Authorization', bearer(techToken));
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ id, requestedById: employeeId });
    });
    await step('maintenance UPDATE denied to employee', async () => {
      expect((await request(app).patch(`/v1/maintenance-orders/${id}`).set('Authorization', bearer(employeeToken)).send({ status: 'COMPLETED' })).status).toBe(403);
      expect((await prisma.maintenanceOrder.findUnique({ where: { id } }))?.status).toBe('PENDING');
    });
    await step('maintenance invalid technician role is rejected', async () => {
      expect((await request(app).patch(`/v1/maintenance-orders/${id}`).set('Authorization', bearer(techToken)).send({ technicianId: employeeUserId })).status).toBe(400);
    });
    await step('maintenance UPDATE and assignment by technician', async () => {
      const res = await request(app).patch(`/v1/maintenance-orders/${id}`).set('Authorization', bearer(techToken)).send({ status: 'IN_PROGRESS', technicianId });
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ id, status: 'IN_PROGRESS', technicianId });
      expect(await prisma.maintenanceOrder.findUnique({ where: { id } })).toMatchObject({ status: 'IN_PROGRESS', technicianId });
    });
    await step('maintenance DELETE and 404 after deletion', async () => {
      expect((await request(app).delete(`/v1/maintenance-orders/${id}`).set('Authorization', bearer(techToken))).status).toBe(204);
      expect((await request(app).get(`/v1/maintenance-orders/${id}`).set('Authorization', bearer(techToken))).status).toBe(404);
      expect((await request(app).delete(`/v1/maintenance-orders/${otherOrderId}`).set('Authorization', bearer(adminToken))).status).toBe(204);
    });
  });

  test('activity logs and refresh/logout', async () => {
    await step('activity logs readable by admin and restricted for employee', async () => {
      const res = await request(app).get('/v1/activity-logs').query({ userId: adminId, limit: 100 }).set('Authorization', bearer(adminToken));
      expect(res.status).toBe(200);
      expect(res.body).toEqual(expect.arrayContaining([expect.objectContaining({ userId: adminId, action: expect.stringContaining(apiCollegeName) })]));
      expect((await request(app).get('/v1/activity-logs').set('Authorization', bearer(employeeToken))).status).toBe(403);
    });
    let rotatedRefresh = '';
    await step('refresh accepts live refresh token', async () => {
      const res = await request(app).post('/v1/auth/refresh-tokens').send({ refreshToken: otherRefresh });
      expect(res.status).toBe(200);
      expect(res.body.access.token).toEqual(expect.any(String));
      rotatedRefresh = res.body.refresh.token;
      expect(rotatedRefresh).toEqual(expect.any(String));
    });
    await step('logout deletes refresh session; reuse is rejected', async () => {
      expect((await request(app).post('/v1/auth/logout').send({ refreshToken: rotatedRefresh })).status).toBe(204);
      expect((await request(app).post('/v1/auth/logout').send({ refreshToken: rotatedRefresh })).status).toBe(404);
      expect((await request(app).post('/v1/auth/refresh-tokens').send({ refreshToken: rotatedRefresh })).status).toBe(401);
    });
  });
});
