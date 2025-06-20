const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { VertexAI } = require('@google-cloud/vertexai');

initializeApp();

exports.chatWithGemini = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Anda harus login untuk menggunakan fitur ini.');
    }

    const prompt = request.data.prompt;
    if (!prompt) {
        throw new HttpsError('invalid-argument', 'Fungsi harus dipanggil dengan argumen "prompt".');
    }
    const vertexAI = new VertexAI({ project: process.env.GCLOUD_PROJECT, location: 'asia-southeast1' });
    const generativeModel = vertexAI.getGenerativeModel({
        model: 'gemini-1.0-pro',
    });
    try {
        const resp = await generativeModel.generateContent(prompt);
        const contentResponse = await resp.response;
        const text = contentResponse.candidates[0].content.parts[0].text;

        return { text: text };
    } catch (error) {
        console.error("Error saat memanggil Gemini API:", error);
        throw new HttpsError('internal', 'Terjadi kesalahan saat berkomunikasi dengan layanan AI.');
    }
});