#!/bin/bash
set -e

# Creates the European shard database on first initialization
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE deskbolic_de_production'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'deskbolic_de_production')\gexec
    GRANT ALL PRIVILEGES ON DATABASE deskbolic_de_production TO "$POSTGRES_USER";
EOSQL
