with ls as
(
    select
        link_id,
        speed,
        travel_time,
        data_as_of,
        to_char(data_as_of, 'HH24') h,
        --case when data_as_of > '2025-01-01' then date_trunc('day', data_as_of) else date_trunc('year', data_as_of) end d,
        date_trunc('year', data_as_of) d,
        case when extract(dow from data_as_of) in (0, 6) then 1 else 0 end weekend
    from link_speed
    where status >= 0
    and speed > 0
    and speed < 100
    and data_as_of > '2018-01-01'
    and extract(week from data_as_of) * 10 + extract(isodow from data_as_of) between 17 and (
        select extract(week from max(data_as_of)) * 10 + extract(isodow from max(data_as_of)) from link_speed
    )
)
select
    quartiles.link_id,
    quartiles.weekend,
    quartiles.h,
    to_char(quartiles.d, 'YYYY-MM-DD') ymd,
    round(quartiles.speed[2]::numeric, 2) speed_50,
    round(quartiles.travel_time[2]::numeric, 2) travel_50
from (
    select
        link_id,
        percentile_cont(array[0.25, 0.5, 0.75]) within group (order by speed) speed,
        percentile_cont(array[0.25, 0.5, 0.75]) within group (order by travel_time) travel_time,
        weekend,
        h,
        d,
        count(1) c
    from ls
    group by link_id, weekend, h, d
) quartiles
left join link l on quartiles.link_id = l.link_id
where 1=1
and quartiles.link_id in (
    select
        link_id
    from ls
    group by link_id
    having min(data_as_of) < '2025-01-01'
    and max(data_as_of) > '2025-01-01'
)
and quartiles.c > 2
order by link_name, quartiles.d desc, quartiles.weekend, quartiles.h;
