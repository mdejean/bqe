with ls as
(
    select
        link_id,
        speed,
        travel_time,
        to_char(data_as_of, 'HH24') h,
        to_char(data_as_of, 'YYYY-MM') ym,
        to_char(data_as_of, 'DD') d,
        case when extract(dow from data_as_of) in (0, 6) then 1 else 0 end weekend
    from link_speed
    where status = 0 
    and data_as_of > '2018-01-01'
)
select
    quartiles.link_id,
    quartiles.weekend,
    quartiles.h,
    quartiles.ym,
    speed_worst,
    travel_worst,
    quartiles.speed[1] speed_25,
    quartiles.speed[2] speed_50,
    quartiles.speed[3] speed_75,
    quartiles.travel_time[1] travel_25,
    quartiles.travel_time[2] travel_50,
    quartiles.travel_time[3] travel_75
from (
    select
        link_id,
        percentile_cont(array[0.25, 0.5, 0.75]) within group (order by speed) speed,
        percentile_cont(array[0.25, 0.5, 0.75]) within group (order by travel_time) travel_time,
        weekend,
        h,
        ym
    from ls
    group by link_id, weekend, h, ym
) quartiles
join (
    select
        link_id,
        weekend,
        h,
        ym,
        min(speed) speed_worst,
        max(travel_time) travel_worst
    from (
        select 
            link_id,
            round(avg(speed)) speed,
            round(avg(travel_time)) travel_time,
            weekend,
            h,
            ym,
            d
        from ls 
        group by link_id, weekend, h, ym, d
    ) s
    group by link_id, weekend, h, ym
) hourly_avg on quartiles.link_id = hourly_avg.link_id
and quartiles.weekend = hourly_avg.weekend
and quartiles.h = hourly_avg.h
and quartiles.ym = hourly_avg.ym
left join link l on quartiles.link_id = l.link_id
where quartiles.link_id in ('4616257', '4616339', '4616340', '4616229', '4616271', '4616223')
-- link_name in (
          -- 'GOW N 9TH STREET - ATLANTIC AVENUE',
          -- 'BQE S LEONARD STREET - ATLANTIC AVENUE',
          -- 'BQE N ATLANTIC AVENUE - LEONARD STREET',
          -- 'BQE S - GOW S ALTANTIC AVENUE - 9TH STREET',
          -- 'BQE N Atlantic Ave - BKN Bridge Manhattan Side',
          -- 'BQE N Atlantic Ave - MAN Bridge Manhattan Side'
          -- )
order by link_name, quartiles.ym desc, quartiles.weekend, quartiles.h;
