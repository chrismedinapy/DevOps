const request = require('supertest');
const server = require('../server'); // Importa el servidor configurado

describe('GET /hola-mundo/v1/healthcheck', () => {
    it('Debería retornar el estado 200 y un objeto JSON con la información correcta', async () => {
        const response = await request(server)
            .get('/hola-mundo/v1/healthcheck')
            .expect(200);

        expect(response.body).toHaveProperty('message');
        expect(response.body).toHaveProperty('datetime');
        expect(response.body).toHaveProperty('hostname');
        expect(response.body).toHaveProperty('version');
    });


});
afterAll(async () => {
  // Cerrar la conexión al servidor
  await server.close();
});