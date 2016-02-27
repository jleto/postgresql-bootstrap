/* Create build schema to manage system information. */
create schema _sys;

comment on schema _sys is
'Schema to manage system information.';

grant usage on schema _sys to public;

/***********************************************************************************************************************************
Create Extensions
**********************************************************************************************************************************/;
do $$
begin
	create extension pgcrypto schema pg_catalog;
	create extension "uuid-ossp" schema pg_catalog;
	create extension tablefunc schema _sys;
end $$;

/***********************************************************************************************************************************
Set Search Path
**********************************************************************************************************************************/;
do $$
declare
    strRoleName text = '@db_user@';
    strDbName text = '@db_instance_name@';
begin
    execute 'alter database ' || strDbName || ' set search_path to _sys';
end $$;

