const express = require('express');
const { body, param, query } = require('express-validator');
const patientController = require('../controllers/patientController');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/patients/stats
 * @desc    Get dashboard statistics
 * @access  Private
 */
router.get('/stats', patientController.getStats);

/**
 * @route   GET /api/patients
 * @desc    Get all patients for authenticated provider
 * @access  Private
 */
router.get(
  '/',
  [
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('search').optional().trim(),
    query('status').optional().isIn(['pending', 'readyForReview', 'reviewed', 'expired']),
  ],
  validate,
  patientController.getPatients
);

/**
 * @route   GET /api/patients/:id
 * @desc    Get a single patient
 * @access  Private
 */
router.get(
  '/:id',
  [param('id').notEmpty().withMessage('Patient ID required')],
  validate,
  patientController.getPatient
);

/**
 * @route   POST /api/patients
 * @desc    Create a new patient
 * @access  Private
 */
router.post(
  '/',
  [
    body('firstName').trim().notEmpty().withMessage('First name required'),
    body('lastName').trim().notEmpty().withMessage('Last name required'),
    body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
    body('phone').optional().trim(),
    body('dateOfBirth').isISO8601().withMessage('Valid date of birth required'),
  ],
  validate,
  patientController.createPatient
);

/**
 * @route   PUT /api/patients/:id
 * @desc    Update a patient
 * @access  Private
 */
router.put(
  '/:id',
  [
    param('id').notEmpty().withMessage('Patient ID required'),
    body('firstName').optional().trim().notEmpty(),
    body('lastName').optional().trim().notEmpty(),
    body('email').optional().isEmail().normalizeEmail(),
    body('phone').optional().trim(),
    body('dateOfBirth').optional().isISO8601(),
  ],
  validate,
  patientController.updatePatient
);

/**
 * @route   DELETE /api/patients/:id
 * @desc    Delete a patient
 * @access  Private
 */
router.delete(
  '/:id',
  [param('id').notEmpty().withMessage('Patient ID required')],
  validate,
  patientController.deletePatient
);

module.exports = router;
