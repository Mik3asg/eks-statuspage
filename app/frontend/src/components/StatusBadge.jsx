const styles = {
  operational:    'bg-green-100  text-green-800',
  degraded:       'bg-yellow-100 text-yellow-800',
  partial_outage: 'bg-orange-100 text-orange-800',
  major_outage:   'bg-red-100    text-red-800',
};

const labels = {
  operational:    'Operational',
  degraded:       'Degraded',
  partial_outage: 'Partial Outage',
  major_outage:   'Major Outage',
};

export default function StatusBadge({ status }) {
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-semibold ${styles[status] ?? 'bg-gray-100 text-gray-800'}`}>
      {labels[status] ?? status}
    </span>
  );
}
