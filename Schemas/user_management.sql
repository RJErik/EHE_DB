CREATE SCHEMA user_management;

CREATE TYPE user_management.user_details_rec AS (
    user_name VARCHAR(100),
    email_hash VARCHAR(255),
    registration_date TIMESTAMP,
    account_status VARCHAR(50)
);

CREATE OR REPLACE FUNCTION user_management.prc_create_user(
    p_user_name VARCHAR,
    p_password_hash VARCHAR,
    p_email_hash VARCHAR
)
RETURNS VOID AS $$
DECLARE
    v_new_user_id INT;
BEGIN
    -- Validate input parameters
    IF p_user_name IS NULL OR p_password_hash IS NULL OR p_email_hash IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    -- Validate string lengths
    PERFORM sys_error_helper.prc_check_string_length(p_user_name, 100);
    PERFORM sys_error_helper.prc_check_string_length(p_email_hash, 255);
    PERFORM sys_error_helper.prc_check_string_length(p_password_hash, 255);

    -- Check if user already exists
    PERFORM sys_error_helper.prc_check_user_exist_name_mail(p_user_name);
    PERFORM sys_error_helper.prc_check_user_exist_name_mail(p_email_hash);

    -- Insert new user
    INSERT INTO "user" (user_name, email_hash, password_hash, account_status)
    VALUES (p_user_name, p_email_hash, p_password_hash, 'ACTIVE')
    RETURNING user_id INTO v_new_user_id;

    -- Log the action
    PERFORM logging.prc_log_action('User created: ' || p_user_name);

    COMMIT;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION user_management.fn_validate_login(
    p_username_or_email VARCHAR,
    p_password_hash VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id INT;
    v_stored_hash VARCHAR;
    v_account_status VARCHAR;
BEGIN
    -- Validate input parameters
    IF p_username_or_email IS NULL OR p_password_hash IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    -- Validate string lengths
    PERFORM sys_error_helper.prc_check_string_length(p_username_or_email, 100);
    PERFORM sys_error_helper.prc_check_string_length(p_password_hash, 255);

    -- Check if user exists
    PERFORM sys_error_helper.prc_check_user_does_not_exist(p_username_or_email);

    -- Retrieve user details
    SELECT user_id, password_hash, account_status
    INTO v_user_id, v_stored_hash, v_account_status
    FROM "user"
    WHERE user_name = p_username_or_email
       OR email_hash = p_username_or_email;

    -- Validate password and account status
    IF v_stored_hash = p_password_hash AND v_account_status = 'ACTIVE' THEN
        -- Log successful login
        PERFORM logging.prc_log_action('Successful login: ' || p_username_or_email);
        RETURN TRUE;
    ELSE
        -- Log failed login attempt
        PERFORM logging.prc_log_action('Failed login attempt: ' || p_username_or_email);
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION user_management.prc_update_user_details(
    p_new_user_name VARCHAR DEFAULT NULL,
    p_new_password_hash VARCHAR DEFAULT NULL,
    p_new_email_hash VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_user_id INT := current_setting('myapp.current_user', true)::INT;
BEGIN
    -- Validate user exists
    PERFORM sys_error_helper.prc_check_user_exist_by_ids();

    -- Validate and update username
    IF p_new_user_name IS NOT NULL THEN
        PERFORM sys_error_helper.prc_check_string_length(p_new_user_name, 100);
        PERFORM sys_error_helper.prc_check_user_exist_name_mail(p_new_user_name);
    END IF;

    -- Validate and update password hash
    IF p_new_password_hash IS NOT NULL THEN
        PERFORM sys_error_helper.prc_check_string_length(p_new_password_hash, 255);
    END IF;

    -- Validate and update email hash
    IF p_new_email_hash IS NOT NULL THEN
        PERFORM sys_error_helper.prc_check_string_length(p_new_email_hash, 255);
        PERFORM sys_error_helper.prc_check_user_exist_name_mail(p_new_email_hash);
    END IF;

    -- Update user details
    UPDATE "user"
    SET user_name = COALESCE(p_new_user_name, user_name),
        password_hash = COALESCE(p_new_password_hash, password_hash),
        email_hash = COALESCE(p_new_email_hash, email_hash)
    WHERE user_id = v_user_id;

    -- Log the action
    PERFORM logging.prc_log_action('User details updated for UserID: ' || v_user_id);

    COMMIT;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION user_management.prc_change_account_activation(
    p_active_status VARCHAR
)
RETURNS VOID AS $$
DECLARE
    v_user_id INT := current_setting('myapp.current_user', true)::INT;
BEGIN
    -- Validate input parameters
    IF p_active_status IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    -- Validate user exists
    PERFORM sys_error_helper.prc_check_user_exist_by_ids();

    -- Validate active status
    IF p_active_status NOT IN ('ACTIVE', 'SUSPENDED') THEN
        RAISE EXCEPTION 'invalid_input' USING ERRCODE = '20020';
    END IF;

    -- Update account status
    UPDATE "user"
    SET account_status = p_active_status
    WHERE user_id = v_user_id;

    -- Log the action
    PERFORM logging.prc_log_action('Account status changed for UserID: ' || v_user_id || ' to ' || p_active_status);

    COMMIT;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION user_management.prc_get_user_details()
RETURNS user_management.user_details_rec AS $$
DECLARE
    v_user_id INT := current_setting('myapp.current_user', true)::INT;
    v_user_details user_management.user_details_rec;
BEGIN
    -- Validate user exists
    PERFORM sys_error_helper.prc_check_user_exist_by_ids();

    -- Retrieve user details
    SELECT user_name, email_hash, registration_date, account_status
    INTO v_user_details
    FROM "user"
    WHERE user_id = v_user_id;

    -- Log the action
    PERFORM logging.prc_log_action('User details retrieved for UserID: ' || v_user_id);

    RETURN v_user_details;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION user_management.fn_does_user_exist(
    p_username_or_email VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_count INT;
BEGIN
    -- Validate input parameter
    IF p_username_or_email IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    -- Check if user exists
    SELECT COUNT(*)
    INTO v_user_count
    FROM "user"
    WHERE user_name = p_username_or_email
       OR email_hash = p_username_or_email;

    RETURN v_user_count > 0;
END;
$$ LANGUAGE plpgsql;
