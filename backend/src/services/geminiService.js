const { GoogleGenerativeAI } = require('@google/generative-ai');
const config = require('../config');
const logger = require('../utils/logger');

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(config.gemini.apiKey);

/**
 * Generate a clinical summary from intake data
 * @param {Object} intake - The intake data
 * @returns {Object} - Generated summary with content and metadata
 */
async function generateSummary(intake) {
  const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro' });

  const prompt = buildPrompt(intake);

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    // Get usage metadata if available
    const usageMetadata = response.usageMetadata;

    return {
      content: text,
      model: 'gemini-1.5-pro',
      tokensUsed: usageMetadata?.totalTokenCount || null,
    };
  } catch (error) {
    logger.error('Gemini API error:', error);
    throw new Error('Failed to generate AI summary');
  }
}

/**
 * Generate a streaming summary (for real-time display)
 * @param {Object} intake - The intake data
 * @returns {AsyncGenerator} - Yields text chunks
 */
async function* generateSummaryStream(intake) {
  const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro' });

  const prompt = buildPrompt(intake);

  try {
    const result = await model.generateContentStream(prompt);

    for await (const chunk of result.stream) {
      const chunkText = chunk.text();
      if (chunkText) {
        yield chunkText;
      }
    }
  } catch (error) {
    logger.error('Gemini streaming error:', error);
    throw new Error('Failed to generate AI summary');
  }
}

/**
 * Build the prompt for clinical summary generation
 */
function buildPrompt(intake) {
  const { chiefComplaint, demographics, medicalHistory, medications, allergies, socialHistory, reviewOfSystems } = intake;

  return `You are a medical AI assistant helping healthcare providers review patient intake forms. Generate a concise, professional clinical summary based on the following patient intake data.

**IMPORTANT GUIDELINES:**
1. Use clear, professional medical terminology
2. Highlight any concerning findings or red flags with [RED FLAG] prefix
3. Be concise but thorough
4. Format using markdown with clear sections
5. Do not make diagnoses - only summarize and highlight findings
6. Include relevant differential considerations where appropriate

**PATIENT INTAKE DATA:**

**Chief Complaint:**
${chiefComplaint || 'Not provided'}

**Demographics:**
${formatJson(demographics)}

**Medical History:**
${formatJson(medicalHistory)}

**Current Medications:**
${formatMedications(medications)}

**Allergies:**
${formatAllergies(allergies)}

**Social History:**
${formatJson(socialHistory)}

**Review of Systems:**
${formatJson(reviewOfSystems)}

---

Please generate a clinical summary with the following sections:
1. **Summary** - Brief overview (2-3 sentences)
2. **Key Findings** - Bullet points of important information
3. **Red Flags** - Any concerning findings (if none, state "No immediate red flags identified")
4. **Medications Review** - Brief medication summary with any potential concerns
5. **Considerations** - Suggested areas for further evaluation (not diagnoses)

Keep the summary professional and suitable for a healthcare provider's review.`;
}

/**
 * Format JSON data for the prompt
 */
function formatJson(data) {
  if (!data) return 'Not provided';
  if (typeof data === 'string') return data;

  try {
    const formatted = [];
    for (const [key, value] of Object.entries(data)) {
      const label = key.replace(/([A-Z])/g, ' $1').replace(/^./, (str) => str.toUpperCase());
      formatted.push(`- ${label}: ${typeof value === 'object' ? JSON.stringify(value) : value}`);
    }
    return formatted.join('\n') || 'Not provided';
  } catch {
    return 'Not provided';
  }
}

/**
 * Format medications list
 */
function formatMedications(medications) {
  if (!medications || !Array.isArray(medications) || medications.length === 0) {
    return 'None reported';
  }

  return medications
    .map((med) => {
      if (typeof med === 'string') return `- ${med}`;
      return `- ${med.name || 'Unknown'}${med.dosage ? ` (${med.dosage})` : ''}${med.frequency ? ` - ${med.frequency}` : ''}`;
    })
    .join('\n');
}

/**
 * Format allergies list
 */
function formatAllergies(allergies) {
  if (!allergies || !Array.isArray(allergies) || allergies.length === 0) {
    return 'No known allergies (NKDA)';
  }

  return allergies
    .map((allergy) => {
      if (typeof allergy === 'string') return `- ${allergy}`;
      return `- ${allergy.allergen || 'Unknown'}${allergy.reaction ? ` → ${allergy.reaction}` : ''}`;
    })
    .join('\n');
}

module.exports = {
  generateSummary,
  generateSummaryStream,
};
