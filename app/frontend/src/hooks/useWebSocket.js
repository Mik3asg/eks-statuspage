import { useEffect } from 'react';

const WS_URL = `${window.location.protocol === 'https:' ? 'wss' : 'ws'}://${window.location.host}/ws`;

export function useWebSocket(onMessage) {
  useEffect(() => {
    const ws = new WebSocket(WS_URL);
    ws.onmessage = (e) => onMessage(JSON.parse(e.data));
    // Reconnect once on unexpected close
    ws.onclose = () => setTimeout(() => new WebSocket(WS_URL), 3000);
    return () => ws.close();
  }, []);
}
