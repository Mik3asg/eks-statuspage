const db = require('../db');

// --- Services ---

const getAllServices = () =>
  db.query('SELECT * FROM services ORDER BY name ASC');

const getServiceById = (id) =>
  db.query('SELECT * FROM services WHERE id = $1', [id]);

const createService = ({ name, description, status = 'operational' }) =>
  db.query(
    'INSERT INTO services (name, description, status) VALUES ($1, $2, $3) RETURNING *',
    [name, description, status]
  );

const updateServiceStatus = (id, status) =>
  db.query(
    'UPDATE services SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
    [status, id]
  );

// --- Incidents ---

const getAllIncidents = () =>
  db.query('SELECT * FROM incidents ORDER BY created_at DESC');

const createIncident = ({ service_id, title, description, status = 'investigating' }) =>
  db.query(
    'INSERT INTO incidents (service_id, title, description, status) VALUES ($1, $2, $3, $4) RETURNING *',
    [service_id, title, description, status]
  );

module.exports = {
  getAllServices,
  getServiceById,
  createService,
  updateServiceStatus,
  getAllIncidents,
  createIncident,
};
