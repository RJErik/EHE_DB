CREATE SCHEMA error_logging;

CREATE TYPE error_logging.t_error_log_rec AS (
    error_log_id INT,
    user_id INT,
    error_message TEXT,
    stack_trace TEXT,
    error_date TIMESTAMP
);

CREATE TYPE error_logging.t_error_log_table AS (
    error_log_id INT,
    user_id INT,
    error_message TEXT,
    stack_trace TEXT,
    error_date TIMESTAMP
);

CREATE OR REPLACE FUNCTION error_logging.prc_log_error(
    p_error_message TEXT,
    p_stack_trace TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_user_id INT := current_setting('myapp.current_user', true)::INT;
BEGIN
    IF p_error_message IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    -- Validate string length
    PERFORM sys_error_helper.prc_check_string_length(p_error_message, 1000);

    -- Insert into error_log table
    INSERT INTO error_log (user_id, error_description, stack_trace)
    VALUES (v_user_id, p_error_message, p_stack_trace);

    COMMIT;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION error_logging.fn_view_error_logs(
    p_start_date TIMESTAMP DEFAULT NULL,
    p_end_date TIMESTAMP DEFAULT NULL,
    p_search_user_id INT DEFAULT NULL,
    p_error_message_filter TEXT DEFAULT NULL
)
RETURNS SETOF error_logging.t_error_log_table AS $$
DECLARE
    v_admin_id INT := current_setting('myapp.current_user', true)::INT;
BEGIN
    -- Validate admin exists
    PERFORM sys_error_helper.prc_check_admin_exists();

    -- Validate date range
    IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL THEN
        PERFORM sys_error_helper.prc_check_date_range_order(p_start_date, p_end_date);
    END IF;

    -- Return error logs
    RETURN QUERY
    SELECT error_log_id, user_id, error_date, error_description, stack_trace
    FROM error_log
    WHERE (p_start_date IS NULL OR error_date >= p_start_date)
      AND (p_end_date IS NULL OR error_date <= p_end_date)
      AND (p_search_user_id IS NULL OR user_id = p_search_user_id)
      AND (p_error_message_filter IS NULL OR
           LOWER(error_description) LIKE LOWER('%' || p_error_message_filter || '%'))
    ORDER BY error_date DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION error_logging.fn_get_latest_error_log()
RETURNS error_logging.t_error_log_rec AS $$
DECLARE
    v_admin_id INT := current_setting('myapp.current_user', true)::INT;
    v_error_log_rec error_logging.t_error_log_rec;
BEGIN
    -- Validate admin exists
    PERFORM sys_error_helper.prc_check_admin_exists();

    -- Get the latest error log
    SELECT error_log_id, user_id, error_date, error_description, stack_trace
    INTO v_error_log_rec
    FROM error_log
    WHERE error_log_id = (SELECT MAX(error_log_id) FROM error_log);

    -- Log the action
    PERFORM logging.prc_log_action('Calling fn_get_latest_error_log');

    RETURN v_error_log_rec;
END;
$$ LANGUAGE plpgsql;
