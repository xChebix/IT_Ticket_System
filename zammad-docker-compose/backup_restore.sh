#!/bin/bash
# Restore latest .tar.gz backup for each Zammad Docker volume

# Configuration
BACKUP_DIR="$HOME/.backups/zammad_volumes"
VOLUMES=(
    "zammad-docker-compose_elasticsearch-data"
    "zammad-docker-compose_postgresql-data"
    "zammad-docker-compose_redis-data"
    "zammad-docker-compose_zammad-backup"
    "zammad-docker-compose_zammad-storage"
)

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "♻️ Starting restore from latest backups in: $BACKUP_DIR"

for VOLUME in "${VOLUMES[@]}"; do
    BACKUP_FILE=$(ls -1t "$BACKUP_DIR"/${VOLUME}_*.tar.gz 2>/dev/null | head -n 1)

    if [ -z "$BACKUP_FILE" ]; then
        log "⚠️  No backup file found for volume: $VOLUME"
        continue
    fi

    if ! docker volume inspect "$VOLUME" >/dev/null 2>&1; then
        log "🔧 Volume $VOLUME does not exist. Creating..."
        docker volume create "$VOLUME"
    fi

    log "🔁 Restoring $VOLUME from: $(basename "$BACKUP_FILE")"

    docker run --rm \
        -v "$VOLUME":/restore-target \
        -v "$BACKUP_DIR":/backup \
        alpine \
        sh -c "rm -rf /restore-target/* && tar xzf /backup/$(basename "$BACKUP_FILE") -C /restore-target"

    log "✅ Restore complete for $VOLUME"
done

log "🎉 All volumes processed. You may now start your containers."

exit 0
