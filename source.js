const csv = require('./helpers/csvHandle');
const mysql = require('mysql2');
const fs = require('fs');
const config = require('./config');

const estados = require('./states');
const cidades = require('./cities');
const leis_artigos_aspectos = require('./leis_artigos_aspecto');

const run = async () => {
    await estados.importStates();
    console.log('Estados importados \r');

    await cidades.importCities();
    console.log('Cidades importadas \r');
}

run();
// estados.importStates();
// cidades.importCities();
// //leis_artigos_aspectos.importData();
// console.log('Terminou.');
