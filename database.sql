--
-- PostgreSQL database dump
--

-- Dumped from database version 11.1
-- Dumped by pg_dump version 11.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: chain; Type: SCHEMA; Schema: -; Owner: test
--

CREATE SCHEMA chain;


ALTER SCHEMA chain OWNER TO test;

--
-- Name: activated_protocol_feature_v0; Type: TYPE; Schema: chain; Owner: test
--

CREATE TYPE chain.activated_protocol_feature_v0 AS (
	feature_digest character varying(64),
	activation_block_num bigint
);


ALTER TYPE chain.activated_protocol_feature_v0 OWNER TO test;

--
-- Name: key_weight; Type: TYPE; Schema: chain; Owner: test
--

CREATE TYPE chain.key_weight AS (
	key character varying,
	weight integer
);


ALTER TYPE chain.key_weight OWNER TO test;

--
-- Name: permission_level_weight; Type: TYPE; Schema: chain; Owner: test
--

CREATE TYPE chain.permission_level_weight AS (
	permission_actor character varying(13),
	permission_permission character varying(13),
	weight integer
);


ALTER TYPE chain.permission_level_weight OWNER TO test;

--
-- Name: transaction_status_type; Type: TYPE; Schema: chain; Owner: test
--

CREATE TYPE chain.transaction_status_type AS ENUM (
    'executed',
    'soft_fail',
    'hard_fail',
    'delayed',
    'expired'
);


ALTER TYPE chain.transaction_status_type OWNER TO test;

--
-- Name: wait_weight; Type: TYPE; Schema: chain; Owner: test
--

CREATE TYPE chain.wait_weight AS (
	wait_sec bigint,
	weight integer
);


ALTER TYPE chain.wait_weight OWNER TO test;

--
-- Name: action_trace_notify_trigger(); Type: FUNCTION; Schema: chain; Owner: test
--

CREATE FUNCTION chain.action_trace_notify_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
    BEGIN
      PERFORM pg_notify('new_action_trace', NEW.receipt_global_sequence::text);
      RETURN NEW;
    END;
    $$;



ALTER FUNCTION chain.action_trace_notify_trigger() OWNER TO test;

--
-- Name: action_trace_notify_trigger(); Type: FUNCTION; Schema: public; Owner: test
--

CREATE FUNCTION public.action_trace_notify_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
    BEGIN
      PERFORM pg_notify('new_action_trace', NEW.receipt_global_sequence::text);
      RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.action_trace_notify_trigger() OWNER TO test;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.account (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    name character varying(13) NOT NULL,
    creation_date timestamp without time zone,
    abi bytea
);


ALTER TABLE chain.account OWNER TO test;

--
-- Name: account_metadata; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.account_metadata (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    name character varying(13) NOT NULL,
    privileged boolean,
    last_code_update timestamp without time zone,
    code_present boolean,
    code_vm_type smallint,
    code_vm_version smallint,
    code_code_hash character varying(64)
);


ALTER TABLE chain.account_metadata OWNER TO test;

--
-- Name: action_trace; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.action_trace (
    block_num bigint NOT NULL,
    transaction_id character varying(64) NOT NULL,
    transaction_status chain.transaction_status_type,
    action_ordinal bigint NOT NULL,
    creator_action_ordinal bigint,
    receipt_present boolean,
    receipt_receiver character varying(13),
    receipt_act_digest character varying(64),
    receipt_global_sequence numeric,
    receipt_recv_sequence numeric,
    receipt_code_sequence bigint,
    receipt_abi_sequence bigint,
    receiver character varying(13),
    act_account character varying(13),
    act_name character varying(13),
    act_data bytea,
    context_free boolean,
    elapsed bigint,
    console character varying,
    "except" character varying,
    error_code numeric
);


ALTER TABLE chain.action_trace OWNER TO test;

--
-- Name: action_trace_auth_sequence; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.action_trace_auth_sequence (
    block_num bigint NOT NULL,
    transaction_id character varying(64) NOT NULL,
    action_ordinal integer NOT NULL,
    ordinal integer NOT NULL,
    transaction_status chain.transaction_status_type,
    account character varying(13),
    sequence numeric
);


ALTER TABLE chain.action_trace_auth_sequence OWNER TO test;

--
-- Name: action_trace_authorization; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.action_trace_authorization (
    block_num bigint NOT NULL,
    transaction_id character varying(64) NOT NULL,
    action_ordinal integer NOT NULL,
    ordinal integer NOT NULL,
    transaction_status chain.transaction_status_type,
    actor character varying(13),
    permission character varying(13)
);


ALTER TABLE chain.action_trace_authorization OWNER TO test;

--
-- Name: action_trace_ram_delta; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.action_trace_ram_delta (
    block_num bigint NOT NULL,
    transaction_id character varying(64) NOT NULL,
    action_ordinal integer NOT NULL,
    ordinal integer NOT NULL,
    transaction_status chain.transaction_status_type,
    account character varying(13),
    delta bigint
);


ALTER TABLE chain.action_trace_ram_delta OWNER TO test;

--
-- Name: block_info; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.block_info (
    block_num bigint NOT NULL,
    block_id character varying(64),
    "timestamp" timestamp without time zone,
    producer character varying(13),
    confirmed integer,
    previous character varying(64),
    transaction_mroot character varying(64),
    action_mroot character varying(64),
    schedule_version bigint,
    new_producers_version bigint
);


ALTER TABLE chain.block_info OWNER TO test;

--
-- Name: code; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.code (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    vm_type smallint NOT NULL,
    vm_version smallint NOT NULL,
    code_hash character varying(64) NOT NULL,
    code bytea
);


ALTER TABLE chain.code OWNER TO test;

--
-- Name: contract_index128; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.contract_index128 (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    code character varying(13) NOT NULL,
    scope character varying(13) NOT NULL,
    "table" character varying(13) NOT NULL,
    primary_key numeric NOT NULL,
    payer character varying(13),
    secondary_key numeric
);


ALTER TABLE chain.contract_index128 OWNER TO test;

--
-- Name: contract_index256; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.contract_index256 (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    code character varying(13) NOT NULL,
    scope character varying(13) NOT NULL,
    "table" character varying(13) NOT NULL,
    primary_key numeric NOT NULL,
    payer character varying(13),
    secondary_key character varying(64)
);


ALTER TABLE chain.contract_index256 OWNER TO test;

--
-- Name: contract_index64; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.contract_index64 (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    code character varying(13) NOT NULL,
    scope character varying(13) NOT NULL,
    "table" character varying(13) NOT NULL,
    primary_key numeric NOT NULL,
    payer character varying(13),
    secondary_key numeric
);


ALTER TABLE chain.contract_index64 OWNER TO test;

--
-- Name: contract_index_double; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.contract_index_double (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    code character varying(13) NOT NULL,
    scope character varying(13) NOT NULL,
    "table" character varying(13) NOT NULL,
    primary_key numeric NOT NULL,
    payer character varying(13),
    secondary_key double precision
);


ALTER TABLE chain.contract_index_double OWNER TO test;

--
-- Name: contract_index_long_double; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.contract_index_long_double (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    code character varying(13) NOT NULL,
    scope character varying(13) NOT NULL,
    "table" character varying(13) NOT NULL,
    primary_key numeric NOT NULL,
    payer character varying(13),
    secondary_key bytea
);


ALTER TABLE chain.contract_index_long_double OWNER TO test;

--
-- Name: contract_row; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.contract_row (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    code character varying(13) NOT NULL,
    scope character varying(13) NOT NULL,
    "table" character varying(13) NOT NULL,
    primary_key numeric NOT NULL,
    payer character varying(13),
    value bytea
);


ALTER TABLE chain.contract_row OWNER TO test;

--
-- Name: contract_table; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.contract_table (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    code character varying(13) NOT NULL,
    scope character varying(13) NOT NULL,
    "table" character varying(13) NOT NULL,
    payer character varying(13)
);


ALTER TABLE chain.contract_table OWNER TO test;

--
-- Name: fill_status; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.fill_status (
    head bigint,
    head_id character varying(64),
    irreversible bigint,
    irreversible_id character varying(64),
    first bigint
);


ALTER TABLE chain.fill_status OWNER TO test;

--
-- Name: generated_transaction; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.generated_transaction (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    sender character varying(13) NOT NULL,
    sender_id numeric NOT NULL,
    payer character varying(13),
    trx_id character varying(64),
    packed_trx bytea
);


ALTER TABLE chain.generated_transaction OWNER TO test;

--
-- Name: permission; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.permission (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    owner character varying(13) NOT NULL,
    name character varying(13) NOT NULL,
    parent character varying(13),
    last_updated timestamp without time zone,
    auth_threshold bigint,
    auth_keys chain.key_weight[],
    auth_accounts chain.permission_level_weight[],
    auth_waits chain.wait_weight[]
);


ALTER TABLE chain.permission OWNER TO test;

--
-- Name: permission_link; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.permission_link (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    account character varying(13) NOT NULL,
    code character varying(13) NOT NULL,
    message_type character varying(13) NOT NULL,
    required_permission character varying(13)
);


ALTER TABLE chain.permission_link OWNER TO test;

--
-- Name: protocol_state; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.protocol_state (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    activated_protocol_features chain.activated_protocol_feature_v0[]
);


ALTER TABLE chain.protocol_state OWNER TO test;

--
-- Name: received_block; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.received_block (
    block_num bigint NOT NULL,
    block_id character varying(64)
);


ALTER TABLE chain.received_block OWNER TO test;

--
-- Name: resource_limits; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.resource_limits (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    owner character varying(13) NOT NULL,
    net_weight bigint,
    cpu_weight bigint,
    ram_bytes bigint
);


ALTER TABLE chain.resource_limits OWNER TO test;

--
-- Name: resource_limits_config; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.resource_limits_config (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    cpu_limit_parameters_target numeric,
    cpu_limit_parameters_max numeric,
    cpu_limit_parameters_periods bigint,
    cpu_limit_parameters_max_multiplier bigint,
    cpu_limit_parameters_contract_rate_numerator numeric,
    cpu_limit_parameters_contract_rate_denominator numeric,
    cpu_limit_parameters_expand_rate_numerator numeric,
    cpu_limit_parameters_expand_rate_denominator numeric,
    net_limit_parameters_target numeric,
    net_limit_parameters_max numeric,
    net_limit_parameters_periods bigint,
    net_limit_parameters_max_multiplier bigint,
    net_limit_parameters_contract_rate_numerator numeric,
    net_limit_parameters_contract_rate_denominator numeric,
    net_limit_parameters_expand_rate_numerator numeric,
    net_limit_parameters_expand_rate_denominator numeric,
    account_cpu_usage_average_window bigint,
    account_net_usage_average_window bigint
);


ALTER TABLE chain.resource_limits_config OWNER TO test;

--
-- Name: resource_limits_state; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.resource_limits_state (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    average_block_net_usage_last_ordinal bigint,
    average_block_net_usage_value_ex numeric,
    average_block_net_usage_consumed numeric,
    average_block_cpu_usage_last_ordinal bigint,
    average_block_cpu_usage_value_ex numeric,
    average_block_cpu_usage_consumed numeric,
    total_net_weight numeric,
    total_cpu_weight numeric,
    total_ram_bytes numeric,
    virtual_net_limit numeric,
    virtual_cpu_limit numeric
);


ALTER TABLE chain.resource_limits_state OWNER TO test;

--
-- Name: resource_usage; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.resource_usage (
    block_num bigint NOT NULL,
    present boolean NOT NULL,
    owner character varying(13) NOT NULL,
    net_usage_last_ordinal bigint,
    net_usage_value_ex numeric,
    net_usage_consumed numeric,
    cpu_usage_last_ordinal bigint,
    cpu_usage_value_ex numeric,
    cpu_usage_consumed numeric,
    ram_usage numeric
);


ALTER TABLE chain.resource_usage OWNER TO test;

--
-- Name: transaction_trace; Type: TABLE; Schema: chain; Owner: test
--

CREATE TABLE chain.transaction_trace (
    block_num bigint NOT NULL,
    transaction_ordinal integer NOT NULL,
    failed_dtrx_trace character varying(64),
    id character varying(64),
    status chain.transaction_status_type,
    cpu_usage_us bigint,
    net_usage_words bigint,
    elapsed bigint,
    net_usage numeric,
    scheduled boolean,
    account_ram_delta_present boolean,
    account_ram_delta_account character varying(13),
    account_ram_delta_delta bigint,
    "except" character varying,
    error_code numeric,
    partial_present boolean,
    partial_expiration timestamp without time zone,
    partial_ref_block_num integer,
    partial_ref_block_prefix bigint,
    partial_max_net_usage_words bigint,
    partial_max_cpu_usage_ms smallint,
    partial_delay_sec bigint,
    partial_signatures character varying[],
    partial_context_free_data bytea[]
);


ALTER TABLE chain.transaction_trace OWNER TO test;

--
-- Name: account_metadata account_metadata_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.account_metadata
    ADD CONSTRAINT account_metadata_pkey PRIMARY KEY (block_num, present, name);


--
-- Name: account account_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.account
    ADD CONSTRAINT account_pkey PRIMARY KEY (block_num, present, name);


--
-- Name: action_trace_auth_sequence action_trace_auth_sequence_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.action_trace_auth_sequence
    ADD CONSTRAINT action_trace_auth_sequence_pkey PRIMARY KEY (block_num, transaction_id, action_ordinal, ordinal);


--
-- Name: action_trace_authorization action_trace_authorization_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.action_trace_authorization
    ADD CONSTRAINT action_trace_authorization_pkey PRIMARY KEY (block_num, transaction_id, action_ordinal, ordinal);


--
-- Name: action_trace action_trace_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.action_trace
    ADD CONSTRAINT action_trace_pkey PRIMARY KEY (block_num, transaction_id, action_ordinal);


--
-- Name: action_trace_ram_delta action_trace_ram_delta_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.action_trace_ram_delta
    ADD CONSTRAINT action_trace_ram_delta_pkey PRIMARY KEY (block_num, transaction_id, action_ordinal, ordinal);


--
-- Name: block_info block_info_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.block_info
    ADD CONSTRAINT block_info_pkey PRIMARY KEY (block_num);


--
-- Name: code code_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.code
    ADD CONSTRAINT code_pkey PRIMARY KEY (block_num, present, vm_type, vm_version, code_hash);


--
-- Name: contract_index128 contract_index128_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.contract_index128
    ADD CONSTRAINT contract_index128_pkey PRIMARY KEY (block_num, present, code, scope, "table", primary_key);


--
-- Name: contract_index256 contract_index256_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.contract_index256
    ADD CONSTRAINT contract_index256_pkey PRIMARY KEY (block_num, present, code, scope, "table", primary_key);


--
-- Name: contract_index64 contract_index64_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.contract_index64
    ADD CONSTRAINT contract_index64_pkey PRIMARY KEY (block_num, present, code, scope, "table", primary_key);


--
-- Name: contract_index_double contract_index_double_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.contract_index_double
    ADD CONSTRAINT contract_index_double_pkey PRIMARY KEY (block_num, present, code, scope, "table", primary_key);


--
-- Name: contract_index_long_double contract_index_long_double_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.contract_index_long_double
    ADD CONSTRAINT contract_index_long_double_pkey PRIMARY KEY (block_num, present, code, scope, "table", primary_key);


--
-- Name: contract_row contract_row_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.contract_row
    ADD CONSTRAINT contract_row_pkey PRIMARY KEY (block_num, present, code, scope, "table", primary_key);


--
-- Name: contract_table contract_table_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.contract_table
    ADD CONSTRAINT contract_table_pkey PRIMARY KEY (block_num, present, code, scope, "table");


--
-- Name: generated_transaction generated_transaction_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.generated_transaction
    ADD CONSTRAINT generated_transaction_pkey PRIMARY KEY (block_num, present, sender, sender_id);


--
-- Name: permission_link permission_link_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.permission_link
    ADD CONSTRAINT permission_link_pkey PRIMARY KEY (block_num, present, account, code, message_type);


--
-- Name: permission permission_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.permission
    ADD CONSTRAINT permission_pkey PRIMARY KEY (block_num, present, owner, name);


--
-- Name: protocol_state protocol_state_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.protocol_state
    ADD CONSTRAINT protocol_state_pkey PRIMARY KEY (block_num, present);


--
-- Name: received_block received_block_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.received_block
    ADD CONSTRAINT received_block_pkey PRIMARY KEY (block_num);


--
-- Name: resource_limits_config resource_limits_config_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.resource_limits_config
    ADD CONSTRAINT resource_limits_config_pkey PRIMARY KEY (block_num, present);


--
-- Name: resource_limits resource_limits_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.resource_limits
    ADD CONSTRAINT resource_limits_pkey PRIMARY KEY (block_num, present, owner);


--
-- Name: resource_limits_state resource_limits_state_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.resource_limits_state
    ADD CONSTRAINT resource_limits_state_pkey PRIMARY KEY (block_num, present);


--
-- Name: resource_usage resource_usage_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.resource_usage
    ADD CONSTRAINT resource_usage_pkey PRIMARY KEY (block_num, present, owner);


--
-- Name: transaction_trace transaction_trace_pkey; Type: CONSTRAINT; Schema: chain; Owner: test
--

ALTER TABLE ONLY chain.transaction_trace
    ADD CONSTRAINT transaction_trace_pkey PRIMARY KEY (block_num, transaction_ordinal);


--
-- Name: fill_status_bool_idx; Type: INDEX; Schema: chain; Owner: test
--

CREATE UNIQUE INDEX fill_status_bool_idx ON chain.fill_status USING btree ((true));


--
-- Name: action_trace action_trace_insert; Type: TRIGGER; Schema: chain; Owner: test
--

CREATE TRIGGER action_trace_insert AFTER INSERT ON chain.action_trace FOR EACH ROW EXECUTE PROCEDURE chain.action_trace_notify_trigger();


--
-- PostgreSQL database dump complete
--

