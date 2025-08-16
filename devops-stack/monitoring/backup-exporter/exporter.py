from prometheus_client import start_http_server, Gauge
import subprocess
import time

BACKUP_HEALTH = Gauge('backup_health', 'Backup health status')

def check_backup_health():
    result = subprocess.run(
        ['/monitoring/healthcheck/backup-health.sh'],
        capture_output=True,
        text=True
    )
    return 1 if result.returncode == 0 else 0

if __name__ == '__main__':
    start_http_server(9191)
    while True:
        BACKUP_HEALTH.set(check_backup_health())
        time.sleep(3600)  # Verificar a cada hora