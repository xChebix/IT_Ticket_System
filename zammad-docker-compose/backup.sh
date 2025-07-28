#!/bin/bash
# Zammad Docker Volume Backup Script
# Backs up all volumes with timestamp and compression

# Configuration
BACKUP_DIR="$HOME/.backups/zammad_volumes"
LOG_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d).log"
VOLUMES=(
    "zammad-docker-compose_elasticsearch-data"
    "zammad-docker-compose_postgresql-data"
    "zammad-docker-compose_redis-data"
    "zammad-docker-compose_zammad-backup"
    "zammad-docker-compose_zammad-storage"
)

# Create backup directory
mkdir -p "$BACKUP_DIR" || { echo "Failed to create backup directory"; exit 1; }

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Main backup process
log "Starting Zammad volume backup..."

for VOLUME in "${VOLUMES[@]}"; do
    BACKUP_FILE="$BACKUP_DIR/${VOLUME}_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    log "Backing up volume $VOLUME to $BACKUP_FILE..."
    
    if ! docker volume inspect "$VOLUME" >/dev/null 2>&1; then
        log "Warning: Volume $VOLUME does not exist, skipping"
        continue
    fi

    if docker run --rm \
        -v "$VOLUME":/source \
        -v "$BACKUP_DIR":/backup \
        alpine \
        tar czf "/backup/$(basename "$BACKUP_FILE")" -C /source . \
        >> "$LOG_FILE" 2>&1; then
        
        log "Successfully backed up $VOLUME"
        # Verify backup was created
        if [ ! -f "$BACKUP_FILE" ]; then
            log "Error: Backup file not created for $VOLUME"
        else
            log "Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"
        fi
    else
        log "Error: Failed to backup $VOLUME"
    fi
done

# Retention policy (keep last 7 backups)
find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +7 -delete -print >> "$LOG_FILE"

# Final status
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -newer "$LOG_FILE" | wc -l)
log "Backup completed. $BACKUP_COUNT volumes backed up."
log "Disk usage: $(du -sh "$BACKUP_DIR")"

exit 0
