const request = require('supertest');
const app = require('../src/index');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

describe('Intakes Endpoints', () => {
  let accessToken;
  let userId;
  let patientId;
  let intakeLinkToken;
  let intakeId;

  const testUser = {
    email: 'intake-doctor@example.com',
    password: 'DoctorPass123',
    firstName: 'Intake',
    lastName: 'Doctor',
  };

  const testPatient = {
    firstName: 'Patient',
    lastName: 'Test',
    email: 'intake-patient@test.com',
    dateOfBirth: '1985-03-20',
  };

  const intakeData = {
    chiefComplaint: 'Severe headache for 3 days',
    demographics: {
      height: '5\'10"',
      weight: '170 lbs',
    },
    medicalHistory: {
      conditions: ['hypertension'],
      surgeries: [],
    },
    medications: [
      { name: 'Lisinopril', dosage: '10mg', frequency: 'daily' },
    ],
    allergies: [
      { allergen: 'Penicillin', reaction: 'Hives' },
    ],
    socialHistory: {
      smoking: 'never',
      alcohol: 'occasional',
    },
  };

  beforeAll(async () => {
    // Clean up
    await prisma.user.deleteMany({
      where: { email: testUser.email },
    });

    // Register provider
    const registerRes = await request(app)
      .post('/api/auth/register')
      .send(testUser);

    accessToken = registerRes.body.data.accessToken;
    userId = registerRes.body.data.user.id;

    // Create patient
    const patientRes = await request(app)
      .post('/api/patients')
      .set('Authorization', `Bearer ${accessToken}`)
      .send(testPatient);

    patientId = patientRes.body.data.patient.id;
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: { email: testUser.email },
    });
    await prisma.$disconnect();
  });

  describe('POST /api/intake-links', () => {
    it('should create an intake link for a patient', async () => {
      const res = await request(app)
        .post('/api/intake-links')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ patientId })
        .expect(201);

      expect(res.body.success).toBe(true);
      expect(res.body.data.intakeLink).toBeDefined();
      expect(res.body.data.intakeLink.token).toBeDefined();
      expect(res.body.data.intakeLink.url).toBeDefined();
      expect(res.body.data.intakeLink.expiresAt).toBeDefined();

      intakeLinkToken = res.body.data.intakeLink.token;
    });

    it('should set custom expiry', async () => {
      const res = await request(app)
        .post('/api/intake-links')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ patientId, expiresInDays: 14 })
        .expect(201);

      const expiresAt = new Date(res.body.data.intakeLink.expiresAt);
      const now = new Date();
      const daysDiff = Math.round((expiresAt - now) / (1000 * 60 * 60 * 24));

      expect(daysDiff).toBe(14);

      // Use this token for subsequent tests
      intakeLinkToken = res.body.data.intakeLink.token;
    });

    it('should reject non-existent patient', async () => {
      const res = await request(app)
        .post('/api/intake-links')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ patientId: 'non-existent' })
        .expect(404);

      expect(res.body.success).toBe(false);
    });

    it('should reject without authentication', async () => {
      const res = await request(app)
        .post('/api/intake-links')
        .send({ patientId })
        .expect(401);

      expect(res.body.success).toBe(false);
    });
  });

  describe('GET /api/intake-links/:token (Public)', () => {
    it('should return intake link info', async () => {
      const res = await request(app)
        .get(`/api/intake-links/${intakeLinkToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.patient).toBeDefined();
      expect(res.body.data.patient.firstName).toBe(testPatient.firstName);
      expect(res.body.data.expiresAt).toBeDefined();
    });

    it('should return 404 for invalid token', async () => {
      const res = await request(app)
        .get('/api/intake-links/invalid-token')
        .expect(404);

      expect(res.body.success).toBe(false);
    });
  });

  describe('POST /api/intake-links/:token/submit (Public)', () => {
    it('should submit intake form', async () => {
      const res = await request(app)
        .post(`/api/intake-links/${intakeLinkToken}/submit`)
        .send(intakeData)
        .expect(201);

      expect(res.body.success).toBe(true);
      expect(res.body.data.intakeId).toBeDefined();

      intakeId = res.body.data.intakeId;
    });

    it('should reject duplicate submission', async () => {
      const res = await request(app)
        .post(`/api/intake-links/${intakeLinkToken}/submit`)
        .send(intakeData)
        .expect(400);

      expect(res.body.success).toBe(false);
    });

    it('should reject missing chief complaint', async () => {
      // Create new link for this test
      const linkRes = await request(app)
        .post('/api/intake-links')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ patientId });

      const newToken = linkRes.body.data.intakeLink.token;

      const res = await request(app)
        .post(`/api/intake-links/${newToken}/submit`)
        .send({ demographics: {} })
        .expect(400);

      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('GET /api/intakes', () => {
    it('should return list of intakes', async () => {
      const res = await request(app)
        .get('/api/intakes')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.intakes).toBeDefined();
      expect(Array.isArray(res.body.data.intakes)).toBe(true);
      expect(res.body.data.intakes.length).toBeGreaterThan(0);
    });

    it('should filter by status', async () => {
      const res = await request(app)
        .get('/api/intakes?status=readyForReview')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      res.body.data.intakes.forEach((intake) => {
        expect(intake.status).toBe('readyforreview');
      });
    });

    it('should filter by patient', async () => {
      const res = await request(app)
        .get(`/api/intakes?patientId=${patientId}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      res.body.data.intakes.forEach((intake) => {
        expect(intake.patient.id).toBe(patientId);
      });
    });
  });

  describe('GET /api/intakes/:id', () => {
    it('should return a single intake with details', async () => {
      const res = await request(app)
        .get(`/api/intakes/${intakeId}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.intake).toBeDefined();
      expect(res.body.data.intake.id).toBe(intakeId);
      expect(res.body.data.intake.chiefComplaint).toBe(intakeData.chiefComplaint);
    });

    it('should return 404 for non-existent intake', async () => {
      const res = await request(app)
        .get('/api/intakes/non-existent')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(404);

      expect(res.body.success).toBe(false);
    });
  });

  describe('POST /api/intakes/:id/review', () => {
    it('should mark intake as reviewed', async () => {
      const res = await request(app)
        .post(`/api/intakes/${intakeId}/review`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.intake.status).toBe('REVIEWED');
      expect(res.body.data.intake.reviewedAt).toBeDefined();
    });

    it('should return 404 for non-existent intake', async () => {
      const res = await request(app)
        .post('/api/intakes/non-existent/review')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(404);

      expect(res.body.success).toBe(false);
    });
  });

  describe('Red Flag Detection', () => {
    it('should detect red flags in chief complaint', async () => {
      // Create new link
      const linkRes = await request(app)
        .post('/api/intake-links')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ patientId });

      const token = linkRes.body.data.intakeLink.token;

      // Submit with concerning symptoms
      await request(app)
        .post(`/api/intake-links/${token}/submit`)
        .send({
          chiefComplaint: 'Chest pain and difficulty breathing',
          medications: [],
          allergies: [],
        });

      // Wait for async red flag detection
      await new Promise((resolve) => setTimeout(resolve, 100));

      // Get intakes and check for red flags
      const intakesRes = await request(app)
        .get('/api/intakes')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      const latestIntake = intakesRes.body.data.intakes[0];
      expect(latestIntake.hasRedFlags).toBe(true);
      expect(latestIntake.redFlagCount).toBeGreaterThan(0);
    });
  });
});
