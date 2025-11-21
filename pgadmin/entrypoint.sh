#!/bin/bash

EMAIL_SANITIZED=$(echo "${PGADMIN_DEFAULT_EMAIL}" | sed 's/@/_/g')

STORAGE_DIR="/var/lib/pgadmin/storage/${EMAIL_SANITIZED}"

mkdir -p "$STORAGE_DIR"

cat <<EOF > ${STORAGE_DIR}/servers.json
{
  "Servers": {
    "1": {
      "Name": "Local PostgreSQL",
      "Group": "Servers",
      "Host": "db",
      "Port": 5432,
      "MaintenanceDB": "postgres",
      "Username": "${POSTGRES_USER}",
      "SSLMode": "prefer"
    }
  }
}
EOF

chown -R pgadmin:pgadmin /var/lib/pgadmin/storage

exec /entrypoint.sh
