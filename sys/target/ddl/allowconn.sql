/***********************************************************************************************************************************
allowconn.sql

Allows connections to database.
**********************************************************************************************************************************/;

-- Allow connections to the db again (unless it is a clean instance)
update pg_database set datallowconn = true where datname = 'opiniator_dev';
--commit;
