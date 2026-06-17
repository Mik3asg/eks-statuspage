const statusColor = {
  investigating: 'text-red-600',
  identified:    'text-orange-600',
  monitoring:    'text-yellow-600',
  resolved:      'text-green-600',
};

export default function IncidentList({ incidents }) {
  if (!incidents.length) {
    return <p className="text-sm text-gray-500">No incidents reported.</p>;
  }

  return (
    <ul className="space-y-3">
      {incidents.map((inc) => (
        <li key={inc.id} className="bg-white rounded-lg shadow-sm border border-gray-100 px-4 py-3">
          <div className="flex items-center justify-between">
            <p className="font-medium text-gray-900">{inc.title}</p>
            <span className={`text-xs font-semibold capitalize ${statusColor[inc.status] ?? 'text-gray-600'}`}>
              {inc.status}
            </span>
          </div>
          {inc.description && (
            <p className="mt-1 text-sm text-gray-500">{inc.description}</p>
          )}
          <p className="mt-1 text-xs text-gray-400">
            {new Date(inc.created_at).toLocaleString()}
          </p>
        </li>
      ))}
    </ul>
  );
}
