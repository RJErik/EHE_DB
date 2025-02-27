CREATE SCHEMA logging;

CREATE TYPE logging.t_log_rec AS (
    log_id INT,
    user_id INT,
    action_date TIMESTAMP,
    action_description TEXT
);

CREATE TYPE logging.t_log_table AS (
    log_id INT,
    user_id INT,
    action_date TIMESTAMP,
    action_description TEXT
);

CREATE OR REPLACE FUNCTION logging.prc_log_action(p_action_description TEXT)
RETURNS VOID AS $$
DECLARE
    v_user_id INT := current_setting('myapp.current_user', true)::INT;
BEGIN
    IF p_action_description IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    -- Validate string length
    PERFORM sys_error_helper.prc_check_string_length(p_action_description, 1000);

    -- Insert into log table
    INSERT INTO log (user_id, action_description)
    VALUES (v_user_id, p_action_description);

    COMMIT;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION logging.fn_view_logs(
    p_start_date TIMESTAMP DEFAULT NULL,
    p_end_date TIMESTAMP DEFAULT NULL,
    p_search_user_id INT DEFAULT NULL,
    p_action_description_filter TEXT DEFAULT NULL
)
RETURNS SETOF logging.t_log_table AS $$
DECLARE
    v_admin_id INT := current_setting('myapp.current_user', true)::INT;
BEGIN
    -- Validate admin exists
    PERFORM sys_error_helper.prc_check_admin_exists();

    -- Validate date range
    IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL THEN
        PERFORM sys_error_helper.prc_check_date_range_order(p_start_date, p_end_date);
    END IF;

    -- Return logs
    RETURN QUERY
    SELECT log_id, user_id, action_date, action_description
    FROM log
    WHERE (p_start_date IS NULL OR action_date >= p_start_date)
      AND (p_end_date IS NULL OR action_date <= p_end_date)
      AND (p_search_user_id IS NULL OR user_id = p_search_user_id)
      AND (p_action_description_filter IS NULL OR
           LOWER(action_description) LIKE LOWER('%' || p_action_description_filter || '%'))
    ORDER BY action_date DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION logging.fn_get_latest_log()
RETURNS logging.t_log_rec AS $$
DECLARE
    v_admin_id INT := current_setting('myapp.current_user', true)::INT;
    v_log_rec logging.t_log_rec;
BEGIN
    -- Validate admin exists
    PERFORM sys_error_helper.prc_check_admin_exists();

    -- Get the latest log
    SELECT log_id, user_id, action_date, action_description
    INTO v_log_rec
    FROM log
    WHERE log_id = (SELECT MAX(log_id) FROM log);

    -- Log the action
    PERFORM logging.prc_log_action('Calling fn_get_latest_log');

    RETURN v_log_rec;
END;
$$ LANGUAGE plpgsql;
