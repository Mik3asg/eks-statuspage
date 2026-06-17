const BASE = '/api';

export const fetchServices  = () => fetch(`${BASE}/services`).then(r => r.json());
export const fetchIncidents = () => fetch(`${BASE}/incidents`).then(r => r.json());
