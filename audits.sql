use sglegis_hmlg_database;

select * from customers c
inner join customers_units cu on c.customer_id = cu.customer_id
where c.customer_business_name = 'SCHERING DO BRASIL QUÍMICA E FARMACÊUTICA LTDA';

select count(1) from tmpAuditoria;


-- INSERT AUDIT
insert into audits (unit_id, item_area_aspect_id, createdAt)
select
    1 as customer_unit_id, iaa.item_area_aspect_id, now() as createdAt
from tmpAuditoria as tmp
inner join /* area e aspect */
(
    select a.area_id, a.area_name, aa.area_aspect_id, aa.area_aspect_name
    from areas_aspects aa
    inner join areas a on aa.area_id = a.area_id
    -- where aa.area_aspect_name = 'ÁGUA' and a.area_name = 'MEIO AMBIENTE'
) aa on tmp.ASPECTO = aa.area_aspect_name and tmp.SG = aa.area_name
inner join /* document scope */
(
    select ds.document_scope_id, ds.document_scope_description
    from document_scopes ds
    -- where ds.document_scope_description = 'FEDERAL'
) ds on tmp.AMBITO = ds.document_scope_description
inner join /* document */
(
    select doc.document_id, doc.document_type, doc.document_number, doc.document_date, doc.document_summary
    from documents doc
    -- where doc.document_type = 'DECRETO' and doc.document_number = 24643 and doc.document_date = date_add(date('1899-12-31'), interval (12610 -1) day ) and doc.document_summary = 'DECRETA O CÓDIGO DE ÁGUAS.'
) doc on tmp.DOCUMENTO = doc.document_type and tmp.NUMERO = doc.document_number and date_add(date('1899-12-31'), interval (tmp.DATA -1) day) = doc.document_date and tmp.EMENTA = doc.document_summary
inner join /* document item */
(
    select di.document_id, di.document_item_id, di.document_item_number, di.document_item_description
    from document_items di
    -- where di.document_item_number = 'ART.2' and di.document_id = 2182
) di on tmp.ITEM = di.document_item_number and di.document_id = doc.document_id
    /* INTER JOINS */
inner join items_areas_aspects iaa on iaa.area_id = aa.area_id and iaa.area_aspect_id = aa.area_aspect_id and iaa.document_item_id = di.document_item_id
ON DUPLICATE KEY UPDATE updatedAt = now();


insert into audit_items (audits_audit_id, audit_practical_order, audit_conformity, audit_evidnece_compliance, audit_control_action, user_id, createdat)
select
       a.audit_id,
        CASE
            WHEN tmp.ORDEMPRATICA = "SIM" THEN 2
            WHEN tmp.ORDEMPRATICA = "NÃO" THEN 3
            ELSE 1
        END as pratical_order,
        CASE
            WHEN tmp.ATENDE = "NÃO SE APLICA" THEN 2
            WHEN tmp.ATENDE = "SIM" THEN 3
            WHEN tmp.ATENDE = "NÃO" THEN 4
            WHEN tmp.ATENDE = "FUTURO" THEN 5
            WHEN tmp.ATENDE = "PARCIAL" THEN 6
            ELSE 1
        END as conformity,
       tmp.EVIDENCIA,
       tmp.CONTROLE,
       1 as user_id, /* CLEITON */
        now() as createdAt
FROM (
select
    tmp.ORDEMPRATICA, tmp.ATENDE, tmp.EVIDENCIA, tmp.CONTROLE, item_area_aspect_id
from tmpAuditoria as tmp
inner join /* area e aspect */
(
    select a.area_id, a.area_name, aa.area_aspect_id, aa.area_aspect_name
    from areas_aspects aa
    inner join areas a on aa.area_id = a.area_id
) aa on tmp.ASPECTO = aa.area_aspect_name and tmp.SG = aa.area_name
inner join /* document scope */
(
    select ds.document_scope_id, ds.document_scope_description
    from document_scopes ds
) ds on tmp.AMBITO = ds.document_scope_description
inner join /* document */
(
    select doc.document_id, doc.document_type, doc.document_number, doc.document_date, doc.document_summary
    from documents doc
) doc on tmp.DOCUMENTO = doc.document_type and tmp.NUMERO = doc.document_number and date_add(date('1899-12-31'), interval (tmp.DATA -1) day) = doc.document_date and tmp.EMENTA = doc.document_summary
inner join /* document item */
(
    select di.document_id, di.document_item_id, di.document_item_number, di.document_item_description
    from document_items di
) di on tmp.ITEM = di.document_item_number and di.document_id = doc.document_id
    /* INTER JOINS */
inner join items_areas_aspects iaa on iaa.area_id = aa.area_id and iaa.area_aspect_id = aa.area_aspect_id and iaa.document_item_id = di.document_item_id
) as tmp
inner join audits a on tmp.item_area_aspect_id = a.item_area_aspect_id and a.unit_id = 1 /* SCHERING */
ON DUPLICATE KEY UPDATE updatedAt = now();

