/*
drop schema if exists etl cascade;
*/

create schema etl;

create sequence etl.connectiontype_id_seq start 1000000;
create sequence etl.connectionmanager_id_seq start 2000000;
create sequence etl.jobpackage_id_seq start 3000000;
create sequence etl.jobtemplate_id_seq start 4000000;
create sequence etl.job_id_seq start 1000000000;
create sequence etl.batch_id_seq start 2000000000;
create sequence etl.joblog_id_seq start 3000000000;

create table etl.connection_type (
	id bigint not null default nextval('etl.connectiontype_id_seq'),
	key text not null,
	name text not null,
	constraint connectiontype_pk primary key (id),
	constraint connectiontype_key_unq unique (key),
	constraint connectiontype_name_unq unique (name)
);

create table etl.connection_manager (
	id bigint not null default nextval('etl.connectionmanager_id_seq'),
	key text not null,
	connection_type_id bigint not null,
	properties json not null,
	constraint connectionmanager_pk primary key (id),
	constraint connectionmanager_connectiontypeid_fk foreign key (connection_type_id)
		references etl.connection_type (id),
	constraint connectionmanager_key_unq unique (key)
);

create table etl.job_package (
	id bigint not null default nextval('etl.jobpackage_id_seq'),	
	key text not null,
	name text not null,
	batch_interval text not null,
	batch_format text not null,
	etl_lock text null,
	constraint jobpackage_pk primary key (id),
	constraint jobpackage_key_unq unique (key),
	constraint jobpackage_name_unq unique (name),
	constraint jobpackage_etllock_unq unique (etl_lock)
);

create table etl.job_template (
	id bigint not null default nextval('etl.jobtemplate_id_seq'),
	parent_id bigint null,
	key text not null,
	job_package_id bigint not null,
	connection_manager_id bigint,
	properties json,
	constraint jobtemplate_pk primary key (id),
	constraint jobtemplate_jobpackageid_fk foreign key (job_package_id)
		references etl.job_package (id),
	constraint jobtemplate_connectionmanagerid_fk foreign key (connection_manager_id)
		references etl.connection_manager (id)
);

create table etl.batch (
	id bigint not null default nextval('etl.batch_id_seq'),
	key text not null,
	job_package_id bigint not null,
	constraint batch_pk primary key (id),
	constraint batch_jobpackageid_fk foreign key (job_package_id)
		references etl.job_package (id),
	constraint batch_keyjobpackageid_unq unique (key, job_package_id)
);

create table etl.job (
	id bigint not null default nextval('etl.job_id_seq'),
	parent_id bigint null,
	batch_id bigint not null,
	job_template_id bigint not null,
	status text not null default 'pending' check (status in ('pending', 'initiated', 'ready', 'running', 'completed', 'error', 'rollback')),
	modified timestamp default current_timestamp,
	constraint job_pk primary key (id),
	constraint job_parentid_fk foreign key (parent_id)
		references etl.job_template (id),
	constraint job_batchid_fk foreign key (batch_id)
		references etl.batch (id),
	constraint job_jobtemplateid_fk foreign key (job_template_id)
		references etl.job_template (id)
);

create or replace function etl.trg_job_status_update() returns trigger as $$
begin

	if new.status <> old.status
	then
		insert into etl.job_log (job_id, status_old, status_new, type, message)
		values (new.id, old.status, new.status, 'info', '[INFO] STATUS CHANGED');
	end if;

	return new;
	
end$$ language plpgsql;

create trigger job_status_update_trigger
after update on etl.job
	for each row execute procedure etl.trg_job_status_update();

create or replace function etl.trg_job_update() returns trigger as
$$
begin
	new.modified = current_timestamp;
	return new;
end $$ language plpgsql;

create trigger job_update_trigger
before update on etl.job
	for each row execute procedure etl.trg_job_update();

--batch trigger for job creation
create or replace function etl.trg_job_generate_batch_insert() returns trigger as $$
begin

	if not exists (select 1 from etl.job where batch_id = new.id)
	then	
		insert into etl.job (parent_id, batch_id, job_template_id)
		select parent_id, new.id, job_template.id
		from etl.job_template
		where job_package_id = new.job_package_id
		order by job_template.parent_id asc;
	end if;
	
	return new;
	
end$$ language plpgsql;

create trigger job_generate_batch_insert_trigger
after insert on etl.batch
	for each row execute procedure etl.trg_job_generate_batch_insert();


create table etl.job_log (
	id bigint not null default nextval('etl.joblog_id_seq'),
	job_id bigint not null,
	status_old text not null check (status_old in ('pending', 'initiated', 'ready', 'running', 'completed', 'error', 'rollback')),
	status_new text not null check (status_new in ('pending', 'initiated', 'ready', 'running', 'completed', 'error', 'rollback')),
	type text not null default 'info' check (type in ('info', 'debug', 'error')),
	message text not null,
	modified timestamp not null default current_timestamp,
	constraint joblog_pk primary key (id),
	constraint joblog_jobid_fk foreign key (job_id)
		references etl.job (id)
);