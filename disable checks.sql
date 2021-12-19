use sgLegis;


    
SET FOREIGN_KEY_CHECKS = 0; 
    truncate table ceps;
    truncate table cities;
    truncate table states;
SET FOREIGN_KEY_CHECKS = 1;

insert into states (state_id , state_name, uf, createdAt)
select  cod_uf, nome_uf, sigla_uf, NOW() from tmpStates;


INSERT INTO cities (city_id, state_id, city_name, uf, createdAt)
select tc.idlocalidade, tc.cod_uf, tc.nome_localidade, s.uf, now() from tmpCities tc
left join states s on tc.cod_uf = s.state_id;


