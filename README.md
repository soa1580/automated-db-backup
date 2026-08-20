# Automated PostgreSQL Backup & Monitoring System

A production-style PostgreSQL backup solution designed to automate database backups, validate backup health, support restoration, expose operational metrics, and provide real-time monitoring through Prometheus and Grafana.

The project also includes Terraform infrastructure configuration and GitHub Actions CI validation for repeatable DevOps workflows.

---

## 📌 Project Overview

Database backups are critical for protecting business data from accidental deletion, corruption, system failures, and operational mistakes.

This project demonstrates how to build an automated PostgreSQL backup and monitoring solution using Linux, Bash, Docker, Python, Prometheus, Grafana, Terraform, and GitHub Actions.

The system automatically creates PostgreSQL database backups, provides restore functionality, monitors backup health, exposes metrics, and visualizes operational information through a Grafana dashboard.

---

## 🏗️ Architecture

```text
                         ┌──────────────────────┐
                         │     PostgreSQL       │
                         │      companydb       │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │    backup.sh         │
                         │ Automated DB Backup   │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │      backups/        │
                         │   PostgreSQL .sql    │
                         │       files          │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │ metrics_exporter.py  │
                         │  Backup Metrics API  │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │     Prometheus       │
                         │   Metrics Storage    │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │       Grafana        │
                         │ Monitoring Dashboard  │
                         └──────────────────────┘


              ┌──────────────────────────────┐
              │        GitHub Actions        │
              │                              │
              │ Bash • Python • Docker       │
              │ Terraform validation        │
              └──────────────────────────────┘

              ┌──────────────────────────────┐
              │          Terraform           │
              │ Infrastructure Configuration │
              └──────────────────────────────┘
```

---

## ✨ Key Features

### Automated PostgreSQL Backups

* Automated PostgreSQL database backup process
* Timestamped SQL backup files
* Backup health validation
* Backup availability monitoring

### Restore Capability

The project includes a dedicated restore script for recovering the PostgreSQL database from a backup file.

### Health Monitoring

The monitoring layer exposes operational metrics including:

* PostgreSQL availability
* Number of available backups
* Latest backup size
* Latest backup age
* Backup availability status

### Prometheus

Prometheus periodically scrapes the custom Python metrics exporter and stores the monitoring data.

### Grafana

Grafana provides a visual dashboard for monitoring the backup system and database availability.

### Docker

Docker Compose is used to run the monitoring components in isolated containers.

### Terraform

Terraform configuration is included for infrastructure provisioning and validation.

### GitHub Actions

The CI workflow automatically validates the project whenever changes are pushed to the `main` branch or submitted through a pull request.

The pipeline validates:

* Bash scripts
* Python syntax
* Docker Compose configuration
* Terraform formatting
* Terraform initialization
* Terraform configuration

---

## 🛠️ Technology Stack

| Technology     | Purpose                                     |
| -------------- | ------------------------------------------- |
| Ubuntu Linux   | Development and execution environment       |
| PostgreSQL     | Database                                    |
| Bash           | Backup, restore and health-check automation |
| Python         | Custom monitoring metrics exporter          |
| Docker         | Containerization                            |
| Docker Compose | Monitoring stack orchestration              |
| Prometheus     | Metrics collection and storage              |
| Grafana        | Monitoring visualization                    |
| Terraform      | Infrastructure as Code                      |
| Git            | Version control                             |
| GitHub         | Source code repository                      |
| GitHub Actions | Continuous Integration                      |

---

## 📁 Project Structure

```text
automated-db-backup/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── backups/
│   └── *.sql
│
├── docs/
│
├── logs/
│   ├── backup.log
│   ├── cron.log
│   ├── health.log
│   └── restore.log
│
├── monitoring/
│   ├── docker-compose.yml
│   ├── health_check.sh
│   ├── metrics_exporter.py
│   └── prometheus/
│       └── prometheus.yml
│
├── scripts/
│   ├── backup.sh
│   └── restore.sh
│
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── .terraform.lock.hcl
│
├── .gitignore
└── README.md
```

> Generated database backups, logs, Terraform state files, Terraform variables, environment files, and private keys are intentionally excluded from version control.

---

## 🚀 Getting Started

### Prerequisites

Install or have access to:

* Ubuntu Linux
* Docker
* Docker Compose
* PostgreSQL
* Git
* Terraform
* Python 3

Verify the major tools:

```bash
docker --version
docker compose version
git --version
terraform version
python3 --version
```

---

## 🗄️ Backup

The primary backup script is:

```bash
scripts/backup.sh
```

Run it with:

```bash
./scripts/backup.sh
```

The script creates timestamped PostgreSQL SQL backup files in:

```text
backups/
```

Example:

```text
companydb_20260819_155146.sql
```

---

## ♻️ Restore

The restore script is:

```bash
scripts/restore.sh
```

Run:

```bash
./scripts/restore.sh
```

The restore process is designed to recover the PostgreSQL database from an available backup.

Always verify the target database and backup file before performing a production restoration.

---

## ❤️ Health Checks

The health-check script is located at:

```bash
monitoring/health_check.sh
```

Run:

```bash
./monitoring/health_check.sh
```

The script helps verify the operational health of the backup environment.

---

## 📊 Monitoring

The monitoring stack consists of:

```text
Python Metrics Exporter
        ↓
    Prometheus
        ↓
      Grafana
```

### Start Monitoring

From the project root:

```bash
docker compose -f monitoring/docker-compose.yml up -d
```

Check the containers:

```bash
docker ps
```

Expected services include:

```text
backup-metrics
backup-prometheus
backup-grafana
```

---

## 🔎 Metrics Exporter

The custom exporter is:

```text
monitoring/metrics_exporter.py
```

It exposes metrics through:

```text
http://localhost:8000/metrics
```

The exporter provides metrics including:

```text
postgres_container_up
backup_count
latest_backup_size_bytes
latest_backup_age_seconds
backup_available
```

---

## 🔭 Prometheus

Prometheus is configured through:

```text
monitoring/prometheus/prometheus.yml
```

The exporter is scraped every 15 seconds.

Prometheus is available at:

```text
http://localhost:9090
```

Check Prometheus readiness:

```bash
curl -s http://localhost:9090/-/ready
```

---

## 📈 Grafana

Grafana is available at:

```text
http://localhost:3000
```

The Grafana dashboard provides a visual overview of the backup and database monitoring metrics.

---

## 🔄 GitHub Actions CI

The project includes:

```text
.github/workflows/ci.yml
```

The workflow runs automatically when changes are pushed to `main` or submitted through a pull request.

### CI Validation

The pipeline performs:

```text
Checkout Repository
       ↓
Terraform Setup
       ↓
Bash Syntax Validation
       ↓
Python Syntax Validation
       ↓
Docker Compose Validation
       ↓
Terraform Format Check
       ↓
Terraform Initialization
       ↓
Terraform Validation
```

A successful workflow produces a green status check on GitHub.

---

## 🏗️ Terraform

Terraform configuration is located in:

```text
terraform/
```

Validate the configuration locally:

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

The Terraform state file and variable file are intentionally excluded from Git.

---

## 🔐 Security Considerations

This project intentionally excludes sensitive operational files from version control.

The `.gitignore` protects:

```text
.env
*.env
.env.*
*.pem
*.key
terraform/*.tfstate
terraform/*.tfstate.*
terraform/terraform.tfvars
backups/*.sql
logs/*.log
```

Never commit:

* Database passwords
* API keys
* Cloud credentials
* Private keys
* Production database dumps
* Terraform state containing sensitive information

Use environment variables or an appropriate secrets-management system for production credentials.

---

## 🧪 Testing

### Bash Validation

```bash
bash -n scripts/backup.sh
bash -n scripts/restore.sh
bash -n monitoring/health_check.sh
```

### Python Validation

```bash
python3 -m py_compile monitoring/metrics_exporter.py
```

### Docker Compose Validation

```bash
docker compose -f monitoring/docker-compose.yml config
```

### Terraform Validation

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

These checks are also performed automatically by GitHub Actions.

---

## 🩺 Troubleshooting

### Check running containers

```bash
docker ps
```

### Check all containers

```bash
docker ps -a
```

### View Prometheus logs

```bash
docker logs backup-prometheus
```

### View Grafana logs

```bash
docker logs backup-grafana
```

### View metrics exporter logs

```bash
docker logs backup-metrics
```

### Test exporter

```bash
curl http://localhost:8000/metrics
```

### Test Prometheus

```bash
curl -s http://localhost:9090/-/ready
```

---

## 📌 Current Project Status

| Component               | Status |
| ----------------------- | ------ |
| PostgreSQL              | ✅      |
| Automated Backup        | ✅      |
| Restore Script          | ✅      |
| Health Check            | ✅      |
| Python Metrics Exporter | ✅      |
| Prometheus              | ✅      |
| Grafana                 | ✅      |
| Docker Compose          | ✅      |
| Terraform               | ✅      |
| GitHub Actions CI       | ✅      |
| Git Repository          | ✅      |
| Documentation           | ✅      |

---

## 🔮 Future Improvements

Potential production enhancements include:

* Remote/object-storage backup retention
* Backup encryption
* Automated backup rotation
* Off-site backup replication
* Alertmanager integration
* Grafana alert notifications
* Persistent Grafana storage
* Persistent Prometheus storage
* Automated restore testing
* Database backup integrity verification
* Cloud-based disaster recovery
* Secrets management using a dedicated secrets manager
* Scheduled infrastructure deployment through CI/CD

---

## 🎯 Project Goal

The goal of this project is to demonstrate practical DevOps and Cloud Engineering skills by combining database administration, Linux automation, containerization, Infrastructure as Code, monitoring, observability, version control, and Continuous Integration into a single working solution.

---

## 👨‍💻 Author

**Saheed Olayode Adedokun**

Cloud / DevOps Engineer | Automation | Infrastructure | Monitoring | Web3

---

## 📄 License

This project is intended for educational, portfolio, and demonstration purposes.
