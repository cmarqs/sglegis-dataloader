const csv = require('./helpers/csvHandle');
const mysql = require('mysql2');
const fs = require('fs');
const config = require('./config');

// const estados = require('./states');
// const cidades = require('./cities');
// const leis_artigos_aspectos = require('./leis_artigos_aspecto');
const data = require('./load-data');

// estados.importStates();
// cidades.importCities();
// leis_artigos_aspectos.importData();
// console.log('Terminou.');

  
  async function doAsync () {
    var start = Date.now(), time;
    console.log(`Iniciado: ${0}`);
    time = await data.importData();
    console.log(`Terminado ${time - start}`);
    // time = await cidades.importCities();
    // console.log(time - start);
    // time = await leis_artigos_aspectos.importData();
    // console.log(time - start);
    //  process.exit();
  }
  
doAsync();