use sglegis;
select * from document_attachments da;

select * from tmpAttachments;



-- insert into document_attachments (attachment_item_id, attachment_description, attachment_src, document_id, createdAt, updatedAt)
select 
 /*
	0 as attachment_item_id,
	CONCAT(doc.documento, '_', doc.numero) as attachment_description,
 	CONCAT(IFNULL(x.e, tmp.Anexo), '.pdf') as attachment_src,
 	doc.document_id,
 	now() as createdAt,
 	now() as updatedAt */
*
from tmpAttachments tmp
inner join (
select
	d.document_id, s.uf, c.city_name as city, ds.status_description as status, d.document_type as documento, d.document_number as numero, date_format(d.document_date, '%Y-%m-%d') as ddate, d.document_summary as ementa
from documents d 
inner join document_status ds on d.document_status_id = ds.status_id 
left join states s on d.document_state_id = s.state_id 
left join cities c on d.document_city_id = c.city_id
) doc on 
	tmp.UF = doc.uf and 
	tmp.CIDADE = doc.city and 
	tmp.STATUS = doc.status and 
	tmp.DOCUMENTO = doc.documento and 
	tmp.NUMERO = doc.numero and 
	date_add(date('1899-12-31'), interval (tmp.`DATA` -1) day ) = doc.ddate
left join (
select trim(e) as e from split_string_into_rows where split_string_into_rows
(
(select group_concat(anexo) from (
select tmp.* from tmpAttachments tmp
inner join (
select
	s.uf, c.city_name as city, ds.status_description as status, d.document_type as documento, d.document_number as numero, date_format(d.document_date, '%Y-%m-%d') as ddate, d.document_summary as ementa
from documents d 
inner join document_status ds on d.document_status_id = ds.status_id 
left join states s on d.document_state_id = s.state_id 
left join cities c on d.document_city_id = c.city_id
) doc on 
	tmp.UF = doc.uf and 
	tmp.CIDADE = doc.city and 
	tmp.STATUS = doc.status and 
	tmp.DOCUMENTO = doc.documento and 
	tmp.NUMERO = doc.numero and 
	date_add(date('1899-12-31'), interval (tmp.`DATA` -1) day ) = doc.ddate
where instr(tmp.anexo, ',')
) dados)
)) x on instr(tmp.anexo, ',') and instr(tmp.anexo, x.e)
