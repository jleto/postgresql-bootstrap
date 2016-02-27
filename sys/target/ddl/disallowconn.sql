/***********************************************************************************************************************************
disallowconn.sql

Make sure the db cannot accept new connections while update is going on.
**********************************************************************************************************************************/;
-- Make sure that no connections are made while script is running
update pg_database set datallowconn = false where datname = 'opiniator_dev';
-- 	commit;
