const express = require('express');
const { body, param, query } = require('express-validator');
const summaryController = require('../controllers/summaryController');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/summaries
 * @desc    Get all summaries
 * @access  Private
 */
router.get(
  '/',
  [
    query('intakeId').optional(),
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 50 }),
  ],
  validate,
  summaryController.getSummaries
);

/**
 * @route   GET /api/summaries/:id
 * @desc    Get a single summary
 * @access  Private
 */
router.get(
  '/:id',
  [param('id').notEmpty().withMessage('Summary ID required')],
  validate,
  summaryController.getSummary
);

/**
 * @route   POST /api/summaries/generate
 * @desc    Generate a new AI summary for an intake
 * @access  Private
 */
router.post(
  '/generate',
  [body('intakeId').notEmpty().withMessage('Intake ID required')],
  validate,
  summaryController.generateSummaryHandler
);

/**
 * @route   POST /api/summaries/generate/stream
 * @desc    Generate AI summary with streaming response (SSE)
 * @access  Private
 */
router.post(
  '/generate/stream',
  [body('intakeId').notEmpty().withMessage('Intake ID required')],
  validate,
  summaryController.generateSummaryStreamHandler
);

/**
 * @route   DELETE /api/summaries/:id
 * @desc    Delete a summary
 * @access  Private
 */
router.delete(
  '/:id',
  [param('id').notEmpty().withMessage('Summary ID required')],
  validate,
  summaryController.deleteSummary
);

module.exports = router;
