const request = require('supertest');
const app = require('../src/index');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

describe('Patients Endpoints', () => {
  let accessToken;
  let userId;
  let patientId;

  const testUser = {
    email: 'doctor@example.com',
    password: 'DoctorPass123',
    firstName: 'Doctor',
    lastName: 'Test',
  };

  const testPatient = {
    firstName: 'John',
    lastName: 'Doe',
    email: 'john.doe@patient.com',
    phone: '555-123-4567',
    dateOfBirth: '1990-05-15',
  };

  beforeAll(async () => {
    // Clean up existing test data
    await prisma.patient.deleteMany({
      where: { email: testPatient.email },
    });
    await prisma.user.deleteMany({
      where: { email: testUser.email },
    });

    // Register and login to get access token
    const registerRes = await request(app)
      .post('/api/auth/register')
      .send(testUser);

    accessToken = registerRes.body.data.accessToken;
    userId = registerRes.body.data.user.id;
  });

  afterAll(async () => {
    // Clean up
    await prisma.patient.deleteMany({
      where: { providerId: userId },
    });
    await prisma.user.deleteMany({
      where: { email: testUser.email },
    });
    await prisma.$disconnect();
  });

  describe('POST /api/patients', () => {
    it('should create a new patient', async () => {
      const res = await request(app)
        .post('/api/patients')
        .set('Authorization', `Bearer ${accessToken}`)
        .send(testPatient)
        .expect(201);

      expect(res.body.success).toBe(true);
      expect(res.body.data.patient).toBeDefined();
      expect(res.body.data.patient.firstName).toBe(testPatient.firstName);
      expect(res.body.data.patient.lastName).toBe(testPatient.lastName);
      expect(res.body.data.patient.email).toBe(testPatient.email.toLowerCase());

      patientId = res.body.data.patient.id;
    });

    it('should reject duplicate email for same provider', async () => {
      const res = await request(app)
        .post('/api/patients')
        .set('Authorization', `Bearer ${accessToken}`)
        .send(testPatient)
        .expect(400);

      expect(res.body.success).toBe(false);
    });

    it('should reject missing required fields', async () => {
      const res = await request(app)
        .post('/api/patients')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ firstName: 'Only' })
        .expect(400);

      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should reject invalid email', async () => {
      const res = await request(app)
        .post('/api/patients')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          ...testPatient,
          email: 'invalid-email',
        })
        .expect(400);

      expect(res.body.success).toBe(false);
    });

    it('should reject without authentication', async () => {
      const res = await request(app)
        .post('/api/patients')
        .send(testPatient)
        .expect(401);

      expect(res.body.success).toBe(false);
    });
  });

  describe('GET /api/patients', () => {
    it('should return list of patients', async () => {
      const res = await request(app)
        .get('/api/patients')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.patients).toBeDefined();
      expect(Array.isArray(res.body.data.patients)).toBe(true);
      expect(res.body.data.patients.length).toBeGreaterThan(0);
      expect(res.body.data.pagination).toBeDefined();
    });

    it('should support pagination', async () => {
      const res = await request(app)
        .get('/api/patients?page=1&limit=10')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.data.pagination.page).toBe(1);
      expect(res.body.data.pagination.limit).toBe(10);
    });

    it('should support search', async () => {
      const res = await request(app)
        .get(`/api/patients?search=${testPatient.firstName}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.data.patients.length).toBeGreaterThan(0);
      expect(res.body.data.patients[0].firstName).toBe(testPatient.firstName);
    });

    it('should reject without authentication', async () => {
      const res = await request(app).get('/api/patients').expect(401);

      expect(res.body.success).toBe(false);
    });
  });

  describe('GET /api/patients/:id', () => {
    it('should return a single patient', async () => {
      const res = await request(app)
        .get(`/api/patients/${patientId}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.patient).toBeDefined();
      expect(res.body.data.patient.id).toBe(patientId);
    });

    it('should return 404 for non-existent patient', async () => {
      const res = await request(app)
        .get('/api/patients/non-existent-id')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(404);

      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });
  });

  describe('PUT /api/patients/:id', () => {
    it('should update patient', async () => {
      const res = await request(app)
        .put(`/api/patients/${patientId}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ firstName: 'Jane' })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.patient.firstName).toBe('Jane');
    });

    it('should return 404 for non-existent patient', async () => {
      const res = await request(app)
        .put('/api/patients/non-existent-id')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ firstName: 'Update' })
        .expect(404);

      expect(res.body.success).toBe(false);
    });
  });

  describe('GET /api/patients/stats', () => {
    it('should return dashboard statistics', async () => {
      const res = await request(app)
        .get('/api/patients/stats')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.stats).toBeDefined();
      expect(res.body.data.stats.totalPatients).toBeDefined();
      expect(res.body.data.stats.pendingIntakes).toBeDefined();
      expect(res.body.data.stats.readyForReview).toBeDefined();
    });
  });

  describe('DELETE /api/patients/:id', () => {
    it('should delete patient', async () => {
      const res = await request(app)
        .delete(`/api/patients/${patientId}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);

      // Verify patient is deleted
      const getRes = await request(app)
        .get(`/api/patients/${patientId}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(404);

      expect(getRes.body.error.code).toBe('NOT_FOUND');
    });

    it('should return 404 for already deleted patient', async () => {
      const res = await request(app)
        .delete(`/api/patients/${patientId}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(404);

      expect(res.body.success).toBe(false);
    });
  });
});
