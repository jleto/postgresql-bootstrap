/* database timestamp */
create table _sys.origin
(
	birthday timestamp not null default current_timestamp,
	constraint origin_pk primary key (birthday)
);

comment on table _sys.origin is
'Table to hold a readonly date and time set at build time.';

comment on column _sys.origin.birthday is
'The date and time the database was created.';

insert into _sys.origin (birthday) values (current_timestamp);

create or replace function _sys.origin_before_insert()
returns trigger as 
$$
begin
	if (select count(*) from _sys.origin) = 0
	then
		return new;
	end if;
						
	return null;
end $$ language plpgsql;

create trigger origin_before_insert
before insert on _sys.origin
for each row
execute procedure _sys.origin_before_insert();
