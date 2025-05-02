const app = require('./app');

const port = process.env.PORT || 3000;

const server = app.listen(port, () => {
    console.log(`This service is listening on port ${port}!`);
});

module.exports = server; // Exporta el servidor para las pruebas
