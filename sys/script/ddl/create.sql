﻿/***********************************************************************************************************************************
create.sql

Create a database and all standard roles.
**********************************************************************************************************************************/;

/***********************************************************************************************************************************
Create the database roles and grant permissions on all tablespaces.
**********************************************************************************************************************************/;
do $$
declare
    xTablespace record;
    strRoleName text = '@db_user@';
    strDbName text = '@db_instance_name@';
begin
    if
    (
        select count(*) = 0 
          from pg_roles 
         where rolname = strRoleName
    ) then
        execute 'create role ' || strRoleName || ' noinherit createrole';
        
        execute 'create role ' || strRoleName || '_reader';
        execute 'create role ' || strRoleName || '_user';
        execute 'create role ' || strRoleName || '_admin';
        execute 'create role ' || strRoleName || '_internal';
        execute 'create user ' || strRoleName || '_etl with password ''' || strRoleName || '_etl''';

        execute 'grant ' || strRoleName || '_reader to ' || strRoleName || '_user';
        execute 'grant ' || strRoleName || '_user to ' || strRoleName || '_admin';
        execute 'grant ' || strRoleName || '_user to ' || strRoleName || '_internal';
        execute 'grant ' || strRoleName || '_user to ' || strRoleName || '_etl';
    end if;

    for xTablespace in
        select spcname as name
          from pg_tablespace
    loop
        execute 'grant create on tablespace ' || xTablespace.name || ' to ' || strRoleName;
    end loop;
    
end $$;

/***********************************************************************************************************************************
Create the database and connect to it.
**********************************************************************************************************************************/;
create database @db_instance_name@ with owner @db_user@ encoding = 'UTF8' tablespace = @db_tablespace_default@;
revoke all on database @db_instance_name@ from public;
\connect @db_instance_name@
update pg_database set datallowconn = false where datname = '@db_instance_name@';

/***********************************************************************************************************************************
Drop the default public schema.
**********************************************************************************************************************************/;
drop schema public;

/***********************************************************************************************************************************
Make C a trusted language so contrib functions can be added (only the db owner can create functions so this is safe).
**********************************************************************************************************************************/;
update pg_language set lanpltrusted = true where lanname = 'c'; 

/***********************************************************************************************************************************
Allow the reader role to connect
**********************************************************************************************************************************/;
do $$
declare
    strRoleName text = '@db_user@';
    strDbName text = '@db_instance_name@';
begin
    execute 'grant connect on database ' || strDbName || ' to ' || strRoleName || '_reader';
end $$;
