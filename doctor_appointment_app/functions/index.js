const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const serviceAccount = require("./serviceAccountKey.json");
const cors = require("cors")({ origin: true });

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Configure Nodemailer with Gmail
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "oatuissto@gmail.com",
    pass: "kfkgfjhwyjczunlk",
  },
});

// Cloud Function to send emails
exports.sendSignUpEmail = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).json({ success: false, message: "Method not allowed. Use POST." });
    }

    try {
      const { subject, body, recipient } = req.body;

      if (!subject || !body || !recipient) {
        return res.status(400).json({ success: false, message: "Missing required fields." });
      }

      const mailOptions = {
        from: "oatuissto@gmail.com",
        to: recipient,
        subject: subject,
        text: body,
      };

      await transporter.sendMail(mailOptions);
      console.log("Email sent successfully");
      return res.status(200).json({ success: true, message: "Email sent successfully" });
    } catch (error) {
      console.error("Error sending email:", error);
      return res.status(500).json({ success: false, message: "Failed to send email" });
    }
  });
});
