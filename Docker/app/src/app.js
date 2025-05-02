require('dotenv').config({ path: './src/.env' });

const express = require('express');
const app = express();
const os = require('os');
const packageJson = require('../package.json');

const { info, manejarError, auditar, generarTraceId } = require('./middlewares/logger');

const message = process.env.MESSAGE || "BUENAS TARDES";
const hostname = os.hostname();

app.use((req, res, next) => {
    if (typeof generarTraceId === 'function') {
        generarTraceId(req, res, next);
    } else {
        console.error('Middleware error:', new Error('Middleware function not found'));
        res.status(500).send('Internal Server Error');
    }
});

app.get('/hola-mundo/v1/healthcheck', function (req, res) {
    try {
        // Get the headers of the request 
        info('Incoming Headers:', req.traceId, req.headers);

        let date_obj = new Date();
        let date = ("0" + (date_obj.getDate())).slice(-2); // day
        let month = ("0" + (date_obj.getMonth() + 1)).slice(-2); // current month
        let year = date_obj.getFullYear(); // current year
        let hours = date_obj.getHours(); // get current hour
        let minutes = date_obj.getMinutes(); // get current minutes
        let seconds = date_obj.getSeconds(); // get seconds
        let version = packageJson.version;
        let fecha = date + "/" + month + "/" + year + " " + hours + ":" + minutes + ":" + seconds;
        let responseObject = { "message": message, "datetime": fecha, "hostname": hostname, "version": version };
        res.json(responseObject);
    } catch (error) {
        manejarError(error, req, res);
    }
});
app.get('/hola-mundo/v1/force-error', (req, res) => {
    try {
        throw new Error("Error for testing logging functionality");
    } catch (err) {
        manejarError(err, req, res); // Esto llevará el error al middleware `manejarError`
    }
});

module.exports = app; // Exporta la aplicación configurada pero no la ejecutes aquí 
