const csv = require('./helpers/csvHandle');
const mysql = require('mysql2');
const fs = require('fs');
const config = require('./config');

// create the connection, specify bluebird as Promise
const pool = mysql.createPool(config.development);

exports.importData = () => {

    return new Promise(function(resolve, reject) {
        // do a thing, possibly async, then…
        try {
            console.log('Saving states');
            readAndSave('tmpStates', './states.csv', 'UTF-8', ';', ['cod_uf', 'sigla_uf', 'nome_uf']);

            console.log('Saving cities');
            readAndSave('tmpCities', './cities.csv', 'UTF-8', ';', ['idlocalidade', 'nome_localidade', 'cod_uf']);

            console.log('Saving documents and aspects');
            readAndSave('tmpLeisArtigosAspecto',
                '/Users/cleiton/Downloads/planilha_unificada.csv',
                'UTF-8',
                ';',
                ['QA', 'SS', 'MA', 'ASPECTO', 'AMBITO', 'MUNICIPIO', 'ESTADO', 'FEDERAL', 'ANEXO', 'DOCUMENTO', 'NUMERO', 'DATA', 'OBSERVACAO', 'STATUS', 'EMENTA', 'ITEM', 'DESCRICAO']
            );

            resolve(Date.now());
        } catch (err) {
            console.error(err);
            reject(Error("It broke: " + err));
        }
    });
    

};


function readAndSave (tableName, arquivo, encode, separador, columns) {
    const columnSet = columns;
    const columnSetObjectArray = [];
    columnSet.forEach(column => {
        columnSetObjectArray.push({ name: column });
    });

    // For pool initialization, see above
    pool.getConnection(function (err, conn) {
        // Do something with the connection
        //conn.query(/* ... */);
        if (!err) {
            createTempTable(conn, tableName, columnSet);

            const chunks = 10;
            csv.readCsvNew(arquivo, encode, separador, columnSet, chunks, true, (data) => {

                saveDb(conn, tableName, columnSet, data);
  
            });
        
            // Don't forget to release the connection when finished!
            pool.releaseConnection(conn);
        }
        else {
            console.error(err);
            throw(err)
        }
    });

};


function createTempTable (conn, tableName, columnSet) {
    console.log('(Re)Creating temp table');

    let columns = 'ID INT NOT NULL PRIMARY KEY AUTO_INCREMENT,';

    columnSet.forEach(c => {
        columns += `${c} TEXT,`
    });
    columns = columns.slice(0, -1); //remove last ,

    conn.query(`DROP TABLE IF EXISTS ${tableName};`);
    conn.query(`CREATE TABLE ${tableName} (${columns});`,
        function (err, results) {
            if (err) throw (err);
        }
    )
};

function saveDb (conn, tableName, columnSet, data) {
    console.log('Saving values (chunck) on database')

    let values = [];
    data.forEach(d => {
        values.push(Object.values(d));
        // console.log(values);
    });

    var sql = `INSERT INTO ${tableName} (${columnSet}) VALUES ?`;
    conn.query(sql, [values], function (err) {
        if (err) throw err;
    });
}
