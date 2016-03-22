create or replace function etl.fn_generate_batch()
returns void as $$
declare r record;
		batch_interval text;
		batch_format text;
		batch_key text;
		max_batch_key text;
		new_batch_key text;
begin

    for r in
		select * from etl.job_package
    loop
		select r.batch_interval into batch_interval;
		select r.batch_format into batch_format;

		new_batch_key := to_char(current_timestamp, (batch_format)::text);

		if not exists((select key from etl.batch where job_package_id = r.id))
		then
			raise notice 'batch key is null';
			insert into etl.batch(key, job_package_id)
			values (new_batch_key, r.id);
		else
			raise notice 'batch key exists';
			select max(key) into max_batch_key
			from etl.batch
			where job_package_id = r.id;

			if (to_char(current_timestamp - (batch_interval)::interval, (batch_format)::text)::bigint >= max_batch_key::bigint)
			then
				insert into etl.batch(key, job_package_id)
				values (new_batch_key, r.id);
			end if;	
			
		end if;
		
    end loop;

end $$ language plpgsql;

/*
truncate table etl.batch cascade;
select etl.fn_generate_batch()
*/