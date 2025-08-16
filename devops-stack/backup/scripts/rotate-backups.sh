#!/bin/bash
# Manter 7 backups diários
find /backup/automated/postgres -name "*.sql.gz" -mtime +7 -delete
find /backup/automated/gitea -name "*.tar.gz" -mtime +7 -delete
find /backup/automated/sonarqube -name "*.tar.gz" -mtime +7 -delete