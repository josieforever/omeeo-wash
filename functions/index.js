const functions = require("firebase-functions/v2");
const nodemailer = require("nodemailer");

const admin = require("firebase-admin");
admin.initializeApp();

// ✅ Configure the email transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "yourgmail@gmail.com",
    pass: "your-app-password", // NOT your Gmail password
  },
});

exports.sendWelcomeEmail = functions.auth.user().onCreate(async (user) => {
  const email = user.email;
  const displayName = user.displayName || "there";

  const mailOptions = {
    from: '"Ommeo Support" <yourgmail@gmail.com>',
    to: email,
    subject: "🎉 Welcome to Ommeo!",
    text: `Hi ${displayName}, welcome to Ommeo! We're excited to have you on board.`,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`✅ Welcome email sent to ${email}`);
  } catch (err) {
    console.error("❌ Error sending welcome email:", err);
  }
});
