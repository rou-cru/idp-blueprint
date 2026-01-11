import http from 'k6/http';
import { check } from 'k6';

const TARGET_URL = __ENV.TARGET_URL || 'https://backstage.192-168-65-16.nip.io';

export const options = {
  scenarios: {
    stress: {
      executor: 'constant-vus',
      vus: 300,
      duration: '2m',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<200'], // Goal: p95 should be under 200ms
  },
  insecureSkipTLSVerify: true,
};

export default function () {
  // Catalog API is heavier than the home page
  const res = http.get(`${TARGET_URL}/api/catalog/entities`);
  
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  // No sleep - maximum pressure
}
