import crypto from 'crypto';
import express from 'express';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT || 3847);
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const MESSAGES_FILE = path.join(DATA_DIR, 'messages.jsonl');
const RATE_FILE = path.join(DATA_DIR, 'ratelimit.json');
const RATE_LIMIT_MS = 5 * 60 * 1000;
const MAX_NAME = 40;
const MAX_MESSAGE = 500;
const MAX_MESSAGES = 200;
const SALT = process.env.GUESTBOOK_SALT || 'guthib-guestbook';

fs.mkdirSync(DATA_DIR, { recursive: true });

const app = express();
app.use(express.json({ limit: '4kb' }));

function clientIp(req) {
  const forwarded = req.headers['x-real-ip'] || req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string') {
    return forwarded.split(',')[0].trim();
  }
  return req.socket.remoteAddress || 'unknown';
}

function ipHash(ip) {
  return crypto.createHash('sha256').update(`${ip}:${SALT}`).digest('hex').slice(0, 16);
}

function readRateLimits() {
  try {
    return JSON.parse(fs.readFileSync(RATE_FILE, 'utf8'));
  } catch {
    return {};
  }
}

function writeRateLimits(limits) {
  fs.writeFileSync(RATE_FILE, JSON.stringify(limits));
}

function cleanText(value, maxLen) {
  return String(value || '')
    .replace(/[\u0000-\u001f\u007f]/g, '')
    .trim()
    .slice(0, maxLen);
}

function readMessages(limit = MAX_MESSAGES) {
  if (!fs.existsSync(MESSAGES_FILE)) return [];

  const lines = fs.readFileSync(MESSAGES_FILE, 'utf8').trim().split('\n').filter(Boolean);
  const messages = [];

  for (let i = lines.length - 1; i >= 0 && messages.length < limit; i -= 1) {
    try {
      messages.push(JSON.parse(lines[i]));
    } catch {
      // skip corrupt lines
    }
  }

  return messages;
}

function appendMessage(message) {
  fs.appendFileSync(MESSAGES_FILE, `${JSON.stringify(message)}\n`, 'utf8');
}

app.get('/api/health', (_req, res) => {
  res.json({ ok: true });
});

app.get('/api/messages', (req, res) => {
  const limit = Math.min(Number(req.query.limit) || MAX_MESSAGES, MAX_MESSAGES);
  res.json({ messages: readMessages(limit) });
});

app.post('/api/messages', (req, res) => {
  const body = req.body || {};

  if (body.website) {
    res.status(201).json({ ok: true });
    return;
  }

  const name = cleanText(body.name, MAX_NAME);
  const message = cleanText(body.message, MAX_MESSAGE);

  if (!name || !message) {
    res.status(400).json({ error: 'Name and message are required.' });
    return;
  }

  const hash = ipHash(clientIp(req));
  const limits = readRateLimits();
  const lastPost = limits[hash] || 0;

  if (Date.now() - lastPost < RATE_LIMIT_MS) {
    res.status(429).json({ error: 'Easy there — one hello every 5 minutes.' });
    return;
  }

  const entry = {
    id: crypto.randomUUID(),
    name,
    message,
    createdAt: new Date().toISOString(),
  };

  appendMessage(entry);
  limits[hash] = Date.now();
  writeRateLimits(limits);

  res.status(201).json({ message: entry });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`guestbook listening on 127.0.0.1:${PORT}`);
});
