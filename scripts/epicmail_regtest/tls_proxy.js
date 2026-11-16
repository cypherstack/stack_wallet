'use strict';

const fs = require('node:fs');
const net = require('node:net');
const tls = require('node:tls');

const listenPort = Number(process.env.EPICMAIL_TLS_PORT || 43420);
const backendPort = Number(process.env.EPICMAIL_BACKEND_PORT || 43422);
const certDir = process.env.EPICMAIL_CERT_DIR;
if (!certDir) throw new Error('EPICMAIL_CERT_DIR is required');

const server = tls.createServer({
  cert: fs.readFileSync(certDir + '/tls.crt'),
  key: fs.readFileSync(certDir + '/tls.key'),
}, (front) => {
  const back = net.connect(backendPort, '127.0.0.1');
  front.pipe(back);
  back.pipe(front);
  front.on('error', () => back.destroy());
  back.on('error', () => front.destroy());
});

server.listen(listenPort, '127.0.0.1');
