# 3‑Tier E‑commerce on Kubernetes with Prometheus Monitoring

This bundle deploys a simple 3‑tier e‑commerce application (frontend, backend API, PostgreSQL DB) on a Kubernetes cluster, instrumented with Prometheus via the Prometheus Operator (kube‑prometheus‑stack) and basic alerting.

## Prerequisites

- Kubernetes v1.24+
- `kubectl` and `helm` installed
- An Ingress controller (e.g., NGINX Ingress)
- A default `StorageClass` for persistent volumes
- `metrics-server` installed (for HPA)

## 1) Install monitoring stack (Prometheus + Grafana)

```bash
kubectl create namespace monitoring
kubectl label namespace monitoring kube-monitoring=true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring       --set grafana.defaultDashboardsEnabled=true
```

Grafana admin password:
```bash
kubectl -n monitoring get secret kube-prometheus-stack-grafana       -o jsonpath="{.data.admin-password}" | base64 --decode && echo
```

Access Grafana locally:
```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# then open http://localhost:3000
```

## 2) Deploy the application

Apply the manifests in order:
```bash
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-postgres-secret.yaml
kubectl apply -f 02-postgres-statefulset.yaml
kubectl apply -f 03-postgres-service.yaml
kubectl apply -f 10-backend-configmap.yaml
kubectl apply -f 11-backend-deployment.yaml
kubectl apply -f 12-backend-service.yaml
kubectl apply -f 13-backend-servicemonitor.yaml
kubectl apply -f 20-frontend-deployment.yaml
kubectl apply -f 21-frontend-service.yaml
kubectl apply -f 30-ingress.yaml
kubectl apply -f 40-network-policies.yaml
kubectl apply -f 50-hpa-backend.yaml
kubectl apply -f 60-pdb.yaml
kubectl apply -f 70-postgres-servicemonitor.yaml
kubectl apply -f 80-prometheus-rules.yaml
```

## 3) Build & push your app images

The manifests reference `your-registry/frontend:1.0.0` and `your-registry/backend:1.0.0`. Replace these with images in a registry your cluster can pull from.

### Backend – Node.js metrics example

Instrument your backend with Prometheus using `prom-client` and expose `/metrics` on the same port as your API:

```js
// server.js
const express = require('express');
const client = require('prom-client');
const app = express();

// Default metrics
client.collectDefaultMetrics();

// Custom metrics
const httpRequests = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method','route','status']
});

app.use((req, res, next) => {
  res.on('finish', () => {
    httpRequests.inc({method: req.method, route: req.path, status: res.statusCode});
  });
  next();
});

app.get('/healthz', (req,res)=>res.status(200).send('ok'));
app.get('/readyz', (req,res)=>res.status(200).send('ready'));
app.get('/api/products', (req,res)=>res.json([{id:1,name:'Laptop'},{id:2,name:'Phone'}]));

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

app.listen(8080, () => console.log('Backend listening on 8080'));
```

### Frontend
Serve static assets via NGINX (or any SPA framework). Configure it to call the backend at `http://backend.ecommerce.svc.cluster.local:8080` or via Ingress host.

## 4) Ingress & DNS

Update `30-ingress.yaml` host to your domain (e.g., `shop.yourdomain.com`). If you don’t have DNS, use a wildcard like `127.0.0.1.nip.io` and point it to your LoadBalancer IP.

## 5) Network security

NetworkPolicies restrict DB access to backend only and allow Prometheus (from `monitoring` namespace) to scrape backend metrics. Ensure the `monitoring` namespace has label `kube-monitoring=true` (we add it above).

## 6) Autoscaling

The backend HPA scales between 2 and 10 pods at ~70% CPU utilization. Make sure `metrics-server` is installed.

## 7) Observability

- **ServiceMonitors** are defined for backend (`/metrics` on port 8080) and PostgreSQL exporter (port 9187).
- **Alerts**: Basic alerts for high backend 5xx rate and postgres exporter down.
- **Grafana**: Use built-in Kubernetes dashboards and import app-specific dashboards if needed.

## 8) Verification

```bash
kubectl -n ecommerce get pods
kubectl -n ecommerce get svc
# Hit the app
curl -I http://<INGRESS-HOST>/
curl http://<INGRESS-HOST>/api/products
# Check metrics
kubectl -n ecommerce port-forward svc/backend 8080:8080
curl http://localhost:8080/metrics | head
```

## 9) Troubleshooting

- Ingress returns 404: verify host and paths, and NGINX Ingress is installed.
- HPA not scaling: ensure `metrics-server` is running (`kubectl get pods -n kube-system`).
- Prometheus not scraping: confirm ServiceMonitors exist and `release: kube-prometheus-stack` label matches your Helm release name.
- DB connection issues: check `DATABASE_URL` in `backend-config` and `postgres` Service DNS.

## Notes

- Storage: Edit `02-postgres-statefulset.yaml` storage request if needed.
- Resources: Tune requests/limits per your cluster size.
- Security: Replace default secrets/passwords and consider using `sealed-secrets`/external secret managers.
