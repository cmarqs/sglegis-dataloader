use sglegis_hmlg_database;

insert into document_status (status_description, createdAt, updatedAt) values
('EM VIGOR',now(), now()),
('REVOGADA',now(), now()),
('SUSPENSA',now(), now()),
('FUTURO', now(), now());

insert into document_scopes (document_scope_description, createdAt, updatedAt) values
('GLOBAL',now(), now()),
('FEDERAL',now(), now()),
('ESTADUAL',now(), now()),
('MUNICIPAL',now(), now());

SET FOREIGN_KEY_CHECKS = 0;
    truncate table ceps;
    truncate table cities;
SET FOREIGN_KEY_CHECKS = 1;


insert into states (state_id, state_name, uf, createdAt)
select cod_uf, nome_uf, sigla_uf, now() from tmpStates;


insert into cities (city_id, state_id, city_name, uf, createdAt)
select tc.idlocalidade, st.cod_uf, tc.nome_localidade, st.sigla_uf, now() from tmpCities tc inner join tmpStates st on tc.cod_uf = st.cod_uf ;


insert into areas (area_name, createdAt, updatedAt) VALUES ('QUALIDADE', now(), now());
insert into areas (area_name, createdAt, updatedAt) VALUES ('SAÚDE E SEGURANÇA', now(), now());
insert into areas (area_name, createdAt, updatedAt) VALUES ('MEIO AMBIENTE', now(), now());



UPDATE tmpLeisArtigosAspecto set AMBITO = 'FEDERAL' where FEDERAL = 'Brasil';
UPDATE tmpLeisArtigosAspecto set AMBITO = 'ESTADUAL' where ESTADO IS NOT NULL and MUNICIPIO IS NULL;
UPDATE tmpLeisArtigosAspecto set AMBITO = 'MUNICIPAL' where MUNICIPIO IS NOT NULL;

UPDATE tmpLeisArtigosAspecto SET ASPECTO = REPLACE(REPLACE(ASPECTO, '\r', ''), '\n', '');

insert into areas_aspects (area_aspect_name, area_id, createdAt, updatedAt)
select
	DISTINCT
	(UPPER(TRIM(tmp.ASPECTO))) as ASPECTO,
	a.area_id,
	NOW() as dtCreated,
	NOW() as dtUpdated
from tmpLeisArtigosAspecto tmp
inner join areas a on upper(tmp.QA)  = 'X' and 'QUALIDADE' = a.area_name ;

insert into areas_aspects (area_aspect_name, area_id, createdAt, updatedAt)
select
	DISTINCT
	(UPPER(TRIM(tmp.ASPECTO))) as ASPECTO,
	a.area_id,
	NOW() as dtCreated,
	NOW() as dtUpdated
from tmpLeisArtigosAspecto tmp
inner join areas a on upper(tmp.SS)  = 'X' and 'SAÚDE E SEGURANÇA' = a.area_name ;

insert into areas_aspects (area_aspect_name, area_id, createdAt, updatedAt)
select
	DISTINCT
	(UPPER(left(TRIM(tmp.ASPECTO), 100))) as ASPECTO,
	a.area_id,
	NOW() as dtCreated,
	NOW() as dtUpdated
from tmpLeisArtigosAspecto tmp
inner join areas a on upper(tmp.MA)  = 'X' and 'MEIO AMBIENTE' = a.area_name and tmp.ASPECTO is not null;


insert into documents (document_scope_id,document_type,document_number,document_date,document_status_id,document_summary,document_state_id,document_city_id,createdAt,updatedAt)
select distinct tmp.document_scope_id, tmp.document_type, tmp.document_number, tmp.document_date, tmp.document_status_id, tmp.document_summary, tmp.document_state_id, tmp.document_city_id, tmp.createdAt, tmp.updatedAt
--  document_scope_id,document_type,document_number,document_date,document_status_id,document_summary,document_state_id,document_city_id, COUNT(1)
from (
	select distinct
		scp.document_scope_id,
		DOCUMENTO AS document_type,
		NUMERO as document_number,
		date_add(date('1899-12-31'), interval tmp.`DATA` day ) as document_date,
		1 as document_status_id, -- EM VIGOR
		coalesce(tmp.ementa, 'sem ementa') as document_summary,
		uf.state_id as document_state_id,
		cty.city_id as document_city_id,
		now() as createdAt,
		now() as updatedAt
	from tmpLeisArtigosAspecto tmp
	inner join document_scopes scp on UPPER(TRIM(tmp.AMBITO)) = scp.document_scope_description
	inner join document_status sts on upper(TRIM(tmp.STATUS)) = sts.status_description
	inner join areas a on ((upper(tmp.MA)  = 'X' and 'MEIO AMBIENTE' = a.area_name) or (upper(tmp.QA)  = 'X' and 'QUALIDADE' = a.area_name) or (upper(tmp.SS)  = 'X' and 'SAÚDE E SEGURANÇA' = a.area_name))
	inner join areas_aspects aa on a.area_id = aa.area_id and aa.area_aspect_name = (UPPER(left(TRIM(tmp.ASPECTO), 100)))
	left join states uf on UPPER(TRIM(tmp.ESTADO)) = UPPER(TRIM(uf.uf))
	left join cities cty on UPPER(TRIM(tmp.ESTADO)) = UPPER(TRIM(uf.uf)) and UPPER(TRIM(tmp.MUNICIPIO)) = UPPER(TRIM(cty.city_name))
) tmp
-- group by document_scope_id,document_type,document_number,document_date,document_status_id,document_summary,document_state_id,document_city_id
-- HAVING count(1) > 1
;

insert into document_items (document_item_number, document_item_order, document_item_status_id, document_item_description, document_item_observation, document_id, createdAt, updatedAt)
select distinct
       x.ITEM as document_item_number,
       1 as document_item_order,
       ds.status_id as document_item_status,
       x.DESCRICAO as document_item_description,
       x.OBSERVACAO as document_item_observation,
       docs.document_id,
       now() as createdAt,
       now() as updatedAt
from tmpLeisArtigosAspecto x
    inner join document_status ds on x.STATUS = ds.status_description
inner join (
    select d.document_id,
           d.document_summary,
           d.document_number,
           d.document_scope_id,
           ds.document_scope_description,
           date_format(d.document_date, '%Y-%m-%d') as document_date,
           d.document_state_id,
           uf.uf,
           d.document_city_id
    from documents d
             inner join document_scopes ds on d.document_scope_id = ds.document_scope_id
             left join states uf on d.document_state_id = uf.state_id
             left join cities c on c.state_id = d.document_state_id and c.city_id = d.document_city_id
) docs on x.NUMERO = docs.document_number AND
          date_add(date('1899-12-31'), interval x.`DATA` day ) = docs.document_date
where x.ITEM is not null;




/*--------- INITIAL DATA ----------- */

insert into customers_groups (customer_group_name, createdAt) values ('GRUPO UNITY', now());
INSERT INTO customers (customer_business_name, customer_cnpj, customer_group_id, createdAt, updatedAt) values ('UNITY', '00000000000101', 1, now(), now());
insert into customers_units (customer_unit_cnpj, customer_unit_name, customer_unit_address, customer_unit_city_id, customer_unit_uf_id, customer_unit_cep, customer_id, createdAt, updatedAt) values ('00000000000102', 'UNITY SKILL', 'Av. Pres. Kennedy, 3500', 9668, 26, '09520200', 1, now(), now());
INSERT INTO units_contacts (UNIT_CONTACT_NAME, UNIT_CONTACT_EMAIL, UNIT_CONTACT_PHONE, UNIT_CONTACT_OBSERVATION, UNIT_CONTACT_CUSTOMER_UNIT_ID, CREATEDAT, UPDATEDAT) VALUES ('NOME', 'NOME@UNITY.COM.BR', '(11) 0000 0000', 'DADOS DE TESTE', 1, NOW(), NOW());

insert into users (user_name, user_email, user_password, user_profile_type, user_role, createdAt, updatedAt)
values  ('cleiton',	'cleiton.marques@200.systems',	'$2a$10$7NHGMMpCf65GXu8sbY0/eOnqvWlS6Fco1tkQp9w4Plbx3sdG7wYQC',	'gestor',	'admin', now(), now()),
		('Andrea Souza',	'andrea.souza@unity.com.br',	'$2a$10$QMISAmUOAMaLyZ.uxDj4pOfOTQp.aOEB56QtP52.rHTbInZRh91FO',	'gestor',	'admin', now(), now()),
       ('Ana Lucia',	'analucia.lopes@unity.com.br',	'$2a$10$QMISAmUOAMaLyZ.uxDj4pOfOTQp.aOEB56QtP52.rHTbInZRh91FO',	'gestor',	'admin', now(), now());
