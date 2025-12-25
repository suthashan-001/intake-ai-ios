const { PrismaClient } = require('@prisma/client');
const { NotFoundError } = require('../utils/errors');
const { generateSummary, generateSummaryStream } = require('../services/geminiService');
const logger = require('../utils/logger');

const prisma = new PrismaClient();

/**
 * Get all summaries for an intake
 * GET /api/summaries
 */
exports.getSummaries = async (req, res, next) => {
  try {
    const { intakeId, page = 1, limit = 10 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {
      intake: {
        patient: { providerId: req.user.id },
      },
    };

    if (intakeId) {
      where.intakeId = intakeId;
    }

    const [summaries, total] = await Promise.all([
      prisma.summary.findMany({
        where,
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
        orderBy: { generatedAt: 'desc' },
        skip,
        take: parseInt(limit),
      }),
      prisma.summary.count({ where }),
    ]);

    res.json({
      success: true,
      data: {
        summaries: summaries.map((s) => ({
          id: s.id,
          content: s.content,
          model: s.model,
          tokensUsed: s.tokensUsed,
          generatedAt: s.generatedAt,
          intakeId: s.intakeId,
          patient: {
            id: s.intake.patient.id,
            name: `${s.intake.patient.firstName} ${s.intake.patient.lastName}`,
          },
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
 * Get a single summary
 * GET /api/summaries/:id
 */
exports.getSummary = async (req, res, next) => {
  try {
    const { id } = req.params;

    const summary = await prisma.summary.findFirst({
      where: {
        id,
        intake: {
          patient: { providerId: req.user.id },
        },
      },
      include: {
        intake: {
          include: {
            patient: true,
          },
        },
      },
    });

    if (!summary) {
      throw new NotFoundError('Summary');
    }

    res.json({
      success: true,
      data: { summary },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Generate a new AI summary for an intake
 * POST /api/summaries/generate
 */
exports.generateSummaryHandler = async (req, res, next) => {
  try {
    const { intakeId } = req.body;

    // Verify intake belongs to provider
    const intake = await prisma.intake.findFirst({
      where: {
        id: intakeId,
        patient: { providerId: req.user.id },
      },
    });

    if (!intake) {
      throw new NotFoundError('Intake');
    }

    logger.info(`Generating AI summary for intake ${intakeId}`);

    // Generate summary using Gemini
    const result = await generateSummary(intake);

    // Save summary to database
    const summary = await prisma.summary.create({
      data: {
        intakeId,
        content: result.content,
        model: result.model,
        tokensUsed: result.tokensUsed,
      },
    });

    logger.info(`AI summary generated for intake ${intakeId}`);

    res.status(201).json({
      success: true,
      data: {
        summary: {
          id: summary.id,
          content: summary.content,
          model: summary.model,
          tokensUsed: summary.tokensUsed,
          generatedAt: summary.generatedAt,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Generate AI summary with streaming response
 * POST /api/summaries/generate/stream
 */
exports.generateSummaryStreamHandler = async (req, res, next) => {
  try {
    const { intakeId } = req.body;

    // Verify intake belongs to provider
    const intake = await prisma.intake.findFirst({
      where: {
        id: intakeId,
        patient: { providerId: req.user.id },
      },
    });

    if (!intake) {
      throw new NotFoundError('Intake');
    }

    logger.info(`Streaming AI summary for intake ${intakeId}`);

    // Set up SSE headers
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('X-Accel-Buffering', 'no');

    let fullContent = '';

    // Stream the response
    for await (const chunk of generateSummaryStream(intake)) {
      fullContent += chunk;
      res.write(`data: ${JSON.stringify({ chunk, done: false })}\n\n`);
    }

    // Save the complete summary
    const summary = await prisma.summary.create({
      data: {
        intakeId,
        content: fullContent,
        model: 'gemini-1.5-pro',
      },
    });

    // Send completion event
    res.write(
      `data: ${JSON.stringify({
        done: true,
        summaryId: summary.id,
      })}\n\n`
    );

    res.end();

    logger.info(`Streaming AI summary completed for intake ${intakeId}`);
  } catch (error) {
    // For streaming, we need to handle errors differently
    if (!res.headersSent) {
      next(error);
    } else {
      res.write(`data: ${JSON.stringify({ error: error.message, done: true })}\n\n`);
      res.end();
    }
  }
};

/**
 * Delete a summary
 * DELETE /api/summaries/:id
 */
exports.deleteSummary = async (req, res, next) => {
  try {
    const { id } = req.params;

    const summary = await prisma.summary.findFirst({
      where: {
        id,
        intake: {
          patient: { providerId: req.user.id },
        },
      },
    });

    if (!summary) {
      throw new NotFoundError('Summary');
    }

    await prisma.summary.delete({ where: { id } });

    logger.info(`Summary ${id} deleted`);

    res.json({
      success: true,
      message: 'Summary deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};
