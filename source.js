const csv = require('./helpers/csvHandle');
const mysql = require('mysql2');
const fs = require('fs');
const config = require('./config');

const estados = require('./states');
const cidades = require('./cities');
const data = require('./load-data');

  async function doAsync () {
    var start = Date.now(), time;

    console.log(`Iniciado: ${0}`);
    time = await data.importData();
    console.log(`Terminado ${time - start}`);

  }
  
doAsync();