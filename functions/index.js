// functions/index.js

// Import necessary Firebase modules
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(); // Initialize Firebase Admin SDK for Firestore access

// Import Axios for making HTTP requests to Meta Graph API
const axios = require('axios');

// --- Configuration for Meta WhatsApp Business Cloud API from Environment Variables ---
// These variables must be set using Firebase CLI before deployment.
// Example CLI command to set them is provided at the end of this response.

const ACCESS_TOKEN = functions.config().facebook.access_token;
const PHONE_NUMBER_ID = functions.config().facebook.phone_number_id;
const RECIPIENT_WA_ID = functions.config().facebook.recipient_wa_id; // The WhatsApp ID of the supervisor (e.g., '919876543210')

// Meta Graph API base URL and version
const GRAPH_API_BASE_URL = 'https://graph.facebook.com/v18.0';

/**
 * Firebase Cloud Function to send a WhatsApp message using Meta's Cloud API
 * when a user's mounting progress data is updated in Firestore.
 *
 * Trigger: onUpdate for documents at 'users/{userId}/mountingProgress/{itemName}'
 */
exports.sendProgressUpdate = functions.firestore
    .document('users/{userId}/mountingProgress/{itemName}')
    .onUpdate(async (change, context) => {
        // Get the data of the updated document
        const newValue = change.after.data();

        // Extract parameters from the Firestore document path
        const userId = context.params.userId;
        const itemName = context.params.itemName;

        // Extract relevant data from the updated document
        const todayProgress = newValue.todayProgress;
        const cumulativeProgress = newValue.cumulativeProgress;
        // Convert Firestore Timestamp to a readable local string, or 'N/A' if not present
        const lastUpdated = newValue.lastUpdated ? newValue.lastUpdated.toDate().toLocaleString() : 'N/A';

        functions.logger.info(`Processing update for user ${userId}, item ${itemName}.`, {
            userId: userId,
            itemName: itemName,
            todayProgress: todayProgress,
            cumulativeProgress: cumulativeProgress
        });

        if (!ACCESS_TOKEN || !PHONE_NUMBER_ID || !RECIPIENT_WA_ID) {
            functions.logger.error('Missing one or more Facebook WhatsApp API environment variables. Please check functions:config.');
            return null;
        }

        // Construct the message payload for the Meta WhatsApp Cloud API
        // This uses a pre-approved template message.
        const messagePayload = {
            messaging_product: 'whatsapp',
            to: RECIPIENT_WA_ID, // Supervisor's WhatsApp ID
            type: 'template',
            template: {
                name: 'solar_progress_update', // **IMPORTANT: This must be the exact name of your pre-approved template**
                language: { code: 'en_US' }, // **IMPORTANT: Match your template's language code**
                components: [
                    {
                        type: 'body',
                        parameters: [
                            { type: 'text', text: String(itemName) },         // {{1}} Item Name
                            { type: 'text', text: String(todayProgress) },    // {{2}} Today's Progress
                            { type: 'text', text: String(cumulativeProgress) }, // {{3}} Cumulative Progress
                            { type: 'text', text: String(lastUpdated) },      // {{4}} Last Updated Timestamp
                            { type: 'text', text: String(userId) }            // {{5}} User ID
                        ],
                    },
                ],
            },
        };

        try {
            // Make the POST request to the Meta Graph API
            const response = await axios.post(
                `${GRAPH_API_BASE_URL}/${PHONE_NUMBER_ID}/messages`,
                messagePayload,
                {
                    headers: {
                        'Authorization': `Bearer ${ACCESS_TOKEN}`,
                        'Content-Type': 'application/json',
                    },
                }
            );

            functions.logger.info('WhatsApp message sent successfully via Meta Cloud API!', {
                responseStatus: response.status,
                responseData: response.data,
                recipient: RECIPIENT_WA_ID
            });
            
        } catch (error) {
            functions.logger.error('Failed to send WhatsApp message via Meta Cloud API:', {
                message: error.message,
                status: error.response?.status,
                data: error.response?.data,
                headers: error.response?.headers,
            });
            // You might want to implement a retry mechanism or alert system here for production
        }

        // Cloud Functions should return null or a Promise to indicate completion
        return null;
    });