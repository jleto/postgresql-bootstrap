create or replace function _etl.test()
returns void as $$
begin
 raise notice 'test';
end $$ language plpgsql;
