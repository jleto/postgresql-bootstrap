do $$
	declare strStagingLoadProperties json = '{"input_db_host":"localhost", "input_db_name":"company", "input_db_user":"postgres","input_db_password":"P23f5h7l", "input_db_sql":"select * from etl.job", "output_db_host":"localhost","output_db_name":"company","output_db_user":"postgres","output_db_password":"P23f5h7l", "output_db_schema":"staging","output_db_table":"job","output_db_sql":""}';
	declare connectionTypeId bigint;
begin

	insert into etl.connection_type (key, name)
	values ('postgres-9.4', 'PostgreSQL v9.4 Database');

	select id into connectionTypeId
	from etl.connection_type
	where key = 'postgres-9.4';

	insert into etl.connection_type (key, name)
	values ('openstack-3.0', 'OpenStack v3.0 REST API');

	insert into etl.connection_type (key, name)
	values ('vmware-vsphere-4.0', 'VMWare vSphere v4.0 REST API');

	insert into etl.connection_type (key, name)
	values ('aws-ec2-2015-10-01', 'AWS EC2 v2015-10-01 REST API');

	insert into etl.connection_manager(key, connection_type_id, properties)
	values ('postgres_local',connectionTypeId,'{"server":"localhost", "database":"company","user":"postgres", "password":"P23f5h7l", "schema":"etl", "table":"test"}'::json);

	insert into etl.job_package (key, name, batch_interval, batch_format)
	values ('x1', 'X1 Cloud', '1 day', 'YYYYMMDD');

	insert into etl.job_package (key, name, batch_interval, batch_format)
	values ('cim', 'Comcast Interactive Media', '1 day', 'YYYYMMDD');

	insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id, properties)
	values (
		null,
		'x1_cloud_metrics_insight_load',
		(select id from etl.job_package where key = 'x1'),
		(select id from etl.connection_manager where key = 'postgres_local'),
		strStagingLoadProperties
	); 

	insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id, properties)
	values (
		(select id from etl.job_template where key = 'x1_cloud_metrics_insight_load'),
		'x1_cloud_metrics_staging1_load',(select id from etl.job_package where key = 'x1'),
		(select id from etl.connection_manager where key = 'postgres_local'),
		strStagingLoadProperties
	); 

	insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id, properties)
	values (
		(select id from etl.job_template where key = 'x1_cloud_metrics_insight_load'),
		'x1_cloud_metrics_staging2_load',(select id from etl.job_package where key = 'x1'),
		(select id from etl.connection_manager where key = 'postgres_local'),
		strStagingLoadProperties
	); 

	insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id, properties)
	values (
		(select id from etl.job_template where key = 'x1_cloud_metrics_insight_load'),
		'x1_cloud_metrics_staging3_load',
		(select id from etl.job_package where key = 'x1'),
		(select id from etl.connection_manager where key = 'postgres_local'),
		strStagingLoadProperties
	); 

	insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id, properties)
	values (
		(select id from etl.job_template where key = 'x1_cloud_metrics_staging3_load'),
		'x1_cloud_metrics_staging4_load',(select id from etl.job_package where key = 'x1'),
		(select id from etl.connection_manager where key = 'postgres_local'),
		strStagingLoadProperties
	); 


	insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id, properties)
	values (
		null,
		'cim_cloud_metrics_insight_load',
		(select id from etl.job_package where key = 'cim'),
		(select id from etl.connection_manager where key = 'postgres_local'),
		strStagingLoadProperties
	); 

	insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id, properties)
	values (
		(select id from etl.job_template where key = 'cim_cloud_metrics_insight_load'),
		'cim_cloud_metrics_staging1_load',
		(select id from etl.job_package where key = 'cim'),
		(select id from etl.connection_manager where key = 'postgres_local'),
		strStagingLoadProperties
	);

	insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id, properties)
	values (
		(select id from etl.job_template where key = 'cim_cloud_metrics_insight_load'),
		'cim_cloud_metrics_staging2_load',
		(select id from etl.job_package where key = 'cim'),
		(select id from etl.connection_manager where key = 'postgres_local'),
		strStagingLoadProperties
	);

	insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id, properties)
	values (
		(select id from etl.job_template where key = 'cim_cloud_metrics_insight_load'),
		'cim_cloud_metrics_staging3_load',
		(select id from etl.job_package where key = 'cim'),
		(select id from etl.connection_manager where key = 'postgres_local'),
		strStagingLoadProperties
	);

	insert into etl.job_template (parent_id, key, job_package_id, connection_manager_id, properties)
	values (
		(select id from etl.job_template where key = 'cim_cloud_metrics_staging3_load'),
		'cim_cloud_metrics_staging4_load',
		(select id from etl.job_package where key = 'cim'),
		(select id from etl.connection_manager where key = 'postgres_local'),
		strStagingLoadProperties
	);

	perform etl.fn_generate_batch();
	
exception when others then
	raise notice '% %', SQLERRM, SQLSTATE;
	rollback;
end $$;