import StatusBadge from './StatusBadge';

export default function ServiceCard({ service }) {
  return (
    <div className="flex items-center justify-between px-4 py-3 bg-white rounded-lg shadow-sm border border-gray-100">
      <div>
        <p className="font-medium text-gray-900">{service.name}</p>
        {service.description && (
          <p className="text-sm text-gray-500">{service.description}</p>
        )}
      </div>
      <StatusBadge status={service.status} />
    </div>
  );
}
