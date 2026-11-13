-- Demo data for the demo club. The server runs it in demo mode (VELOMINE__DEMO__ENABLED), after it has created the
-- demo accounts and their club: see DemoData.cs.
--
-- It does not create accounts: it uses the club that already exists (the one with the most members) and its
-- memberships. It adds bikes, components, rides with full streams, power bests, laps, goals, wellbeing,
-- privacy settings, sharing grants, view log entries and notifications.
--
-- Idempotent: if any member of that club already has a bike or a ride, it does nothing.
--
-- The rides are generated at 1 Hz, so their streams, laps and power bests are consistent with each other and
-- with the metrics stored on the ride. Everything is synthetic.

CREATE OR REPLACE FUNCTION pg_temp.demo_seed_ride(
    p_user uuid,
    p_bike uuid,
    p_start timestamptz,
    p_offset int,
    p_kind text,
    p_minutes int,
    p_intensity float8,
    p_discipline text,
    p_environment text,
    p_laps int,
    p_gps boolean,
    p_base_speed float8,
    p_ftp int,
    p_max_hr int,
    p_seed int
) RETURNS void LANGUAGE plpgsql AS $ride$
DECLARE
    v_n int;
    v_i int;
    v_seconds int;
    v_p0 float8;
    v_effort float8;
    v_terrain float8;
    v_power_w float8;
    v_speed_ms float8;
    v_ratio float8;
    v_distance_total float8 := 0;
    v_prev_hr float8;
    v_target_hr float8;
    v_hr_val float8;
    v_cad float8;
    v_hill float8;
    v_loop_len float8;
    v_radius float8;
    v_lat0 float8;
    v_lon0 float8;
    v_frac float8;
    v_theta float8;
    v_r float8;
    v_sum_power float8 := 0;
    v_max_power int := 0;
    v_sum_hr float8 := 0;
    v_max_hr_actual int := 0;
    v_sum_cad float8 := 0;
    v_max_speed float8 := 0;
    v_window_sum float8;
    v_fourth_sum float8 := 0;
    v_windows int := 0;
    v_np int;
    v_if float8;
    v_tss float8;
    v_trimp float8 := 0;
    v_zone int;
    v_hr_ratio float8;
    v_ref_alt float8;
    v_gain float8 := 0;
    v_loss float8 := 0;
    v_delta float8;
    v_durations int[] := ARRAY[1, 5, 15, 30, 60, 120, 300, 600, 1200, 1800, 3600];
    v_d int;
    v_best float8;
    v_lap int;
    v_lap_start int;
    v_lap_end int;
    v_lap_count int;
    v_lap_power float8;
    v_lap_hr float8;
    v_lap_cad float8;
    v_lap_max_power int;
    v_lap_max_hr int;
    v_lap_max_speed float8;
    v_lap_gain float8;
    v_lap_ref float8;
    v_lap_distance float8;
    v_ride_id uuid;
    v_time double precision[];
    v_lat double precision[];
    v_lon double precision[];
    v_alt real[];
    v_speed real[];
    v_dist real[];
    v_hr smallint[];
    v_power smallint[];
    v_cadence smallint[];
    v_temp smallint[];
BEGIN
    v_n := p_minutes * 60 + 1;
    v_p0 := p_ftp * p_intensity;
    v_ride_id := gen_random_uuid();

    -- A deterministic stream per ride: the same seed gives the same ride.
    PERFORM setseed(((p_seed % 997)::float8 / 997.0) - 0.5);

    v_time := array_fill(0::double precision, ARRAY[v_n]);
    v_alt := array_fill(0::real, ARRAY[v_n]);
    v_speed := array_fill(0::real, ARRAY[v_n]);
    v_dist := array_fill(0::real, ARRAY[v_n]);
    v_hr := array_fill(0::smallint, ARRAY[v_n]);
    v_power := array_fill(0::smallint, ARRAY[v_n]);
    v_cadence := array_fill(0::smallint, ARRAY[v_n]);
    v_temp := array_fill(0::smallint, ARRAY[v_n]);
    IF p_gps THEN
        v_lat := array_fill(0::double precision, ARRAY[v_n]);
        v_lon := array_fill(0::double precision, ARRAY[v_n]);
    ELSE
        v_lat := NULL;
        v_lon := NULL;
    END IF;

    FOR v_i IN 1..v_n LOOP
        v_seconds := v_i - 1;
        v_time[v_i] := v_seconds;

        IF p_kind = 'intervals' THEN
            IF v_seconds < 600 THEN
                v_effort := 0.82;
            ELSIF v_seconds > v_n - 300 THEN
                v_effort := 0.78;
            ELSIF (v_seconds % 300) < 180 THEN
                v_effort := 1.32;
            ELSE
                v_effort := 0.68;
            END IF;
        ELSIF p_kind = 'tempo' THEN
            v_effort := 1.0;
        ELSIF p_kind = 'recovery' THEN
            v_effort := 0.92;
        ELSIF p_kind = 'virtual' THEN
            v_effort := 1.0 + 0.10 * sin(v_seconds / 120.0);
        ELSE
            v_effort := 1.0;
        END IF;
        v_effort := v_effort * (1 + (random() - 0.5) * 0.06);

        v_terrain := 1 + 0.06 * sin(v_seconds / 300.0 + p_seed)
                       + 0.03 * sin(v_seconds / 47.0 + p_seed * 0.3);
        v_power_w := v_p0 * v_effort * (0.94 + 0.12 * v_terrain) + (random() - 0.5) * 8;
        v_power_w := greatest(30, least(v_power_w, p_ftp * 1.75));
        v_power[v_i] := round(v_power_w)::smallint;

        v_ratio := v_power_w / v_p0;
        v_speed_ms := p_base_speed * power(v_ratio, 0.32) * (0.98 + 0.04 * sin(v_seconds / 97.0));
        v_speed_ms := greatest(1.5, least(v_speed_ms, 20.0));
        v_speed[v_i] := v_speed_ms::real;
        v_distance_total := v_distance_total + v_speed_ms;
        v_dist[v_i] := v_distance_total::real;
        IF v_speed_ms > v_max_speed THEN v_max_speed := v_speed_ms; END IF;

        v_target_hr := 55 + (p_max_hr - 55) * least(1.0, v_power_w / (p_ftp * 1.15));
        IF v_prev_hr IS NULL THEN v_prev_hr := v_target_hr * 0.8; END IF;
        v_hr_val := v_prev_hr + (v_target_hr - v_prev_hr) * 0.06;
        IF v_seconds > 3600 THEN v_hr_val := v_hr_val + 0.02; END IF;
        v_hr_val := greatest(60, least(v_hr_val, p_max_hr + 2));
        v_prev_hr := v_hr_val;
        v_hr[v_i] := round(v_hr_val)::smallint;

        v_cad := CASE p_kind WHEN 'intervals' THEN 92 WHEN 'gravel' THEN 82 ELSE 88 END
                 + 4 * sin(v_seconds / 90.0) + (random() - 0.5) * 6;
        v_cadence[v_i] := greatest(60, least(v_cad, 115))::smallint;

        v_temp[v_i] := round(18 + 6 * sin(2 * pi() * extract(doy FROM p_start) / 365.0)
                             + (random() - 0.5) * 2)::smallint;

        v_sum_power := v_sum_power + v_power_w;
        IF v_power_w > v_max_power THEN v_max_power := round(v_power_w); END IF;
        v_sum_hr := v_sum_hr + v_hr_val;
        IF round(v_hr_val) > v_max_hr_actual THEN v_max_hr_actual := round(v_hr_val); END IF;
        v_sum_cad := v_sum_cad + v_cad;

        v_hr_ratio := v_hr_val / p_max_hr;
        IF v_hr_ratio >= 0.5 THEN
            v_zone := CASE
                WHEN v_hr_ratio >= 0.9 THEN 5
                WHEN v_hr_ratio >= 0.8 THEN 4
                WHEN v_hr_ratio >= 0.7 THEN 3
                WHEN v_hr_ratio >= 0.6 THEN 2
                ELSE 1
            END;
            v_trimp := v_trimp + v_zone;
        END IF;
    END LOOP;

    v_loop_len := v_distance_total / greatest(p_laps, 1);
    v_radius := v_loop_len / (2 * pi());
    IF p_discipline = 'gravel' THEN
        v_lat0 := 45.468; v_lon0 := 10.535;
    ELSE
        v_lat0 := 45.438; v_lon0 := 10.685;
    END IF;
    v_lat0 := v_lat0 + ((p_seed % 7) - 3) * 0.003;
    v_lon0 := v_lon0 + ((p_seed % 5) - 2) * 0.004;
    v_hill := CASE p_discipline WHEN 'gravel' THEN 1.15 WHEN 'mountain' THEN 1.4 ELSE 1.0 END;

    FOR v_i IN 1..v_n LOOP
        v_frac := v_dist[v_i] / v_loop_len;
        v_theta := 2 * pi() * v_frac;
        v_r := v_radius * (1 + 0.22 * sin(3 * v_theta + p_seed * 0.1) + 0.08 * cos(5 * v_theta));
        IF p_gps THEN
            v_lat[v_i] := v_lat0 + v_r * sin(v_theta) / 111320.0;
            v_lon[v_i] := v_lon0 + v_r * cos(v_theta) / (111320.0 * cos(radians(v_lat0)));
        END IF;
        v_alt[v_i] := (80 + v_hill * (75 * sin(2 * pi() * v_frac * 2 + 0.4)
                                     + 40 * sin(2 * pi() * v_frac * 5 + 1.1)
                                     + 10 * sin(2 * pi() * v_frac * 11)))::real;
    END LOOP;

    v_ref_alt := v_alt[1];
    FOR v_i IN 2..v_n LOOP
        v_delta := v_alt[v_i] - v_ref_alt;
        IF abs(v_delta) >= 2 THEN
            IF v_delta > 0 THEN v_gain := v_gain + v_delta; ELSE v_loss := v_loss - v_delta; END IF;
            v_ref_alt := v_alt[v_i];
        END IF;
    END LOOP;

    v_window_sum := 0;
    FOR v_i IN 1..v_n LOOP
        v_window_sum := v_window_sum + v_power[v_i];
        IF v_i > 30 THEN v_window_sum := v_window_sum - v_power[v_i - 30]; END IF;
        IF v_i >= 30 THEN
            v_fourth_sum := v_fourth_sum + power(v_window_sum / 30.0, 4);
            v_windows := v_windows + 1;
        END IF;
    END LOOP;
    v_np := CASE WHEN v_windows > 0 THEN round(power(v_fourth_sum / v_windows, 0.25)) ELSE 0 END;
    IF p_ftp > 0 AND v_np > 0 THEN
        v_if := round(v_np::numeric / p_ftp, 2);
        v_tss := round(((v_n - 1) * v_np * v_if / (p_ftp * 3600) * 100)::numeric, 1);
    ELSE
        v_if := NULL;
        v_tss := NULL;
    END IF;
    v_trimp := round((v_trimp / 60.0)::numeric, 1);

    INSERT INTO rides.rides (
        id, user_id, status, file_sha256, file_name, uploaded_at, start_time, utc_offset_minutes, device,
        distance_m, elapsed_s, moving_s, elevation_gain_m, elevation_loss_m, avg_speed_ms, max_speed_ms,
        speed_source, avg_power_w, max_power_w, normalized_power_w, avg_heart_rate, max_heart_rate, avg_cadence,
        bike_id, intensity_factor, trimp, tss, assist, commute, discipline, environment, power_bests_backfilled_at)
    VALUES (
        v_ride_id, p_user, 'Ready', '', 'demo-' || to_char(p_start AT TIME ZONE 'Europe/Rome', 'YYYY-MM-DD')
            || '-' || p_kind || '.tcx.gz',
        p_start + make_interval(secs => v_n + 119), p_start, p_offset,
        CASE WHEN p_environment = 'virtual' THEN 'Zwift'
             WHEN p_seed % 2 = 0 THEN 'Garmin Edge 840' ELSE 'Wahoo ELEMNT ROAM' END,
        v_distance_total, v_n - 1, v_n - 1, v_gain, v_loss,
        v_distance_total / (v_n - 1), v_max_speed, 'Device',
        round(v_sum_power / v_n), v_max_power, v_np, round(v_sum_hr / v_n), v_max_hr_actual,
        round(v_sum_cad / v_n), p_bike, v_if, v_trimp, v_tss,
        'none', p_kind = 'commute', p_discipline, p_environment, now());

    INSERT INTO rides.ride_streams (
        ride_id, time, latitude, longitude, altitude, speed, distance, heart_rate, power, cadence, temperature)
    VALUES (v_ride_id, v_time, v_lat, v_lon, v_alt, v_speed, v_dist, v_hr, v_power, v_cadence, v_temp);

    FOREACH v_d IN ARRAY v_durations LOOP
        IF v_n >= v_d THEN
            v_window_sum := 0;
            v_best := 0;
            FOR v_i IN 1..v_n LOOP
                v_window_sum := v_window_sum + v_power[v_i];
                IF v_i > v_d THEN v_window_sum := v_window_sum - v_power[v_i - v_d]; END IF;
                IF v_i >= v_d AND v_window_sum / v_d > v_best THEN
                    v_best := v_window_sum / v_d;
                END IF;
            END LOOP;
            IF v_best > 0 THEN
                INSERT INTO rides.ride_power_bests (ride_id, duration_s, watts)
                VALUES (v_ride_id, v_d, round(v_best)::int);
            END IF;
        END IF;
    END LOOP;

    FOR v_lap IN 1..greatest(p_laps, 1) LOOP
        v_lap_start := 1 + ((v_lap - 1) * (v_n - 1)) / greatest(p_laps, 1);
        v_lap_end := 1 + (v_lap * (v_n - 1)) / greatest(p_laps, 1);
        v_lap_count := v_lap_end - v_lap_start + 1;
        v_lap_power := 0;
        v_lap_hr := 0;
        v_lap_cad := 0;
        v_lap_max_power := 0;
        v_lap_max_hr := 0;
        v_lap_max_speed := 0;
        v_lap_gain := 0;
        v_lap_ref := v_alt[v_lap_start];
        FOR v_i IN v_lap_start..v_lap_end LOOP
            v_lap_power := v_lap_power + v_power[v_i];
            v_lap_hr := v_lap_hr + v_hr[v_i];
            v_lap_cad := v_lap_cad + v_cadence[v_i];
            IF v_power[v_i] > v_lap_max_power THEN v_lap_max_power := v_power[v_i]; END IF;
            IF v_hr[v_i] > v_lap_max_hr THEN v_lap_max_hr := v_hr[v_i]; END IF;
            IF v_speed[v_i] > v_lap_max_speed THEN v_lap_max_speed := v_speed[v_i]; END IF;
            v_delta := v_alt[v_i] - v_lap_ref;
            IF abs(v_delta) >= 2 THEN
                IF v_delta > 0 THEN v_lap_gain := v_lap_gain + v_delta; END IF;
                v_lap_ref := v_alt[v_i];
            END IF;
        END LOOP;
        v_lap_distance := v_dist[v_lap_end] - v_dist[v_lap_start];
        INSERT INTO rides.ride_laps (
            ride_id, index, start_s, end_s, duration_s, moving_s, distance_m, avg_speed_ms, max_speed_ms,
            avg_power_w, max_power_w, avg_heart_rate, max_heart_rate, avg_cadence, elevation_gain_m)
        VALUES (
            v_ride_id, v_lap, v_lap_start - 1, v_lap_end - 1, v_lap_count - 1, v_lap_count - 1,
            v_lap_distance, v_lap_distance / greatest(v_lap_count - 1, 1), v_lap_max_speed,
            round(v_lap_power / v_lap_count), v_lap_max_power, round(v_lap_hr / v_lap_count), v_lap_max_hr,
            round(v_lap_cad / v_lap_count), v_lap_gain);
    END LOOP;
END
$ride$;

DO $seed$
DECLARE
    v_now timestamptz := now();
    v_today date := (now() AT TIME ZONE 'Europe/Rome')::date;
    v_club uuid;
    v_club_name text;
    v_coach uuid;
    v_coach_name text;
    v_road uuid;
    v_gravel uuid;
    v_template uuid;
    v_start timestamptz;
    v_day date;
    v_hour int;
    v_offset int;
    v_kind text;
    v_bike uuid;
    v_max_hr int;
    v_count int;
    v_step int;
    v_road_brand text;
    v_road_model text;
    v_gravel_brand text;
    v_gravel_model text;
    m record;
    i int;
    k record;
BEGIN
    -- The demo club: the one with the most members. On the hosted demo that is the only club.
    SELECT c.id, c.name INTO v_club, v_club_name
    FROM clubs.clubs c
    JOIN clubs.memberships mbr ON mbr.club_id = c.id
    GROUP BY c.id, c.name, c.created_at
    ORDER BY count(*) DESC, c.created_at
    LIMIT 1;

    IF v_club IS NULL THEN
        RAISE EXCEPTION 'No club found. Create the demo club and its members first.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM rides.rides r
        JOIN clubs.memberships mbr ON mbr.user_id = r.user_id
        WHERE mbr.club_id = v_club
    ) OR EXISTS (
        SELECT 1
        FROM bikes.bikes b
        JOIN clubs.memberships mbr ON mbr.user_id = b.user_id
        WHERE mbr.club_id = v_club
    ) THEN
        RAISE NOTICE 'Club "%" already has bikes or rides; demo seed skipped.', v_club_name;
        RETURN;
    END IF;

    RAISE NOTICE 'Seeding demo data for club "%".', v_club_name;

    CREATE TEMP TABLE demo_members ON COMMIT DROP AS
    SELECT mbr.user_id,
           row_number() OVER (ORDER BY mbr.joined_at, mbr.user_id) AS n,
           mbr.role
    FROM clubs.memberships mbr
    WHERE mbr.club_id = v_club;

    SELECT user_id INTO v_coach FROM demo_members
    ORDER BY CASE role WHEN 'owner' THEN 0 WHEN 'coach' THEN 1 ELSE 2 END, n
    LIMIT 1;
    SELECT display_name INTO v_coach_name FROM accounts.users WHERE id = v_coach;

    -- Profiles: the rides and the analytics need FTP, weight, birth year and a time zone.
    UPDATE accounts.users u
    SET ftp_w = COALESCE(u.ftp_w, CASE
            WHEN dm.role IN ('owner', 'coach') THEN 280
            WHEN dm.n % 3 = 0 THEN 225
            WHEN dm.n % 3 = 1 THEN 275
            ELSE 195
        END),
        weight_kg = COALESCE(u.weight_kg, CASE
            WHEN dm.role IN ('owner', 'coach') THEN 74
            WHEN dm.n % 3 = 0 THEN 60
            WHEN dm.n % 3 = 1 THEN 72
            ELSE 57
        END),
        birth_year = COALESCE(u.birth_year, CASE
            WHEN dm.role IN ('owner', 'coach') THEN 1982
            WHEN dm.n % 3 = 0 THEN 1993
            WHEN dm.n % 3 = 1 THEN 1988
            ELSE 1997
        END),
        time_zone = COALESCE(u.time_zone, 'Europe/Rome'),
        wellbeing_consent_at = COALESCE(u.wellbeing_consent_at, v_now - interval '90 days'),
        wellbeing_consent_version = COALESCE(u.wellbeing_consent_version, 1)
    FROM demo_members dm
    WHERE u.id = dm.user_id;

    CREATE TEMP TABLE demo_member_bikes ON COMMIT DROP AS
    SELECT dm.n, dm.user_id, NULL::uuid AS road_bike, NULL::uuid AS gravel_bike
    FROM demo_members dm;

    FOR m IN SELECT * FROM demo_members ORDER BY n LOOP
        v_road := gen_random_uuid();
        v_gravel := gen_random_uuid();
        v_road_brand := CASE (m.n - 1) % 4 WHEN 0 THEN 'Trek' WHEN 1 THEN 'Specialized' WHEN 2 THEN 'Colnago' ELSE 'Bianchi' END;
        v_road_model := CASE (m.n - 1) % 4 WHEN 0 THEN 'Émonda SL 7' WHEN 1 THEN 'Roubaix SL8' WHEN 2 THEN 'C68' ELSE 'Infinito CV' END;
        v_gravel_brand := CASE (m.n - 1) % 4 WHEN 0 THEN 'Trek' WHEN 1 THEN 'Canyon' WHEN 2 THEN 'Bianchi' ELSE 'Giant' END;
        v_gravel_model := CASE (m.n - 1) % 4 WHEN 0 THEN 'Checkpoint SL 5' WHEN 1 THEN 'Grizl CF SL 7' WHEN 2 THEN 'Impulso Allroad' ELSE 'Revolt Advanced 2' END;

        INSERT INTO bikes.bikes (
            id, user_id, name, brand, model, kind, wheel_circumference_mm, initial_distance_m,
            purchased_on, is_default, is_active, created_at, build_spec, frame_size, model_year)
        VALUES (
            v_road, m.user_id, v_road_brand || ' ' || v_road_model, v_road_brand, v_road_model, 'road', 2155, 0,
            v_today - 500, true, true, v_now - interval '200 days', 'Ultegra Di2', '56', 2025);

        INSERT INTO bikes.bikes (
            id, user_id, name, brand, model, kind, wheel_circumference_mm, initial_distance_m,
            purchased_on, is_default, is_active, created_at, build_spec, frame_size, model_year)
        VALUES (
            v_gravel, m.user_id, v_gravel_brand || ' ' || v_gravel_model, v_gravel_brand, v_gravel_model, 'gravel', 2200, 0,
            v_today - 350, false, true, v_now - interval '180 days', 'GRX 810', 'M', 2024);

        UPDATE demo_member_bikes SET road_bike = v_road, gravel_bike = v_gravel WHERE n = m.n;

        v_template := gen_random_uuid();
        INSERT INTO bikes.bike_templates (id, user_id, name, created_at)
        VALUES (v_template, m.user_id, 'Race day', v_now - interval '40 days');
        INSERT INTO bikes.bike_template_parts (
            id, template_id, type, brand, model, mpn, expected_distance_m, is_custom)
        VALUES
            (gen_random_uuid(), v_template, 'chain', 'Shimano', 'CN-M8100', 'CN-M8100', 4000000, false),
            (gen_random_uuid(), v_template, 'cassette', 'Shimano', 'CS-R8000', 'CS-R8000', 12000000, false),
            (gen_random_uuid(), v_template, 'rear_brake_pads', 'Shimano', 'B05S-RX', 'B05S-RX', 2000000, false);
    END LOOP;

    -- Components: two current sets with a worn sealant and a soon brake fluid, plus one retired chain.
    INSERT INTO bikes.bike_components (
        id, bike_id, type, brand, model, mpn, installed_on, removed_on,
        expected_distance_m, expected_hours, expected_months, part_id, is_custom)
    SELECT gen_random_uuid(), b.bike_id, s.type, s.brand, s.model, s.mpn,
           v_today - s.installed_days, NULL, s.km * 1000.0, s.hours, s.months,
           p.id, p.id IS NULL
    FROM demo_member_bikes mb
    CROSS JOIN LATERAL (VALUES (mb.road_bike), (mb.gravel_bike)) b(bike_id)
    CROSS JOIN (VALUES
        ('chain', 'Shimano', 'CN-M8100', 'CN-M8100', 90, 4000, NULL::float8, NULL::int),
        ('cassette', 'Shimano', 'CS-R8000', 'CS-R8000', 300, 12000, NULL, NULL),
        ('front_brake_pads', 'Shimano', 'B05S-RX', 'B05S-RX', 120, 2000, NULL, NULL),
        ('rear_brake_pads', 'Shimano', 'B05S-RX', 'B05S-RX', 120, 2000, NULL, NULL),
        ('tubeless_sealant', 'Stan''s', 'Race Sealant', NULL, 120, NULL, NULL::float8, 3),
        ('brake_fluid', 'Shimano', 'Mineral Oil', NULL, 720, NULL, NULL, 24)
    ) AS s(type, brand, model, mpn, installed_days, km, hours, months)
    LEFT JOIN bikes.parts p
        ON p.status = 'active' AND p.type = s.type
       AND lower(p.brand) = lower(s.brand) AND lower(p.model) = lower(s.model);

    INSERT INTO bikes.bike_components (
        id, bike_id, type, brand, model, mpn, installed_on, removed_on,
        expected_distance_m, part_id, is_custom)
    SELECT gen_random_uuid(), mb.road_bike, 'chain', 'Shimano', 'CN-HG601', 'CN-HG601',
           v_today - 400, v_today - 100, 4000000, p.id, p.id IS NULL
    FROM demo_member_bikes mb
    LEFT JOIN bikes.parts p
        ON p.status = 'active' AND p.type = 'chain'
       AND lower(p.brand) = 'shimano' AND lower(p.model) = 'cn-hg601';

    -- Ride templates by kind.
    CREATE TEMP TABLE demo_kinds (
        kind text PRIMARY KEY, minutes int, intensity float8, discipline text,
        environment text, laps int, gps boolean, base_speed float8) ON COMMIT DROP;
    INSERT INTO demo_kinds VALUES
        ('intervals', 65, 0.78, 'road', 'outdoor', 2, true, 8.1),
        ('endurance', 95, 0.66, 'road', 'outdoor', 2, true, 7.4),
        ('long', 155, 0.68, 'road', 'outdoor', 3, true, 7.5),
        ('recovery', 45, 0.52, 'road', 'outdoor', 1, true, 6.7),
        ('tempo', 60, 0.82, 'road', 'outdoor', 2, true, 8.3),
        ('gravel', 105, 0.72, 'gravel', 'outdoor', 2, true, 6.3),
        ('virtual', 70, 0.80, 'road', 'virtual', 3, false, 9.7),
        ('commute', 35, 0.55, 'road', 'outdoor', 1, true, 6.2);

    -- Rides for every member, ending today and going back about three months (about 90 days each).
    FOR m IN
        SELECT dm.n, dm.user_id, mb.road_bike, mb.gravel_bike, u.ftp_w, u.birth_year
        FROM demo_members dm
        JOIN demo_member_bikes mb ON mb.n = dm.n
        JOIN accounts.users u ON u.id = dm.user_id
        ORDER BY dm.n
    LOOP
        v_count := CASE WHEN m.n = 1 THEN 16 WHEN m.n = 2 THEN 20 WHEN m.n = 3 THEN 18 ELSE 16 END;
        v_step := CASE m.n WHEN 1 THEN 6 ELSE 5 END; -- 16 rides x 6 days, 20 x 5 and 18 x 5: about 90 days each

        FOR i IN 0..v_count - 1 LOOP
            v_kind := CASE (i + m.n) % 6
                WHEN 0 THEN 'endurance'
                WHEN 1 THEN 'tempo'
                WHEN 2 THEN 'intervals'
                WHEN 3 THEN 'long'
                WHEN 4 THEN 'gravel'
                ELSE 'recovery'
            END;
            IF i % 9 = 7 THEN v_kind := 'virtual'; END IF;
            IF i % 11 = 9 THEN v_kind := 'commute'; END IF;

            SELECT * INTO k FROM demo_kinds WHERE kind = v_kind;
            v_day := v_today - i * v_step;
            v_hour := CASE WHEN k.minutes >= 120 THEN 9 ELSE 18 END;

            v_start := (v_day::timestamp + make_interval(hours => v_hour)) AT TIME ZONE 'Europe/Rome';
            IF v_start > now() - interval '1 hour' THEN
                v_start := ((v_day - 1)::timestamp + make_interval(hours => v_hour)) AT TIME ZONE 'Europe/Rome';
            END IF;
            v_offset := round(extract(epoch FROM
                ((v_start AT TIME ZONE 'Europe/Rome') - (v_start AT TIME ZONE 'UTC'))) / 60)::int;

            v_bike := CASE WHEN k.discipline = 'gravel' THEN m.gravel_bike ELSE m.road_bike END;
            v_max_hr := round(208 - 0.7 * (extract(year FROM v_today) - m.birth_year))::int;

            PERFORM pg_temp.demo_seed_ride(
                m.user_id, v_bike, v_start, v_offset, v_kind, k.minutes, k.intensity, k.discipline,
                k.environment, k.laps, k.gps, k.base_speed, m.ftp_w, v_max_hr, (m.n * 1000 + i)::int);
        END LOOP;
    END LOOP;

    -- Goals.
    INSERT INTO analytics.goals (id, user_id, period, metric, target, created_at)
    SELECT gen_random_uuid(), dm.user_id, g.period, g.metric, g.target, v_now - interval '30 days'
    FROM demo_members dm
    CROSS JOIN LATERAL (VALUES
        ('week', 'distance', 150000.0),
        ('month', 'elevation', 3000.0),
        ('year', 'rides', 120.0)
    ) AS g(period, metric, target)
    ON CONFLICT (user_id, period, metric) DO NOTHING;

    -- Daily check-ins for the last two weeks.
    FOR m IN SELECT * FROM demo_members LOOP
        FOR i IN 0..13 LOOP
            INSERT INTO wellbeing.daily_check_ins (
                id, user_id, local_date, fatigue, soreness, mood, stress, motivation, created_at, updated_at)
            VALUES (
                gen_random_uuid(), m.user_id, v_today - i,
                1 + ((i + m.n) % 5), 1 + ((i * 2 + m.n) % 5), 1 + ((i * 3 + m.n) % 5),
                1 + ((i + 2 * m.n) % 5), 1 + ((i * 2 + 3 * m.n) % 5),
                v_now - make_interval(days => i), v_now - make_interval(days => i))
            ON CONFLICT (user_id, local_date) DO NOTHING;
        END LOOP;
    END LOOP;

    -- Privacy: a short trim at both ends, and a home zone for the first two members.
    INSERT INTO privacy.settings (
        user_id, hide_heart_rate, hide_power, hide_cadence, hide_speed, hide_elevation, hide_temperature,
        trim_start_m, trim_end_m, updated_at)
    SELECT dm.user_id, false, false, false, false, false, true, 300, 200, v_now - interval '14 days'
    FROM demo_members dm
    ON CONFLICT (user_id) DO NOTHING;

    INSERT INTO privacy.zones (id, user_id, name, latitude, longitude, radius_m, created_at)
    SELECT gen_random_uuid(), dm.user_id, 'Home', 45.438 + dm.n * 0.002, 10.685, 500, v_now - interval '60 days'
    FROM demo_members dm
    WHERE dm.n <= 2;

    -- Sharing: every member except the coach/owner shares with the club's coaches.
    INSERT INTO sharing.grants (id, member_id, club_id, data_type, audience, updated_at)
    SELECT gen_random_uuid(), dm.user_id, v_club, t.data_type, 'coaches', v_now - interval '20 days'
    FROM demo_members dm
    CROSS JOIN (VALUES ('rides'), ('analytics'), ('routes'), ('wellbeing')) AS t(data_type)
    WHERE dm.user_id <> v_coach
    ON CONFLICT (member_id, data_type) DO NOTHING;

    INSERT INTO sharing.view_log (id, member_id, club_id, viewer_id, viewer_name, what, at)
    SELECT gen_random_uuid(), dm.user_id, v_club, v_coach, v_coach_name, w.what,
           v_now - make_interval(hours => w.hours)
    FROM demo_members dm
    CROSS JOIN (VALUES ('summary', 20), ('training', 18), ('ride', 5)) AS w(what, hours)
    WHERE dm.user_id <> v_coach;

    -- Notifications: the two latest rides per member, the latest unread.
    INSERT INTO notifications.notifications (
        id, user_id, type, subject, ride_id, created_at, read_at)
    SELECT gen_random_uuid(), r.user_id, 'ride_ready', r.file_name, r.id, r.uploaded_at,
           CASE WHEN r.rn = 2 THEN r.uploaded_at + interval '1 hour' ELSE NULL END
    FROM (
        SELECT rides.*, row_number() OVER (PARTITION BY user_id ORDER BY start_time DESC) AS rn
        FROM rides.rides
        WHERE user_id IN (SELECT user_id FROM demo_members)
    ) r
    WHERE r.rn <= 2;

    INSERT INTO notifications.notifications (
        id, user_id, type, subject, bike_id, component_id, created_at)
    SELECT gen_random_uuid(), b.user_id, 'part_worn',
           CASE bc.type WHEN 'tubeless_sealant' THEN 'Tubeless sealant' ELSE bc.type END || ' on ' || b.name,
           b.id, bc.id, v_now - interval '2 days'
    FROM bikes.bike_components bc
    JOIN bikes.bikes b ON b.id = bc.bike_id
    WHERE b.user_id IN (SELECT user_id FROM demo_members)
      AND bc.type = 'tubeless_sealant' AND bc.removed_on IS NULL;

    -- How the last rides felt, to give the coach view and readiness some RPE.
    INSERT INTO wellbeing.ride_feel (ride_id, rpe, notes, updated_at)
    SELECT r.id, 4 + r.rn, CASE WHEN r.rn = 1 THEN 'Strong on the last climb.' ELSE NULL END,
           r.start_time + interval '3 hours'
    FROM (
        SELECT rides.*, row_number() OVER (PARTITION BY user_id ORDER BY start_time DESC) AS rn
        FROM rides.rides
        WHERE user_id IN (SELECT user_id FROM demo_members)
    ) r
    WHERE r.rn <= 3;

    RAISE NOTICE 'Demo data seeded for club "%": % members, % rides.',
        v_club_name,
        (SELECT count(*) FROM demo_members),
        (SELECT count(*) FROM rides.rides WHERE user_id IN (SELECT user_id FROM demo_members));
END
$seed$;
