CREATE SCHEMA sys_error_helper;

CREATE OR REPLACE FUNCTION sys_error_helper.prc_check_user_exist_by_ids()
RETURNS VOID AS $$
DECLARE
    v_user_id INT := current_setting('myapp.current_user', true)::INT;
    v_user_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_user_count
    FROM "user"
    WHERE user_id = v_user_id;

    IF v_user_count = 0 THEN
        RAISE EXCEPTION 'invalid_user_id' USING ERRCODE = '20001';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys_error_helper.prc_check_admin_exists()
RETURNS VOID AS $$
DECLARE
    v_admin_id INT := current_setting('myapp.current_user', true)::INT;
    v_admin_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_admin_count
    FROM admin
    WHERE admin_id = v_admin_id;

    IF v_admin_count = 0 THEN
        RAISE EXCEPTION 'invalid_admin_id' USING ERRCODE = '20002';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys_error_helper.prc_check_user_exist_name_mail(p_usernameoremail VARCHAR)
RETURNS VOID AS $$
DECLARE
    v_user_count INT;
BEGIN
    IF p_usernameoremail IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    SELECT COUNT(*)
    INTO v_user_count
    FROM "user"
    WHERE user_name = p_usernameoremail
       OR email_hash = p_usernameoremail;

    IF v_user_count > 0 THEN
        RAISE EXCEPTION 'duplicate_user_info' USING ERRCODE = '20017';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys_error_helper.prc_check_user_does_not_exist(p_usernameoremail VARCHAR)
RETURNS VOID AS $$
DECLARE
    v_user_count INT;
BEGIN
    IF p_usernameoremail IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    SELECT COUNT(*)
    INTO v_user_count
    FROM "user"
    WHERE user_name = p_usernameoremail
       OR email_hash = p_usernameoremail;

    IF v_user_count = 0 THEN
        RAISE EXCEPTION 'invalid_user_name_email' USING ERRCODE = '20019';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys_error_helper.prc_check_string_length(p_inputvalue VARCHAR, p_maxlength INT)
RETURNS VOID AS $$
BEGIN
    IF p_inputvalue IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    IF LENGTH(p_inputvalue) > p_maxlength THEN
        RAISE EXCEPTION 'input_too_long' USING ERRCODE = '20016';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys_error_helper.prc_check_date_range_order(p_startdate TIMESTAMP, p_enddate TIMESTAMP)
RETURNS VOID AS $$
BEGIN
    IF p_startdate IS NULL OR p_enddate IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    IF p_startdate > p_enddate THEN
        RAISE EXCEPTION 'invalid_date_range' USING ERRCODE = '20010';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys_error_helper.prc_check_price_range_possible(p_minprice DECIMAL, p_maxprice DECIMAL)
RETURNS VOID AS $$
BEGIN
    IF p_minprice IS NULL OR p_maxprice IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    IF p_minprice > p_maxprice THEN
        RAISE EXCEPTION 'invalid_price' USING ERRCODE = '20009';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys_error_helper.prc_check_listing_belongs_user(p_listingid INT)
RETURNS VOID AS $$
DECLARE
    v_user_id INT := current_setting('myapp.current_user', true)::INT;
    v_listing_count INT;
BEGIN
    IF p_listingid IS NULL THEN
        RAISE EXCEPTION 'null_value_error' USING ERRCODE = '20000';
    END IF;

    SELECT COUNT(*)
    INTO v_listing_count
    FROM portfolio
    WHERE portfolio_id = p_listingid
      AND user_id = v_user_id;

    IF v_listing_count = 0 THEN
        RAISE EXCEPTION 'invalid_listing_id' USING ERRCODE = '20018';
    END IF;
END;
$$ LANGUAGE plpgsql;


