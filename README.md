This repo contains Terraform files that deploy a Postgres statefulset to a Kubernetes cluster along with [postgres-exporter](https://github.com/prometheus-community/postgres_exporter) to be used for monitoring. Grafana, Prometheus, and AlertManager were installed using a [Helm chart](https://github.com/prometheus-operator/kube-prometheus) with a modified values.yml.

The values.yml had this added in the [postgres] section to scrape the exporter. This assumes everything is on the same namespace and the name must be changed if in a different namespace. (eg. `postgres-exporter.NAMESPACE.pod.cluster.local`)

```
 additionalScrapeConfigs:
      - job_name: postgres
        static_configs:
          - targets: ['postgres-exporter:9187']
```