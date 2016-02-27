/* database versioning */
create table _sys.version
(
	major int not null default 0,
	minor int not null default 0,
	revision int not null default 0,
	comment text null,
	constraint version_pk primary key (major, minor, revision)
);

comment on table _sys.version is
'Table to manage the version of the database.';

comment on column _sys.version.major is
'Major version number.';

comment on column _sys.version.minor is
'Minor version number.';

comment on column _sys.version.revision is
'Revision number.';

insert into _sys.version (major, minor, revision, comment) values (@version_major@, @version_minor@, @version_revision@, '@version_comment@');

create or replace function _sys.version_before_insert()
returns trigger as 
$$
begin
	if (select count(*) from _sys.version) = 0
	then
		return new;
	end if;
						
	return null;
end $$ language plpgsql;

create trigger version_before_insert
before insert on _sys.version
for each row
execute procedure _sys.version_before_insert();
