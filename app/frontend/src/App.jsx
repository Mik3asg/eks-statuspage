import { useEffect, useState } from 'react';
import { fetchServices, fetchIncidents } from './api';
import { useWebSocket } from './hooks/useWebSocket';
import ServiceCard from './components/ServiceCard';
import IncidentList from './components/IncidentList';

const overallStatus = (services) => {
  if (services.some(s => s.status === 'major_outage'))   return { label: 'Major Outage',   bg: 'bg-red-500' };
  if (services.some(s => s.status === 'partial_outage')) return { label: 'Partial Outage', bg: 'bg-orange-500' };
  if (services.some(s => s.status === 'degraded'))       return { label: 'Degraded',       bg: 'bg-yellow-500' };
  return { label: 'All Systems Operational', bg: 'bg-green-500' };
};

export default function App() {
  const [services,  setServices]  = useState([]);
  const [incidents, setIncidents] = useState([]);

  useEffect(() => {
    fetchServices().then(setServices);
    fetchIncidents().then(setIncidents);
  }, []);

  // Apply real-time updates from the backend WebSocket
  useWebSocket(({ type, service, incident }) => {
    if (type === 'STATUS_UPDATE') {
      setServices(prev => prev.map(s => s.id === service.id ? service : s));
    }
    if (type === 'INCIDENT_CREATED') {
      setIncidents(prev => [incident, ...prev]);
    }
  });

  const status = overallStatus(services);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Overall status banner */}
      <div className={`${status.bg} text-white py-10 text-center`}>
        <h1 className="text-3xl font-bold">EKS Status Page</h1>
        <p className="mt-2 text-lg font-medium">{status.label}</p>
      </div>

      <div className="max-w-2xl mx-auto px-4 py-10 space-y-10">
        {/* Services */}
        <section>
          <h2 className="text-lg font-semibold text-gray-700 mb-3">Services</h2>
          <div className="space-y-2">
            {services.map(s => <ServiceCard key={s.id} service={s} />)}
          </div>
        </section>

        {/* Incidents */}
        <section>
          <h2 className="text-lg font-semibold text-gray-700 mb-3">Incidents</h2>
          <IncidentList incidents={incidents} />
        </section>
      </div>
    </div>
  );
}
