const fs = require('fs');
const reader = require('csv-reader');
const assert = require('assert');

function readCsvNew(filepath, encoding, separator, columnSet, chunkLenght, allCaptal = false, callback) {

    let dataChunk = [];
    let inputStream = fs.createReadStream(filepath, encoding)

    inputStream
        .pipe(new reader({ trim: true, delimiter: separator, skipHeader: false, parseNumbers:true, allowQuotes: true, parseBooleans: true, trim:true, asObject: true,  }))
        .on('header', validateHeader)
        .on('error', handleError)
        .on('data', handleData)
        .on('end', handleFinish);


    function validateHeader(headerObteined) {
        let headerExpected = columnSet;
        return assert.deepStrictEqual(headerObteined, headerExpected, 'O cabeçalho não coincide com o template.')
    }

    function handleError(err) {
        throw err;
    }

    function handleData(data) {

        if (data) {
            Object.keys(data).forEach(function (key) {
                if (data[key] === 'NA' || data[key] === '') {
                    data[key] = undefined;
                }
                else{
                    if (allCaptal && isNaN(data[key])){
                        data[key] = (data[key]).toUpperCase();
                    }
                }
            });
            dataChunk.push(data);
        }

        if (dataChunk.length >= chunkLenght) {
            //process the chunk of data
            callback(dataChunk);

            //reset the chunk
            dataChunk = [];
        }
    }

    function handleFinish() {
        if (dataChunk.length > 0)
            callback(dataChunk);
    }
}

module.exports = { readCsvNew };