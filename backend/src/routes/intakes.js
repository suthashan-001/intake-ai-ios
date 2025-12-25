const express = require('express');
const { body, param, query } = require('express-validator');
const intakeController = require('../controllers/intakeController');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = express.Router();

// ============================================
// Public routes (for patient intake forms)
// ============================================

/**
 * @route   GET /api/intake-links/:token
 * @desc    Get intake link info by token (for patient form)
 * @access  Public
 */
router.get(
  '/intake-links/:token',
  [param('token').notEmpty().withMessage('Token required')],
  validate,
  intakeController.getIntakeLinkByToken
);

/**
 * @route   POST /api/intake-links/:token/submit
 * @desc    Submit intake form
 * @access  Public
 */
router.post(
  '/intake-links/:token/submit',
  [
    param('token').notEmpty().withMessage('Token required'),
    body('chiefComplaint').trim().notEmpty().withMessage('Chief complaint required'),
    body('demographics').optional().isObject(),
    body('medicalHistory').optional().isObject(),
    body('medications').optional().isArray(),
    body('allergies').optional().isArray(),
    body('socialHistory').optional().isObject(),
    body('reviewOfSystems').optional().isObject(),
  ],
  validate,
  intakeController.submitIntake
);

// ============================================
// Protected routes (for healthcare providers)
// ============================================

/**
 * @route   POST /api/intake-links
 * @desc    Create an intake link for a patient
 * @access  Private
 */
router.post(
  '/intake-links',
  authenticate,
  [
    body('patientId').notEmpty().withMessage('Patient ID required'),
    body('expiresInDays').optional().isInt({ min: 1, max: 30 }),
  ],
  validate,
  intakeController.createIntakeLink
);

/**
 * @route   GET /api/intakes
 * @desc    Get all intakes for provider's patients
 * @access  Private
 */
router.get(
  '/intakes',
  authenticate,
  [
    query('status').optional().isIn(['readyForReview', 'reviewed']),
    query('patientId').optional(),
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
  ],
  validate,
  intakeController.getIntakes
);

/**
 * @route   GET /api/intakes/:id
 * @desc    Get a single intake
 * @access  Private
 */
router.get(
  '/intakes/:id',
  authenticate,
  [param('id').notEmpty().withMessage('Intake ID required')],
  validate,
  intakeController.getIntake
);

/**
 * @route   POST /api/intakes/:id/review
 * @desc    Mark intake as reviewed
 * @access  Private
 */
router.post(
  '/intakes/:id/review',
  authenticate,
  [param('id').notEmpty().withMessage('Intake ID required')],
  validate,
  intakeController.markReviewed
);

module.exports = router;
