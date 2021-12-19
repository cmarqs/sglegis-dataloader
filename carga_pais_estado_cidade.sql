use sgLegis;
select * from document_scopes ds ; 
/*
2	FEDERAL
3	ESTADUAL
4	MUNICIPAL
 */
select * from document_status ds ;
/*
1	EM VIGOR
2	REVOGADA
3	EM JULGAMENTO
 */

-- #################### ESCOPO FEDERAL 
select 
count(1) as DUPLICADOS,
NUMERO, `DATA`, AMBITO
from (
	select 
		COALESCE(tlf.NUMERO, 0) as NUMERO,
		tlf.`DATA`,
		'FEDERAL' AS AMBITO
	from tmpLeisFederais tlf 
) as dados
group by NUMERO, `DATA`, AMBITO HAVING count(1) > 1
;


insert into documents (document_scope_id, document_type, document_number, document_date, document_status_id, document_summary, document_state_id, document_city_id, createdAt)
select
2 as document_scope,
tlf.DOCUMENTO as document_type,
tlf.NUMERO as document_number,
 STR_TO_DATE(tlf.`DATA`, '%d/%m/%Y') as document_date,
CASE
    WHEN tlf.STATUS = 'EM VIGOR' THEN 1
    WHEN tlf.STATUS = 'REVOGADO' THEN 2
    WHEN tlf.STATUS = 'REVOGADA' THEN 2
    WHEN tlf.STATUS = 'EM JULGAMENTO' THEN 3
    ELSE 1
END as document_status,
tlf.EMENTA as document_summary,
null as document_state,
null as document_city,
now() as createdAt
from tmpLeisFederais tlf
;

-- #################### ESCOPO ESTADUAL
select
count(1) as DUPLICADOS,
NUMERO, `DATA`, AMBITO
from (
	select 
		COALESCE(tle.NUMERO, 0) as NUMERO,
		tle.`DATA`,
		'ESTADUAL' AS AMBITO
	from tmpLeisEstaduais tle 
) as dados
group by NUMERO, `DATA`, AMBITO HAVING count(1) > 1
;


insert into documents (document_scope_id, document_type, document_number, document_date, document_status_id, document_summary, document_state_id, document_city_id, createdAt)
select
3 as document_scope,
tle.DOCUMENTO as document_type,
tle.NUMERO as document_number,
 STR_TO_DATE(tle.`DATA`, '%d/%m/%Y') as document_date,
CASE
    WHEN tle.STATUS = 'EM VIGOR' THEN 1
    WHEN tle.STATUS = 'REVOGADO' THEN 2
    WHEN tle.STATUS = 'REVOGADA' THEN 2
    WHEN tle.STATUS = 'EM JULGAMENTO' THEN 3
    ELSE 1
END as document_status,
tle.EMENTA as document_summary,
s.state_id,
null as document_city,
now() as createdAt
from tmpLeisEstaduais tle
left join states s on tle.estado = s.uf 
;

-- #################### ESCOPO MUNICIPAL
select
count(1) as DUPLICADOS,
NUMERO, `DATA`, AMBITO
from (
	select 
		COALESCE(tlm.NUMERO, 0) as NUMERO,
		tlm.`DATA`,
		'ESTADUAL' AS AMBITO
	from tmpLeisMunicipais tlm 
) as dados
group by NUMERO, `DATA`, AMBITO HAVING count(1) > 1
;

insert into documents (document_scope_id, document_type, document_number, document_date, document_status_id, document_summary, document_state_id, document_city_id, createdAt)
select
3 as document_scope,
tlm.DOCUMENTO as document_type,
tlm.NUMERO as document_number,
 STR_TO_DATE(tlm.`DATA`, '%d/%m/%Y') as document_date,
CASE
    WHEN tlm.STATUS = 'EM VIGOR' THEN 1
    WHEN tlm.STATUS = 'REVOGADO' THEN 2
    WHEN tlm.STATUS = 'REVOGADA' THEN 2
    WHEN tlm.STATUS = 'EM JULGAMENTO' THEN 3
    ELSE 1
END as document_status,
tlm.EMENTA as document_summary,
s.state_id,
null as document_city,
now() as createdAt
from tmpLeisMunicipais tlm
left join states s on tlm.estado = s.uf 
left join cities c on tlm.
;
