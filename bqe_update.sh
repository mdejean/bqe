#!/bin/bash
set -e

APP_TOKEN=r3OmPQwf2v2FV7lJmUsZKerX0

last_d=`psql crashes --tuples-only -A -c "select to_char(max(data_as_of), 'YYYY-MM-DD\"T\"HH24:MI:SS') from link_speed"`
echo "Getting data since $last_d"
curl -H "X-App-Token: $APP_TOKEN" 'https://data.cityofnewyork.us/resource/i4gi-tjb9.csv?$limit=1000000000&$select=link_id,data_as_of,status,speed,travel_time&$where=data_as_of>"'$last_d'"' --output link_speed.csv
curl -H "X-App-Token: $APP_TOKEN" 'https://data.cityofnewyork.us/resource/6a2s-2t65.csv?$limit=1000000000&$select=sid,median_calculation_timestamp,n_samples,median_speed_fps,median_tt_sec&$where=median_calculation_timestamp>"'$last_d'"' --output mim_speed.csv
echo "Loading to postgres"
psql crashes -v ON_ERROR_STOP=1 <<EOF
truncate table link_speed_import;
\copy link_speed_import(link_id, data_as_of, status, speed, travel_time) from 'link_speed.csv' delimiter ',' csv header
commit;
insert into link_speed (
    link_id,
    data_as_of,
    status,
    speed,
    travel_time
) select
    link_id,
    data_as_of,
    status,
    speed,
    travel_time
from link_speed_import
on conflict (link_id, data_as_of) do nothing;
commit;

truncate table mim_speed_import;
\copy mim_speed_import (sid, median_calculation_timestamp, n_samples, median_speed_fps, median_tt_sec) from 'mim_speed.csv' delimiter ',' csv header
insert into link_speed (
    link_id,
    data_as_of,
    status,
    speed,
    travel_time
) select
    sid,
    median_calculation_timestamp,
    n_samples - 1,
    median_speed_fps * 0.6818,
    median_tt_sec
from mim_speed_import
on conflict (link_id, data_as_of) do nothing;
\q
EOF
echo "Creating summary file"
psql crashes --csv -f bqe_agg.sql -o bqe_agg.csv
