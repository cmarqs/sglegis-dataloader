const csv = require('./helpers/csvHandle');
const mysql = require('mysql2');
const fs = require('fs');
const config = require('./config');


// create the connection, specify bluebird as Promise
const pool = mysql.createPool(config.development);

const tableName = 'tmpDocuments';


loadFile(
    '/Users/cleiton/Downloads/Planilha de leis_MUNICIPAL_1_A_64_FINALIZADO.csv',
    'UTF-8',
    ';',
    ['ESTADO','MUNICIPIO','ANEXO','DOCUMENTO','NUMERO','DATA','EMENTA','STATUS']
);

function loadFile (arquivo, encode, separador, columns) {
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
            csv.readCsvNew(arquivo, encode, separador, columnSet, chunks, (data) => {

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

    conn.query(`CREATE TABLE ${tableName} (${columns});`,
        function (err, results, fields) {
            console.log(err);
            console.log(results); // results contains rows returned by server
            console.log(fields); // fields contains extra meta data about results, if available
        });
}

function saveDb (conn, tableName, columnSet, data) {
    let values = [];
    data.forEach(d => {
        values.push(Object.values(d));
    });

    var sql = `INSERT INTO ${tableName} (${columnSet}) VALUES ?`;
    conn.query(sql, [values], function (err) {
        if (err) throw err;
    });
    console.log(`Saved this \n ${values} \n`);

}