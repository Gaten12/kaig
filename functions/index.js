const functions = require("firebase-functions");
const admin = require("firebase-admin");
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
        model: 'gemini-1.5-pro',
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

const ensureIsAdmin = async (context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Permintaan tidak terautentikasi.");
    }
    const userRecord = await admin.auth().getUser(context.auth.uid);
    if (userRecord.customClaims?.role !== "admin") {
        throw new functions.https.HttpsError("permission-denied", "Hanya admin yang dapat melakukan aksi ini.");
    }
};

exports.resetUserPassword = functions.region("asia-southeast1").https.onCall(async (data, context) => {
    await ensureIsAdmin(context);
    const email = data.email;
    if (!email) {
        throw new functions.https.HttpsError("invalid-argument", "Email diperlukan.");
    }
    try {
        await admin.auth().generatePasswordResetLink(email);
        return { message: `Email reset password telah dikirim ke ${email}.` };
    } catch (error) {
        console.error("Error sending password reset email:", error);
        throw new functions.https.HttpsError("internal", `Gagal mengirim email reset: ${error.message}`);
    }
});

exports.toggleUserStatus = functions.region("asia-southeast1").https.onCall(async (data, context) => {
    await ensureIsAdmin(context);
    const { uid, disabled } = data;
    if (!uid) {
        throw new functions.https.HttpsError("invalid-argument", "UID pengguna diperlukan.");
    }
    try {
        await admin.auth().updateUser(uid, { disabled: disabled });
        const status = disabled ? "dinonaktifkan" : "diaktifkan";
        return { message: `Akun dengan UID ${uid} berhasil ${status}.` };
    } catch (error) {
        console.error("Error toggling user status:", error);
        throw new functions.https.HttpsError("internal", `Gagal mengubah status akun: ${error.message}`);
    }
});

exports.deleteUserAccount = functions.region("asia-southeast1").https.onCall(async (data, context) => {
    await ensureIsAdmin(context);
    const uid = data.uid;
    if (!uid) {
        throw new functions.https.HttpsError("invalid-argument", "UID pengguna diperlukan.");
    }

    try {
        await admin.auth().deleteUser(uid);

        const userDocRef = admin.firestore().collection("users").doc(uid);
        await userDocRef.delete();

        return { message: `Akun dengan UID ${uid} berhasil dihapus dari sistem.` };
    } catch (error) {
        console.error("ERROR SAAT MENGHAPUS AKUN:", {
            uid: uid,
            pemicu: context.auth.uid,
            errorCode: error.code,
            errorMessage: error.message,
        });

        if (error.code === 'auth/user-not-found') {
             try {
                const userDocRef = admin.firestore().collection("users").doc(uid);
                await userDocRef.delete();
                return { message: `Akun di Auth tidak ditemukan, data Firestore untuk UID ${uid} berhasil dihapus.` };
             } catch (firestoreError) {
                console.error("Gagal hapus Firestore setelah user-not-found:", firestoreError);
                throw new functions.https.HttpsError("internal", `User tidak ada di Auth, dan gagal hapus dari Firestore: ${firestoreError.message}`);
             }
        }

        throw new functions.https.HttpsError(
            'internal',
            `Server Error: ${error.message} (Code: ${error.code || 'UNKNOWN'})`
        );
    }
});