create or replace function create_tenant_schema(schema_name varchar)
    returns void as
$function$
begin
    execute format('create schema if not exists %I', schema_name);

    -- Creation of Users Table Per Tenant as SCHEMA
    execute format('
            create table %I.users(
                       id serial primary key,
                       customer_id serial not null,
                       email varchar(50) unique not null,
                       keycloak_id varchar(75) unique,
                       password text not null,
                       first_name varchar(50) not null,
                       last_name varchar(50) not null,
                       role varchar(50) not null default ''user'',
                       active boolean not null default true,
                       last_login timestamp,
                       created_at timestamp not null default now(),
                       updated_at timestamp,
                       constraint chk_role check (role in (''ADMIN'', ''EDITOR'', ''VIEWER'', ''API_CLIENT''))
            )', schema_name);

    -- Creation of Templates Table Per Tenant as SCHEMA
    execute format('
            create table %I.template(
                       id serial primary key,
                       customer_id integer not null,
                       name varchar(50) unique not null,
                       code varchar(100) unique not null,
                       description text,
                       current_version integer default 1,
                       metadata jsonb default ''{}''::jsonb,
                       created_at timestamp not null default now(),
                       updated_at timestamp
            )', schema_name);

    -- Creation of Template Versions Table Per Tenant as SCHEMA
    EXECUTE format('
            create table %I.template_version (
                id serial primary key,
                template_id integer not null references %I.template(id) on delete cascade,
                version integer not null,
                html_content text not null,
                field_schema jsonb not null,
                css_styles text,
                settings jsonb default ''{}''::jsonb,
                status varchar(20) not null default ''DRAFT'',
                created_by serial not null,
                created_at timestamp not null default NOW(),
                constraint uq_template_version unique (template_id, version),
                constraint chk_version_status check (status IN (''DRAFT'', ''PUBLISHED'', ''ARCHIVED''))
            )', schema_name, schema_name);

    EXECUTE format('
            create table %I.certificate (
                id serial primary key,
                customer_id integer not null,
                template_version_id integer not null references %I.template_version(id),
                certificate_number varchar(100) unique not null,
                recipient_data jsonb not null,
                metadata jsonb default ''{}''::jsonb,
                storage_path varchar(500),
                signed_hash varchar(512),
                status varchar(20) not null default ''PENDING'',
                issued_at timestamp with time zone,
                expires_at timestamp with time zone,
                issued_by serial,
                preview_generated_at timestamp with time zone,
                created_at timestamp not null default now(),
                updated_at timestamp not null default now(),
                constraint chk_certificate_status check (status IN (''PENDING'', ''PROCESSING'', ''ISSUED'', ''REVOKED'', ''FAILED''))
            )', schema_name, schema_name);

    EXECUTE format('
            create table %I.certificate_hash (
                id serial primary key,
                certificate_id integer unique not null references %I.certificate(id) on delete cascade,
                hash_algorithm varchar(50) not null,
                hash_value varchar(512) not null,
                salt varchar(255),
                created_at timestamp not null default now(),
                updated_at timestamp not null default now()
            )', schema_name, schema_name);

    EXECUTE format('
            create table %I.audit_log (
                id serial primary key,
                customer_id integer not null,
                user_id integer,
                entity_id integer,
                entity_type varchar(50),
                action varchar(50) not null,
                old_values jsonb,
                new_values jsonb,
                ip_address inet,
                user_agent text,
                created_at timestamp not null default now()
            )', schema_name);

    EXECUTE format('create index idx_%I_users_customer on %I.users(customer_id)', schema_name, schema_name);
    EXECUTE format('create index idx_%I_users_email on %I.users(email)', schema_name, schema_name);
    EXECUTE format('create index idx_%I_template_customer on %I.template(customer_id)', schema_name, schema_name);
    EXECUTE format('create index idx_%I_template_code on %I.template(code)', schema_name, schema_name);
    EXECUTE format('create index idx_%I_cert_number on %I.certificate(certificate_number)', schema_name, schema_name);
    EXECUTE format('create index idx_%I_cert_status on %I.certificate(status)', schema_name, schema_name);
    EXECUTE format('create index idx_%I_cert_issued_at on %I.certificate(issued_at DESC)', schema_name, schema_name);
    EXECUTE format('create index idx_%I_cert_preview_generated_at on %I.certificate(preview_generated_at)', schema_name,
                   schema_name);
    EXECUTE format('create index idx_%I_audit_created_at on %I.audit_log(created_at DESC)', schema_name, schema_name);
    EXECUTE format('create index idx_%I_audit_entity on %I.audit_log(entity_type, entity_id)', schema_name,
                   schema_name);
end;
$function$ language plpgsql;