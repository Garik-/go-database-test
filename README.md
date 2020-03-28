# Platform Event Mock
Creates mock events in the database
## Config
See `.env` file
## Environment
Start database and import SQL dump
```BASH
$ docker-compose up -d
$ chmod +x import.sh && ./import.sh
```
## Prometheus
For example install https://github.com/stefanprodan/dockprom

Append in prometheus.yml `scrape_configs`
```YAML
- job_name: 'actionmonitor-eventmock'
  scrape_interval: 5s
  static_configs:
    - targets: [METRICS_ADDR]
```
see `METRICS_ADDR` in .env

An example prometheus query that shows the general RPS
```
sum(rate(events_total[1m]))
```
