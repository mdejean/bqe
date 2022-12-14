#!/bin/bash
APP_TOKEN=r3OmPQwf2v2FV7lJmUsZKerX0

last_d=`psql crashes --tuples-only -A -c "select to_char(max(data_as_of), 'YYYY-MM-DD\"T\"HH24:MI:SS') from link_speed"`
curl -H "X-App-Token: $APP_TOKEN" 'https://data.cityofnewyork.us/resource/i4gi-tjb9.csv?$limit=1000000000&$select=link_id,data_as_of,status,speed,travel_time&$where=data_as_of>"'$last_d'"' --output link_speed.csv
ogr2ogr -f "PostgreSQL" PG:"dbname=crashes" -append -nln link_speed_import -oo AUTODETECT_TYPE=YES link_speed.csv
psql crashes --csv -f bqe_agg.sql -o bqe_agg.csv
