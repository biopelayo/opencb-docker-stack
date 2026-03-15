# 🧬 OpenCB Docker Stack

Complete, production-ready Docker + Docker Compose deployment for the entire OpenCB stack:
- **OpenCGA** - Open Computational Genomics Analysis platform
- **CellBase** - High-performance NoSQL biological database with REST APIs
- **jsorolla** - JavaScript library for genomic data visualization
- **MongoDB** - NoSQL storage engine
- **OpenSearch** - Indexing and search
- **Nginx** - Frontend server

## Quick Start

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 1.29+
- 16GB RAM minimum
- 50GB free disk space

### Clone and Deploy

```bash
git clone https://github.com/biopelayo/opencb-docker-stack.git
cd opencb-docker-stack
docker-compose up -d
```

### Verify Installation

```bash
# Check all services are running
docker-compose ps

# Test OpenCGA REST API
curl http://localhost:8080/opencga/rest/v2/api/version

# Monitor logs
docker-compose logs -f opencga
```

## Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| OpenCGA REST API | http://localhost:8080/opencga/rest/v2 | - |
| Frontend (jsorolla) | http://localhost | - |
| MongoDB Admin | http://localhost:8081 | opencb / opencb_secure_pass |
| OpenSearch | http://localhost:9200 | elastic / OpenSearch@123 |
| pgAdmin | http://localhost:5050 | admin@opencb.local / admin123 |

## File Structure

```
opencb-docker-stack/
├── Dockerfile                  # Backend build (OpenCGA + deps)
├── docker-compose.yml          # Orchestration
├── .env                        # Environment variables
├── entrypoint.sh              # Initialization script
├── config/
│   ├── configuration.yml       # OpenCGA config
│   └── maven-settings.xml      # Maven settings
├── scripts/
│   ├── build-dependencies.sh   # Dependency builder
│   ├── init-mongodb.js         # MongoDB initialization
│   └── health-check.sh         # Health checks
├── frontend/
│   ├── Dockerfile.frontend     # jsorolla build
│   └── nginx.conf              # Nginx configuration
└── README.md
```

## Configuration

Edit `.env` to customize:

```bash
# Database
MONGO_ROOT_USER=opencb
MONGO_ROOT_PASSWORD=your_secure_password

# OpenCGA
OPENCGA_JAVA_MEMORY=8g
LOG_LEVEL=INFO
```

Edit `config/configuration.yml` for detailed OpenCGA settings.

## Building Components

Dependencies are built in this order:
1. java-common-libs
2. biodata  
3. datastore
4. cellbase
5. opencga (main platform)

Each is compiled from OpenCB GitHub develop branch.

## Data Management

### Load Data

```bash
# Create project
docker-compose exec opencga ./bin/opencga.sh projects create --project-id myproject

# Create study
docker-compose exec opencga ./bin/opencga.sh studies create \
  --study-id mystudy --project-id myproject

# Upload files
docker-compose exec opencga ./bin/opencga.sh files upload \
  --study-id myproject:mystudy --file input.vcf

# Index variants
docker-compose exec opencga ./bin/opencga.sh files index \
  --study-id myproject:mystudy --file-id input.vcf
```

### Backup & Restore

```bash
# Backup MongoDB
docker-compose exec mongodb mongodump --out /backup

# Backup volumes
docker run --rm -v opencb-docker-stack_opencga_data:/data \
  -v $(pwd)/backup:/backup \
  busybox tar czf /backup/opencga_data.tar.gz /data
```

## Troubleshooting

### Services won't start

```bash
# Check logs
docker-compose logs opencga
docker-compose logs mongodb

# Rebuild images
docker-compose build --no-cache
```

### MongoDB connection issues

```bash
# Test MongoDB connection
docker-compose exec mongodb mongosh -u opencb -p opencb_secure_pass
```

### Out of memory

Increase Docker memory and adjust `JAVA_OPTS` in `.env`:

```bash
OPENCGA_JAVA_MEMORY=16g
```

## Production Deployment

For production, consider:

1. **Use external databases** instead of containerized
2. **Enable SSL/TLS** in `configuration.yml`
3. **Configure resource limits** in docker-compose.yml
4. **Set up proper logging** and monitoring
5. **Use secrets management** (Docker Secrets or Vault)
6. **Configure backup strategies**

## Documentation

- [OpenCGA Wiki](https://github.com/opencb/opencga/wiki)
- [CellBase Documentation](https://github.com/opencb/cellbase)
- [jsorolla GitHub](https://github.com/opencb/jsorolla)

## Support

For issues:
1. Check logs: `docker-compose logs -f`
2. Review [OpenCGA issues](https://github.com/opencb/opencga/issues)
3. Read [OpenCB documentation](https://docs.opencb.org)

## License

Apache License 2.0 - See LICENSE file

## Maintainers

Based on OpenCB projects maintained by Zetta Genomics
