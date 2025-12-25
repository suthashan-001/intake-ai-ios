const { PrismaClient } = require('@prisma/client');
const { nanoid } = require('nanoid');
const { NotFoundError, ValidationError } = require('../utils/errors');
const logger = require('../utils/logger');

const prisma = new PrismaClient();

/**
 * Create an intake link for a patient
 * POST /api/intake-links
 */
exports.createIntakeLink = async (req, res, next) => {
  try {
    const { patientId, expiresInDays = 7 } = req.body;

    // Verify patient belongs to provider
    const patient = await prisma.patient.findFirst({
      where: {
        id: patientId,
        providerId: req.user.id,
      },
    });

    if (!patient) {
      throw new NotFoundError('Patient');
    }

    // Expire any existing pending links for this patient
    await prisma.intakeLink.updateMany({
      where: {
        patientId,
        status: 'PENDING',
      },
      data: {
        status: 'EXPIRED',
      },
    });

    // Create new intake link
    const token = nanoid(32);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + expiresInDays);

    const intakeLink = await prisma.intakeLink.create({
      data: {
        token,
        patientId,
        expiresAt,
      },
    });

    // Construct the full URL
    const baseUrl = process.env.INTAKE_FORM_URL || 'https://intake.intakeai.app';
    const intakeUrl = `${baseUrl}/form/${token}`;

    logger.info(`Intake link created for patient ${patientId}`);

    res.status(201).json({
      success: true,
      data: {
        intakeLink: {
          id: intakeLink.id,
          token: intakeLink.token,
          url: intakeUrl,
          expiresAt: intakeLink.expiresAt,
          createdAt: intakeLink.createdAt,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get intake link by token (public endpoint for patient form)
 * GET /api/intake-links/:token
 */
exports.getIntakeLinkByToken = async (req, res, next) => {
  try {
    const { token } = req.params;

    const intakeLink = await prisma.intakeLink.findUnique({
      where: { token },
      include: {
        patient: {
          select: {
            firstName: true,
            lastName: true,
            email: true,
            dateOfBirth: true,
          },
        },
      },
    });

    if (!intakeLink) {
      throw new NotFoundError('Intake link');
    }

    // Check if expired
    if (intakeLink.expiresAt < new Date() || intakeLink.status === 'EXPIRED') {
      return res.status(410).json({
        success: false,
        error: {
          code: 'LINK_EXPIRED',
          message: 'This intake link has expired',
        },
      });
    }

    // Check if already completed
    if (intakeLink.status === 'COMPLETED') {
      return res.status(410).json({
        success: false,
        error: {
          code: 'ALREADY_COMPLETED',
          message: 'This intake has already been submitted',
        },
      });
    }

    res.json({
      success: true,
      data: {
        patient: intakeLink.patient,
        expiresAt: intakeLink.expiresAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Submit intake form (public endpoint)
 * POST /api/intake-links/:token/submit
 */
exports.submitIntake = async (req, res, next) => {
  try {
    const { token } = req.params;
    const {
      demographics,
      chiefComplaint,
      medicalHistory,
      medications,
      allergies,
      socialHistory,
      reviewOfSystems,
    } = req.body;

    // Find and validate intake link
    const intakeLink = await prisma.intakeLink.findUnique({
      where: { token },
      include: { patient: true },
    });

    if (!intakeLink) {
      throw new NotFoundError('Intake link');
    }

    if (intakeLink.expiresAt < new Date() || intakeLink.status === 'EXPIRED') {
      throw new ValidationError('This intake link has expired');
    }

    if (intakeLink.status === 'COMPLETED') {
      throw new ValidationError('This intake has already been submitted');
    }

    // Create intake and update link status in transaction
    const [intake] = await prisma.$transaction([
      prisma.intake.create({
        data: {
          patientId: intakeLink.patientId,
          intakeLinkId: intakeLink.id,
          demographics,
          chiefComplaint,
          medicalHistory,
          medications,
          allergies,
          socialHistory,
          reviewOfSystems,
          completedAt: new Date(),
        },
      }),
      prisma.intakeLink.update({
        where: { id: intakeLink.id },
        data: { status: 'COMPLETED' },
      }),
    ]);

    // Detect red flags asynchronously
    detectRedFlags(intake.id).catch((err) => {
      logger.error('Red flag detection failed:', err);
    });

    logger.info(`Intake submitted for patient ${intakeLink.patientId}`);

    res.status(201).json({
      success: true,
      message: 'Intake submitted successfully',
      data: {
        intakeId: intake.id,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get all intakes for provider's patients
 * GET /api/intakes
 */
exports.getIntakes = async (req, res, next) => {
  try {
    const { status, patientId, page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {
      patient: { providerId: req.user.id },
    };

    if (status) {
      where.status = status.toUpperCase().replace(/([A-Z])/g, '_$1').replace(/^_/, '');
    }

    if (patientId) {
      where.patientId = patientId;
    }

    const [intakes, total] = await Promise.all([
      prisma.intake.findMany({
        where,
        include: {
          patient: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
            },
          },
          redFlags: true,
          summaries: {
            orderBy: { generatedAt: 'desc' },
            take: 1,
          },
        },
        orderBy: { completedAt: 'desc' },
        skip,
        take: parseInt(limit),
      }),
      prisma.intake.count({ where }),
    ]);

    res.json({
      success: true,
      data: {
        intakes: intakes.map((intake) => ({
          id: intake.id,
          patient: {
            id: intake.patient.id,
            name: `${intake.patient.firstName} ${intake.patient.lastName}`,
            email: intake.patient.email,
          },
          status: intake.status.toLowerCase().replace('_', ''),
          chiefComplaint: intake.chiefComplaint,
          completedAt: intake.completedAt,
          reviewedAt: intake.reviewedAt,
          hasRedFlags: intake.redFlags.length > 0,
          redFlagCount: intake.redFlags.length,
          hasSummary: intake.summaries.length > 0,
        })),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get a single intake
 * GET /api/intakes/:id
 */
exports.getIntake = async (req, res, next) => {
  try {
    const { id } = req.params;

    const intake = await prisma.intake.findFirst({
      where: {
        id,
        patient: { providerId: req.user.id },
      },
      include: {
        patient: true,
        redFlags: true,
        summaries: {
          orderBy: { generatedAt: 'desc' },
        },
      },
    });

    if (!intake) {
      throw new NotFoundError('Intake');
    }

    res.json({
      success: true,
      data: { intake },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Mark intake as reviewed
 * POST /api/intakes/:id/review
 */
exports.markReviewed = async (req, res, next) => {
  try {
    const { id } = req.params;

    const intake = await prisma.intake.findFirst({
      where: {
        id,
        patient: { providerId: req.user.id },
      },
    });

    if (!intake) {
      throw new NotFoundError('Intake');
    }

    const updatedIntake = await prisma.intake.update({
      where: { id },
      data: {
        status: 'REVIEWED',
        reviewedAt: new Date(),
      },
    });

    logger.info(`Intake ${id} marked as reviewed`);

    res.json({
      success: true,
      data: { intake: updatedIntake },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Detect red flags in an intake (internal function)
 */
async function detectRedFlags(intakeId) {
  const intake = await prisma.intake.findUnique({
    where: { id: intakeId },
  });

  if (!intake) return;

  const redFlags = [];

  // Check chief complaint for concerning keywords
  const urgentKeywords = [
    { term: 'chest pain', category: 'cardiac', severity: 'CRITICAL' },
    { term: 'difficulty breathing', category: 'respiratory', severity: 'CRITICAL' },
    { term: 'shortness of breath', category: 'respiratory', severity: 'HIGH' },
    { term: 'severe headache', category: 'neurological', severity: 'HIGH' },
    { term: 'worst headache', category: 'neurological', severity: 'CRITICAL' },
    { term: 'sudden weakness', category: 'neurological', severity: 'CRITICAL' },
    { term: 'numbness', category: 'neurological', severity: 'MEDIUM' },
    { term: 'blood in stool', category: 'gastrointestinal', severity: 'HIGH' },
    { term: 'blood in urine', category: 'urological', severity: 'HIGH' },
    { term: 'suicidal', category: 'psychiatric', severity: 'CRITICAL' },
    { term: 'self-harm', category: 'psychiatric', severity: 'CRITICAL' },
    { term: 'overdose', category: 'toxicology', severity: 'CRITICAL' },
    { term: 'unconscious', category: 'general', severity: 'CRITICAL' },
    { term: 'fainting', category: 'cardiovascular', severity: 'HIGH' },
    { term: 'allergic reaction', category: 'allergy', severity: 'HIGH' },
    { term: 'anaphylaxis', category: 'allergy', severity: 'CRITICAL' },
  ];

  const chiefComplaint = (intake.chiefComplaint || '').toLowerCase();

  for (const keyword of urgentKeywords) {
    if (chiefComplaint.includes(keyword.term)) {
      redFlags.push({
        intakeId,
        category: keyword.category,
        description: `Patient reported: "${keyword.term}"`,
        severity: keyword.severity,
        source: 'chiefComplaint',
      });
    }
  }

  // Check medications for high-risk drugs
  const medications = intake.medications || [];
  const highRiskMeds = ['warfarin', 'insulin', 'methotrexate', 'lithium', 'digoxin'];

  if (Array.isArray(medications)) {
    for (const med of medications) {
      const medName = (med.name || med || '').toLowerCase();
      if (highRiskMeds.some((hrm) => medName.includes(hrm))) {
        redFlags.push({
          intakeId,
          category: 'medication',
          description: `High-risk medication: ${medName}`,
          severity: 'MEDIUM',
          source: 'medications',
        });
      }
    }
  }

  // Check allergies for drug allergies
  const allergies = intake.allergies || [];
  if (Array.isArray(allergies) && allergies.length > 3) {
    redFlags.push({
      intakeId,
      category: 'allergy',
      description: `Multiple allergies reported (${allergies.length})`,
      severity: 'LOW',
      source: 'allergies',
    });
  }

  // Save red flags to database
  if (redFlags.length > 0) {
    await prisma.redFlag.createMany({
      data: redFlags,
    });
    logger.info(`Created ${redFlags.length} red flags for intake ${intakeId}`);
  }
}

module.exports = {
  createIntakeLink: exports.createIntakeLink,
  getIntakeLinkByToken: exports.getIntakeLinkByToken,
  submitIntake: exports.submitIntake,
  getIntakes: exports.getIntakes,
  getIntake: exports.getIntake,
  markReviewed: exports.markReviewed,
};
