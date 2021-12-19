use sgLegis;
use sglegis_hmlg_database;

-- atualiza os ambitos corretamente
select DISTINCT tlaa.FEDERAL, tlaa.ESTADO, tlaa.MUNICIPIO 
from tmpLeisArtigosAspecto tlaa ;

UPDATE tmpLeisArtigosAspecto set AMBITO = 'FEDERAL' where FEDERAL = 'Brasil';
UPDATE tmpLeisArtigosAspecto set AMBITO = 'ESTADUAL' where ESTADO IS NOT NULL and MUNICIPIO IS NULL;
UPDATE tmpLeisArtigosAspecto set AMBITO = 'MUNICIPAL' where MUNICIPIO IS NOT NULL;

select * from documents;

insert into documents (document_scope_id,document_type,document_number,document_date,document_status_id,document_summary,document_state_id,document_city_id,createdAt,updatedAt)
select distinct tmp.document_scope_id, tmp.document_type, tmp.document_number, tmp.document_date, tmp.document_status_id, tmp.document_summary, tmp.document_state_id, tmp.document_city_id, tmp.createdAt, tmp.updatedAt
 -- tmp.document_number, tmp.document_scope_id, tmp.document_date, tmp.document_state_id, tmp.document_city_id, COUNT(1) 
from (
	select distinct
		scp.document_scope_id,
		DOCUMENTO AS document_type, 
		NUMERO as document_number, 
		str_to_date(left(tmp.`DATA`, 10), '%d/%m/%Y') as document_date, 
		1 as document_status_id, -- EM VIGOR 
		tmp.ementa as document_summary,
		uf.state_id as document_state_id,
		cty.city_id as document_city_id,
		now() as createdAt,
		now() as updatedAt
	from tmpLeisArtigosAspecto tmp
	inner join document_scopes scp on UPPER(TRIM(tmp.AMBITO)) = scp.document_scope_description 
	inner join document_status sts on upper(TRIM(tmp.STATUS)) = sts.status_description 
	inner join states uf on UPPER(TRIM(tmp.ESTADO)) = UPPER(TRIM(uf.uf))
	inner join cities cty on UPPER(TRIM(tmp.MUNICIPIO)) = UPPER(TRIM(cty.city_name))
) tmp;
-- group by tmp.document_number, tmp.document_scope_id, tmp.document_date, tmp.document_state_id, tmp.document_city_id HAVING count(1) > 1;

// -- ITENS
;
insert into document_items (document_item_number, document_item_order, document_item_status_id, document_item_description, document_item_observation, document_id, createdAt, updatedAt)
;
select 
	tlaa.NUMERO as item_number,
	1 as item_order,
	sts.status_id as item_status,
	tlaa.DESCRICAO as item_description,
	null as item_observation,
	docs.document_id,
	now() as item_created,
	now() as item_updated
FROM tmpLeisArtigosAspecto tlaa 
inner join document_status sts on upper(TRIM(tlaa.STATUS)) = sts.status_description
inner join (
	select d.document_id, d.document_number, d.document_date, ds.document_scope_description as document_scope, s.uf, c.city_name 
	from documents d
	inner join document_scopes ds on d.document_scope_id = ds.document_scope_id 
	left join states s on d.document_state_id = s.state_id 
	left join cities c on c.city_id = d.document_city_id 
) docs on tlaa.NUMERO = docs.document_number and str_to_date(left(tlaa.`DATA`, 10), '%d-%m-%Y') = docs.document_date 
and (docs.document_scope = 'FEDERAL') OR (docs.document_scope = 'ESTADUAL' = )
;


