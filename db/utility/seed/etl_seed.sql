insert into _etl.provider (key, name) values ('opiniator', 'Opiniator');

insert into _etl.product (key, name, provider_id, frequency) values ('opiniator_insights','Opiniator Insights', (select id from _etl.provider where key = 'opiniator'), 'daily');

insert into _etl.batch (key, product_id) values (to_char(current_timestamp - interval '7 day', 'YYYY-MM-DD'), (select id from _etl.product where key = 'opiniator_insights'));

insert into _etl.workflow (key, name, active) values ('insight_load', 'Insight Load', true);

insert into _etl.workflow_job (workflow_id, parent_id, product_id, key, name) values ((select id from _etl.workflow where key = 'insight_load'), null, (select id from _etl.product where key = 'opiniator_insights'), 'insight_load_survey', 'Insight Load - Survey');
insert into _etl.workflow_job (workflow_id, parent_id, product_id, key, name) values ((select id from _etl.workflow where key = 'insight_load'), (select id from _etl.workflow_job where key = 'insight_load_survey'), (select id from _etl.product where key = 'opiniator_insights'), 'insight_load_supplemental', 'Insight Load - Supplemental');
insert into _etl.workflow_job (workflow_id, parent_id, product_id, key, name) values ((select id from _etl.workflow where key = 'insight_load'), (select id from _etl.workflow_job where key = 'insight_load_supplemental'), (select id from _etl.product where key = 'opiniator_insights'), 'insight_load_alert', 'Insight Load - Alert');

do $$
begin
 perform _etl.fn_generate_batch();
end $$;