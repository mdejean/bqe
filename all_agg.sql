with ls as
(
    select
        link_id,
        speed,
        travel_time,
        data_as_of,
        to_char(data_as_of, 'HH24') h,
        case when data_as_of > '2025-01-01' then date_trunc('day', data_as_of) else date_trunc('year', data_as_of) end d,
        case when extract(dow from data_as_of) in (0, 6) then 1 else 0 end weekend
    from link_speed
    where status >= 0 
    and data_as_of > '2018-01-01'
    and data_as_of not between '2025-01-01' and '2025-01-05'
)
select
    link_name,
    quartiles.weekend,
    quartiles.h,
    to_char(quartiles.d, 'YYYY-MM-DD') ymd,
    quartiles.speed[1] speed_25,
    quartiles.speed[2] speed_50,
    quartiles.speed[3] speed_75,
    quartiles.travel_time[1] travel_25,
    quartiles.travel_time[2] travel_50,
    quartiles.travel_time[3] travel_75
from link l
join (
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
) quartiles on quartiles.link_id = l.link_id
where 1=1
and l.link_id in (
    select
        link_id
    from ls
    group by link_id
    having min(data_as_of) < '2025-01-01'
    and max(data_as_of) > '2025-01-01'
)
and quartiles.c > 5
-- and link_name in (
          -- 'GOW N 9TH STREET - ATLANTIC AVENUE',
          -- 'BQE S LEONARD STREET - ATLANTIC AVENUE',
          -- 'BQE N ATLANTIC AVENUE - LEONARD STREET',
          -- 'BQE S - GOW S ALTANTIC AVENUE - 9TH STREET',
          -- 'BQE N Atlantic Ave - BKN Bridge Manhattan Side',
          -- 'BQE N Atlantic Ave - MAN Bridge Manhattan Side'
          -- )
order by link_name, quartiles.d desc, quartiles.weekend, quartiles.h;
