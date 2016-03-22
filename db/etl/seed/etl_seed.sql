insert into etl.connection_type (key, name)
values ('database', 'Database');

insert into etl.connection_type (key, name)
values ('rest_api', 'REST API');

insert into etl.connection_manager(key, connection_type_id, properties)
values ('postgres_local',(select id from etl.connection_type where key = 'database'),'{"server":"localhost", "database":"company","user":"postgres", "password":"P23f5h7l", "schema":"etl", "table":"test"}'::json);

insert into etl.job_package (key, name, batch_interval, batch_format)
values ('x1', 'X1 Cloud', '1 day', 'YYYYMMDD');

insert into etl.job_package (key, name, batch_interval, batch_format)
values ('cim', 'Comcast Interactive Media', '1 day', 'YYYYMMDD');

insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id)
values (null, 'x1_cloud_metrics_insight_load',(select id from etl.job_package where key = 'x1'), (select id from etl.connection_manager where key = 'postgres_local')); 

insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id)
values ((select id from etl.job_template where key = 'x1_cloud_metrics_insight_load'), 'x1_cloud_metrics_staging1_load',(select id from etl.job_package where key = 'x1'), (select id from etl.connection_manager where key = 'postgres_local')); 

insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id)
values ((select id from etl.job_template where key = 'x1_cloud_metrics_insight_load'), 'x1_cloud_metrics_staging2_load',(select id from etl.job_package where key = 'x1'), (select id from etl.connection_manager where key = 'postgres_local')); 

insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id)
values ((select id from etl.job_template where key = 'x1_cloud_metrics_insight_load'), 'x1_cloud_metrics_staging3_load',(select id from etl.job_package where key = 'x1'), (select id from etl.connection_manager where key = 'postgres_local')); 

insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id)
values (null, 'cim_cloud_metrics_insight_load',(select id from etl.job_package where key = 'cim'), (select id from etl.connection_manager where key = 'postgres_local')); 

insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id)
values ((select id from etl.job_template where key = 'cim_cloud_metrics_insight_load'), 'cim_cloud_metrics_staging1_load', (select id from etl.job_package where key = 'cim'), (select id from etl.connection_manager where key = 'postgres_local'));

insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id)
values ((select id from etl.job_template where key = 'cim_cloud_metrics_insight_load'), 'cim_cloud_metrics_staging2_load', (select id from etl.job_package where key = 'cim'), (select id from etl.connection_manager where key = 'postgres_local'));

insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id)
values ((select id from etl.job_template where key = 'cim_cloud_metrics_insight_load'), 'cim_cloud_metrics_staging3_load', (select id from etl.job_package where key = 'cim'), (select id from etl.connection_manager where key = 'postgres_local'));


do $$
begin
 perform etl.fn_generate_batch();
end $$;