require('dotenv').config();

const http    = require('http');
const express = require('express');
const { WebSocketServer } = require('ws');
const servicesRouter = require('./routes/services');

const app    = express();
const server = http.createServer(app);

// WebSocket server shares the same HTTP server — no separate port needed
const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'CONNECTED' }));
});

app.use(express.json());

// Health check — Kubernetes liveness probe hits this
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.use('/api', servicesRouter(wss));

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
