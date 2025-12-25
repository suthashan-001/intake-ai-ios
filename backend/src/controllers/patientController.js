const { PrismaClient } = require('@prisma/client');
const { NotFoundError, ValidationError } = require('../utils/errors');
const logger = require('../utils/logger');

const prisma = new PrismaClient();

/**
 * Get all patients for the authenticated provider
 * GET /api/patients
 */
exports.getPatients = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, status } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Build where clause
    const where = {
      providerId: req.user.id,
    };

    if (search) {
      where.OR = [
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    // Get patients with their latest intake
    const [patients, total] = await Promise.all([
      prisma.patient.findMany({
        where,
        include: {
          intakeLinks: {
            orderBy: { createdAt: 'desc' },
            take: 1,
          },
          intakes: {
            orderBy: { createdAt: 'desc' },
            take: 1,
            include: {
              redFlags: true,
              summaries: {
                orderBy: { generatedAt: 'desc' },
                take: 1,
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit),
      }),
      prisma.patient.count({ where }),
    ]);

    // Transform response
    const patientsWithDetails = patients.map((patient) => {
      const latestIntakeLink = patient.intakeLinks[0];
      const latestIntake = patient.intakes[0];

      // Determine display status
      let displayStatus = 'pending';
      if (latestIntake) {
        displayStatus = latestIntake.status === 'REVIEWED' ? 'reviewed' : 'readyForReview';
      } else if (latestIntakeLink) {
        if (latestIntakeLink.status === 'EXPIRED' || latestIntakeLink.expiresAt < new Date()) {
          displayStatus = 'expired';
        }
      }

      return {
        id: patient.id,
        firstName: patient.firstName,
        lastName: patient.lastName,
        fullName: `${patient.firstName} ${patient.lastName}`,
        email: patient.email,
        phone: patient.phone,
        dateOfBirth: patient.dateOfBirth,
        createdAt: patient.createdAt,
        displayStatus,
        latestIntakeLink: latestIntakeLink
          ? {
              id: latestIntakeLink.id,
              status: latestIntakeLink.status.toLowerCase(),
              expiresAt: latestIntakeLink.expiresAt,
              createdAt: latestIntakeLink.createdAt,
            }
          : null,
        latestIntake: latestIntake
          ? {
              id: latestIntake.id,
              status: latestIntake.status.toLowerCase().replace('_', ''),
              completedAt: latestIntake.completedAt,
              reviewedAt: latestIntake.reviewedAt,
              chiefComplaint: latestIntake.chiefComplaint,
            }
          : null,
        redFlags: latestIntake?.redFlags.map((rf) => ({
          id: rf.id,
          category: rf.category,
          description: rf.description,
          severity: rf.severity.toLowerCase(),
        })) || [],
        hasRedFlags: (latestIntake?.redFlags.length || 0) > 0,
        redFlagCount: latestIntake?.redFlags.length || 0,
        hasSummary: (latestIntake?.summaries.length || 0) > 0,
      };
    });

    res.json({
      success: true,
      data: {
        patients: patientsWithDetails,
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
 * Get a single patient by ID
 * GET /api/patients/:id
 */
exports.getPatient = async (req, res, next) => {
  try {
    const { id } = req.params;

    const patient = await prisma.patient.findFirst({
      where: {
        id,
        providerId: req.user.id,
      },
      include: {
        intakeLinks: {
          orderBy: { createdAt: 'desc' },
        },
        intakes: {
          orderBy: { createdAt: 'desc' },
          include: {
            redFlags: true,
            summaries: {
              orderBy: { generatedAt: 'desc' },
            },
          },
        },
      },
    });

    if (!patient) {
      throw new NotFoundError('Patient');
    }

    res.json({
      success: true,
      data: { patient },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Create a new patient
 * POST /api/patients
 */
exports.createPatient = async (req, res, next) => {
  try {
    const { firstName, lastName, email, phone, dateOfBirth } = req.body;

    // Check if patient with email already exists for this provider
    const existingPatient = await prisma.patient.findFirst({
      where: {
        email: email.toLowerCase(),
        providerId: req.user.id,
      },
    });

    if (existingPatient) {
      throw new ValidationError('A patient with this email already exists');
    }

    const patient = await prisma.patient.create({
      data: {
        firstName,
        lastName,
        email: email.toLowerCase(),
        phone,
        dateOfBirth: new Date(dateOfBirth),
        providerId: req.user.id,
      },
    });

    logger.info(`Patient created: ${patient.id} by provider ${req.user.id}`);

    res.status(201).json({
      success: true,
      data: { patient },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update a patient
 * PUT /api/patients/:id
 */
exports.updatePatient = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { firstName, lastName, email, phone, dateOfBirth } = req.body;

    // Verify patient belongs to provider
    const existingPatient = await prisma.patient.findFirst({
      where: {
        id,
        providerId: req.user.id,
      },
    });

    if (!existingPatient) {
      throw new NotFoundError('Patient');
    }

    // If email is being changed, check for duplicates
    if (email && email.toLowerCase() !== existingPatient.email) {
      const duplicateEmail = await prisma.patient.findFirst({
        where: {
          email: email.toLowerCase(),
          providerId: req.user.id,
          NOT: { id },
        },
      });

      if (duplicateEmail) {
        throw new ValidationError('A patient with this email already exists');
      }
    }

    const patient = await prisma.patient.update({
      where: { id },
      data: {
        ...(firstName && { firstName }),
        ...(lastName && { lastName }),
        ...(email && { email: email.toLowerCase() }),
        ...(phone !== undefined && { phone }),
        ...(dateOfBirth && { dateOfBirth: new Date(dateOfBirth) }),
      },
    });

    logger.info(`Patient updated: ${patient.id}`);

    res.json({
      success: true,
      data: { patient },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete a patient
 * DELETE /api/patients/:id
 */
exports.deletePatient = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Verify patient belongs to provider
    const patient = await prisma.patient.findFirst({
      where: {
        id,
        providerId: req.user.id,
      },
    });

    if (!patient) {
      throw new NotFoundError('Patient');
    }

    await prisma.patient.delete({
      where: { id },
    });

    logger.info(`Patient deleted: ${id}`);

    res.json({
      success: true,
      message: 'Patient deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get dashboard statistics
 * GET /api/patients/stats
 */
exports.getStats = async (req, res, next) => {
  try {
    const providerId = req.user.id;

    // Get counts in parallel
    const [
      totalPatients,
      pendingIntakes,
      readyForReview,
      reviewedIntakes,
      recentRedFlags,
    ] = await Promise.all([
      prisma.patient.count({ where: { providerId } }),
      prisma.intakeLink.count({
        where: {
          patient: { providerId },
          status: 'PENDING',
          expiresAt: { gt: new Date() },
        },
      }),
      prisma.intake.count({
        where: {
          patient: { providerId },
          status: 'READY_FOR_REVIEW',
        },
      }),
      prisma.intake.count({
        where: {
          patient: { providerId },
          status: 'REVIEWED',
        },
      }),
      prisma.redFlag.findMany({
        where: {
          intake: {
            patient: { providerId },
            status: 'READY_FOR_REVIEW',
          },
        },
        include: {
          intake: {
            include: {
              patient: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
    ]);

    res.json({
      success: true,
      data: {
        stats: {
          totalPatients,
          pendingIntakes,
          readyForReview,
          reviewedIntakes,
        },
        recentRedFlags: recentRedFlags.map((rf) => ({
          id: rf.id,
          category: rf.category,
          description: rf.description,
          severity: rf.severity.toLowerCase(),
          patientId: rf.intake.patient.id,
          patientName: `${rf.intake.patient.firstName} ${rf.intake.patient.lastName}`,
          createdAt: rf.createdAt,
        })),
      },
    });
  } catch (error) {
    next(error);
  }
};
