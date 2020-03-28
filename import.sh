#!/bin/sh
export $(cat .env | sed 's/#.*//g' | xargs)
cat database.sql | docker exec -i $POSTGRES_CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB