'use strict';

const {Server} = require(`ws`);
const {v4} = require(`uuid`);

const clients = {};
const messages = [];

const webSocketSever = new Server({port: 8000});

webSocketSever.on(`connection`, (ws) => {
    const id = v4();
    clients[id] = ws;

    console.log(`New client was connected: ${id}`);

    ws.on(`message`, (rawMessage) => {
        const {name, message} = JSON.parse(rawMessage);
        messages.push({name, message});
        for (const id in clients) {
          clients[id].send(JSON.stringify([{name, message}]));
        }
    })

    ws.on(`close`, () => {
        delete clients[id];
        console.log(`Client was closed: ${id}`)
    })
})
