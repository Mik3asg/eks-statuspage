const { Router } = require('express');
const model = require('../models/service');

const router = Router();

// Broadcast a status update to all connected WebSocket clients
const broadcast = (wss, payload) => {
  wss.clients.forEach((client) => {
    if (client.readyState === 1) client.send(JSON.stringify(payload));
  });
};

module.exports = (wss) => {
  // Services
  router.get('/services', async (_req, res) => {
    const { rows } = await model.getAllServices();
    res.json(rows);
  });

  router.get('/services/:id', async (req, res) => {
    const { rows } = await model.getServiceById(req.params.id);
    if (!rows.length) return res.status(404).json({ error: 'Service not found' });
    res.json(rows[0]);
  });

  router.post('/services', async (req, res) => {
    const { rows } = await model.createService(req.body);
    res.status(201).json(rows[0]);
  });

  router.put('/services/:id', async (req, res) => {
    const { rows } = await model.updateServiceStatus(req.params.id, req.body.status);
    if (!rows.length) return res.status(404).json({ error: 'Service not found' });
    // Push real-time update to all connected clients
    broadcast(wss, { type: 'STATUS_UPDATE', service: rows[0] });
    res.json(rows[0]);
  });

  // Incidents
  router.get('/incidents', async (_req, res) => {
    const { rows } = await model.getAllIncidents();
    res.json(rows);
  });

  router.post('/incidents', async (req, res) => {
    const { rows } = await model.createIncident(req.body);
    broadcast(wss, { type: 'INCIDENT_CREATED', incident: rows[0] });
    res.status(201).json(rows[0]);
  });

  return router;
};
