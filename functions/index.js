const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

const OTP_TTL_MS = 5 * 60 * 1000;

function generateCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function otpDocId(channel, email, phone) {
  const key = channel === "email" ? email.toLowerCase() : phone;
  return `${channel}_${key}`;
}

async function storeOtp(channel, email, phone, code) {
  const id = otpDocId(channel, email, phone);
  await db.collection("otp_verifications").doc(id).set({
    code,
    channel,
    email,
    phone,
    expiresAt: Date.now() + OTP_TTL_MS,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return id;
}

async function sendEmail(to, code, username) {
  const host = process.env.SMTP_HOST;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM || "HANDee <noreply@handee.app>";

  if (!host || !user || !pass) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Email SMTP is not configured. Set SMTP_HOST, SMTP_USER, SMTP_PASS.",
    );
  }

  const transporter = nodemailer.createTransport({
    host,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === "true",
    auth: { user, pass },
  });

  await transporter.sendMail({
    from,
    to,
    subject: "Your HANDee verification code",
    text: `Hi ${username || "there"},\n\nYour HANDee verification code is: ${code}\n\nIt expires in 5 minutes.`,
    html: `<p>Hi ${username || "there"},</p><p>Your HANDee verification code is:</p><h2>${code}</h2><p>Expires in 5 minutes.</p>`,
  });
}

async function sendTwilio(channel, toPhone, code) {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  const smsFrom = process.env.TWILIO_SMS_FROM;
  const waFrom = process.env.TWILIO_WHATSAPP_FROM;

  if (!sid || !token) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Twilio is not configured. Set TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN.",
    );
  }

  const twilio = require("twilio")(sid, token);
  const body = `Your HANDee verification code is ${code}. It expires in 5 minutes.`;

  if (channel === "whatsapp") {
    if (!waFrom) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Set TWILIO_WHATSAPP_FROM (e.g. whatsapp:+14155238886).",
      );
    }
    await twilio.messages.create({
      from: waFrom.startsWith("whatsapp:") ? waFrom : `whatsapp:${waFrom}`,
      to: toPhone.startsWith("whatsapp:") ? toPhone : `whatsapp:${toPhone}`,
      body,
    });
    return;
  }

  if (!smsFrom) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Set TWILIO_SMS_FROM for SMS delivery.",
    );
  }
  await twilio.messages.create({ from: smsFrom, to: toPhone, body });
}

exports.sendVerificationCode = functions.https.onCall(async (data) => {
  const channel = (data.channel || "").toString();
  const email = (data.email || "").toString().trim();
  const phone = (data.phone || "").toString().trim();
  const username = (data.username || "").toString().trim();

  if (!["email", "whatsapp", "sms"].includes(channel)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid channel.");
  }
  if (channel === "email" && !email) {
    throw new functions.https.HttpsError("invalid-argument", "Email required.");
  }
  if (channel !== "email" && !phone) {
    throw new functions.https.HttpsError("invalid-argument", "Phone required.");
  }

  const code = generateCode();
  await storeOtp(channel, email, phone, code);

  if (channel === "email") {
    await sendEmail(email, code, username);
    return {
      success: true,
      message: `Code sent to ${email}`,
      masked: maskEmail(email),
    };
  }

  await sendTwilio(channel, phone, code);
  return {
    success: true,
    message: `Code sent via ${channel}`,
    masked: maskPhone(phone),
  };
});

exports.checkVerificationCode = functions.https.onCall(async (data) => {
  const channel = (data.channel || "").toString();
  const email = (data.email || "").toString().trim();
  const phone = (data.phone || "").toString().trim();
  const code = (data.code || "").toString().trim();

  const id = otpDocId(channel, email, phone);
  const snap = await db.collection("otp_verifications").doc(id).get();
  if (!snap.exists) {
    return { valid: false, message: "No code found. Request a new one." };
  }

  const record = snap.data();
  if (Date.now() > record.expiresAt) {
    await snap.ref.delete();
    return { valid: false, message: "Code expired. Request a new one." };
  }
  if (record.code !== code) {
    return { valid: false, message: "Invalid code." };
  }

  await snap.ref.delete();
  return { valid: true };
});

function maskEmail(email) {
  const [user, domain] = email.split("@");
  if (!domain) return email;
  return `${user[0]}***@${domain}`;
}

function maskPhone(phone) {
  const digits = phone.replace(/\D/g, "");
  if (digits.length < 4) return phone;
  return `***${digits.slice(-4)}`;
}
