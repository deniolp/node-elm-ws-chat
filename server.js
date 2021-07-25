'use strict';

const {Server} = require(`ws`);
const {v4} = require(`uuid`);
const {writeFile, readFileSync, existsSync} = require(`fs`);

const clients = {};
const log = existsSync(`log.txt`) && readFileSync(`log.txt`);
const messages = JSON.parse(log) || [];

const webSocketSever = new Server({port: 4000});

webSocketSever.on(`connection`, (ws) => {
    const id = v4();
    clients[id] = ws;

    console.log(`New client was connected: ${id}`);
    ws.send(JSON.stringify(messages));

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

process.on(`SIGINT`, () => {
  webSocketSever.close();
  writeFile(`log.txt`, JSON.stringify(messages), (err) => {
    if (err) {
      console.log(err);
    }

    process.exit();
  })
});
