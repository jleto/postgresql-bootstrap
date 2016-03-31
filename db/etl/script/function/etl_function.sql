
create or replace view etl.vw_dependent_path
as
	select etl_lock, array_agg(dependent_path) as path
	from 
	(
		WITH RECURSIVE job_next(job_id, batch_id, status, job_template_id, parent_id, depth) AS (
				SELECT jb.id,
						jb.batch_id,
						jb.status,
						jb.job_template_id,
						jb.parent_id,
						0 as depth,
						ARRAY[jb.job_template_id] as path,
						false as cycle,
						case when (jb.status <> 'pending' and jb.status <> 'completed') then true else false end as dependency
				FROM etl.job jb
				where jb.parent_id is null
			  UNION
				SELECT jb.id,
				jb.batch_id,
				jb.status,
				jb.job_template_id,
				jb.parent_id,
				jn.depth + 1,
				path || jb.job_template_id,
				jb.job_template_id = ANY(path),
				case when (jb.status <> 'pending' and jb.status <> 'completed') then true else false end as dependency
				FROM etl.job jb
				join job_next jn on jb.parent_id = jn.job_template_id
		)
		SELECT job_package.etl_lock, 
			   unnest(path) as dependent_path
		FROM job_next
		inner join etl.job_template
			on job_next.job_template_id = job_template.id
		inner join etl.job_package
			on job_template.job_package_id = job_package.id
		and dependency
	) job_tree
	group by etl_lock;


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
			insert into etl.batch(key, job_package_id)
			values (new_batch_key, r.id);
		else
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
    
exception when others then
	raise notice '% %', SQLERRM, SQLSTATE;
	
end $$ language plpgsql;

create or replace function etl.fn_next_job(strEtlLock text) returns table(
																			batch_id bigint,
																			batch_key text,
																			status text,
																			job_id bigint,
																			job_parent_id bigint,
																			job_template_id bigint,
																			job_template_key text,
																			job_template_properties json,
																			connection_type_key text,
																			connection_key text,
																			connection_properties json
																		)
as $$
begin
    return query
	WITH RECURSIVE job_next(job_id, batch_id, status, job_template_id, parent_id, depth) AS (
			SELECT jb.id,
					jb.batch_id,
					jb.status,
					jb.job_template_id,
					jb.parent_id,
					0 as depth,
					ARRAY[jb.job_template_id] as path,
					false as cycle
			FROM etl.job jb
			where jb.status = 'pending'
				and jb.parent_id is null
		  UNION
			SELECT jb.id,
			jb.batch_id,
			jb.status,
			jb.job_template_id,
			jb.parent_id,
			jn.depth + 1,
			path || jb.job_template_id,
			jb.job_template_id = ANY(path)
			FROM etl.job jb
			join job_next jn on jb.parent_id = jn.job_template_id
			where jb.status = 'pending'
	)
	SELECT 	batch.id as batch_id, 
			batch.key as batch_key,
			job_next.status,
			job_next.job_id,
			job_next.parent_id,
			job_next.job_template_id,
			job_template.key as job_template_key,
			job_template.properties as job_template_properties,
			connection_type.key as connection_type_key,
			connection_manager.key as connection_key,
			connection_manager.properties as connection_properties
	FROM job_next
	inner join etl.batch
		on batch.id = job_next.batch_id
	inner join etl.job_template
		on job_next.job_template_id = job_template.id
	inner join etl.connection_manager
		on job_template.connection_manager_id = connection_manager.id
	inner join etl.connection_type
		on connection_manager.connection_type_id = connection_type.id
	inner join etl.job_package
		on job_template.job_package_id = job_package.id
	where job_package.etl_lock = strEtlLock
	order by job_next.batch_id asc, job_next.depth desc, job_next.path asc
	limit 1;
end$$ language plpgsql;

create or replace function etl.fn_initiate_next_job(strEtlLock text)
returns table(
	batch_key text,
	job_id bigint,
	job_key text,
	job_properties text,
	connection_type_key text,
	connection_key text,
	connection_properties text
) as
$$
	declare r record;
begin

FOR r IN 
    
	SELECT 	jn.job_id,
			jn.batch_id,
			jn.batch_key,
			jn.status,
			jn.job_parent_id,
			jn.job_template_id,
			jn.job_template_key,
			jn.job_template_properties,
			jn.connection_type_key,
			jn.connection_key,
			jn.connection_properties
	FROM etl.fn_next_job(strEtlLock) jn
	limit 1
	loop

		if exists (
			select r.job_parent_id = ANY(path)
			from etl.vw_dependent_path
			where etl_lock = strEtlLock
		)
		then
			return query
			select 	r.batch_key as batch_key,
					-2::bigint as job_id,
					r.job_template_key as job_template_key,
					r.job_template_properties::text as job_template_properties,
					r.connection_type_key as connection_type_key,
					r.connection_key as connection_key,
					r.connection_properties::text as connection_properties;
		else 
			if (r.status = 'pending')
			then 
				update etl.job
				set status = 'initiated'
				where job.id = r.job_id;
			end if;
			
			return query
			select 	r.batch_key,
					r.job_id,
					r.job_template_key,
					r.job_template_properties::text,
					r.connection_type_key,
					r.connection_key,
					r.connection_properties::text;
		end if;

	end loop;
			
end$$ language plpgsql;

create or replace function etl.fn_package_lock() returns table (job_package_id bigint, etl_lock text) as 
$$
	declare r record;
begin
	for r in
		WITH RECURSIVE job_next(job_id, batch_id, status, job_template_id, parent_id, depth) AS (
				SELECT jb.id, jb.batch_id, jb.status, jb.job_template_id, jb.parent_id, 0 as depth,
				ARRAY[jb.job_template_id] as path,
				false as cycle
				FROM etl.job jb
				where jb.status = 'pending'
				and jb.parent_id is null
			  UNION
				SELECT jb.id, jb.batch_id, jb.status, jb.job_template_id, jb.parent_id, jn.depth + 1,
				path || jb.job_template_id,
				jb.job_template_id = ANY(path)
				FROM etl.job jb
				join job_next jn on jb.parent_id = jn.job_template_id
				where jb.status = 'pending'
		)
		SELECT 	batch.id as batch_id, 
				batch.key as batch_key,
				job_next.status,
				job_next.job_id,
				job_next.job_template_id,
				job_template.key as job_template_key,
				job_package.id as job_package_id,
				connection_type.key as connection_type_key,
				connection_manager.key as connection_key,
				connection_manager.properties as connection_properties
		FROM job_next
		inner join etl.batch
			on batch.id = job_next.batch_id
		inner join etl.job_template
			on job_next.job_template_id = job_template.id
		inner join etl.connection_manager
			on job_template.connection_manager_id = connection_manager.id
		inner join etl.connection_type
			on connection_manager.connection_type_id = connection_type.id
		inner join etl.job_package
			on job_template.job_package_id = job_package.id
		where job_package.etl_lock is null
		order by batch_id asc, depth desc, path asc
		limit 1
	loop

		update etl.job_package
		set etl_lock = utility.random_string(32)
		where job_package.id = r.job_package_id;
		
		return query
		select id as job_package_id,
			   job_package.etl_lock
		from etl.job_package
		where id = r.job_package_id;
		
	end loop;
	
end $$ language plpgsql;

create or replace function etl.fn_package_release_lock(strEtlLock text) returns boolean
as $$
	declare 
begin
	if not exists (
		select job.*
		from etl.job
		inner join etl.job_template
			on job.job_template_id = job_template.id
		inner join etl.job_package
			on job_template.job_package_id = job_package.id
		where status <> 'completed'
		and job_package.etl_lock = strEtlLock
		limit 1
	)
	then
		update etl.job_package
		set etl_lock = null
		where etl_lock = strEtlLock;

		return true;
	end if;

	return false;
end $$ language plpgsql;

create or replace function etl.job_batch_expire() returns void
as $$
begin

	update etl.job u_job
	set status = 'expired'
	from etl.job
	inner join etl.batch
	on job.batch_id = batch.id
	inner join etl.job_template
		on job.job_template_id = job_template.id
	inner join etl.job_package
		on job_template.job_package_id = job_package.id
	where job.status = 'pending'
	and job.id = u_job.id
	and batch.key < to_char(current_timestamp, (job_package.batch_format)::text);
	
end $$ language plpgsql;