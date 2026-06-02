import http from 'k6/http';
import { check } from 'k6';

// P6: smoke test enforcing the perf budget.
export const options = {
  vus: 50,
  duration: '1m',
  thresholds: {
    http_req_duration: ['p(95)<250', 'p(99)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:5111';

export default function () {
  const res = http.get(`${BASE_URL}/api/v1/projects/${crypto.randomUUID()}/stats`);
  check(res, {
    'status 200': (r) => r.status === 200,
    'has body':   (r) => r.body && r.body.length > 0,
  });
}
