const csv = require('./helpers/csvHandle');
const mysql = require('mysql2');
const fs = require('fs');
const config = require('./config');

// create the connection, specify bluebird as Promise
const pool = mysql.createPool(config.development);

const tableName = 'tmpLeisArtigosAspecto'

const errors = [];
const inserted = [];

importData = () => {
    loadFileData(
        '/Users/cleiton/Downloads/planilha_unificada.csv',
        'UTF-8',
        ';',
        ['QA', 'SS', 'MA', 'ASPECTO', 'AMBITO', 'MUNICIPIO', 'ESTADO', 'FEDERAL', 'ANEXO', 'DOCUMENTO', 'NUMERO', 'DATA', 'OBSERVACAO', 'STATUS', 'EMENTA', 'ITEM', 'DESCRICAO']
    );
};

function loadFileData (arquivo, encode, separador, columns) {
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

            const chunks = 100;
            csv.readCsvNew(arquivo, encode, separador, columnSet, chunks, true, (data) => {

                saveDb(conn, tableName, columnSet, data);
  
            });
        
            // Don't forget to release the connection when finished!
            pool.releaseConnection(conn);
        }
    });
};

function createTempTable (conn, tableName, columnSet) {

    let columns = 'ID INT NOT NULL PRIMARY KEY AUTO_INCREMENT,';

    columnSet.forEach(c => {
        columns += `${c} TEXT,`
    });
    columns = columns.slice(0, -1); //remove last ,

    conn.query(`DROP TABLE IF EXISTS ${tableName};`);
    conn.query(`CREATE TABLE ${tableName} (${columns});`,
        function (err, results, fields) {
            console.log(err);
            // console.log(results); // results contains rows returned by server
            // console.log(fields); // fields contains extra meta data about results, if available
        });
}

function saveDb (conn, tableName, columnSet, data) {
    let values = [];
    data.forEach(d => {
        values.push(Object.values(d));
    });

    var sql = `INSERT INTO ${tableName} (${columnSet}) VALUES ?`;
    conn.query(sql, [values], function (err) {
        if (err)
            errors.push(err);
        else
            inserted.push(values);
            //console.log(`Saved this \n ${values} \n`);
    });
}

function ExcelDateToJSDate(serial) {
    var utc_days  = Math.floor(serial - 25569);
    var utc_value = utc_days * 86400;                                        
    var date_info = new Date(utc_value * 1000);
 
    var fractional_day = serial - Math.floor(serial) + 0.0000001;
 
    var total_seconds = Math.floor(86400 * fractional_day);
 
    var seconds = total_seconds % 60;
 
    total_seconds -= seconds;
 
    var hours = Math.floor(total_seconds / (60 * 60));
    var minutes = Math.floor(total_seconds / 60) % 60;
 
    return new Date(date_info.getFullYear(), date_info.getMonth(), date_info.getDate(), hours, minutes, seconds);
 }
 

module.exports = {
    errors,
    inserted,
    importData
}