const http = require('http');

const listenHost = process.env.LISTEN_HOST || '127.0.0.1';
const port = process.env.PORT || 8080;

const GREETING = 'Hello';

const server = http.createServer((req, res) => {
  console.log(new Date().toISOString(), req.url, req.headers['x-request-id'], req.headers['user-agent']);
  const reqstatus = /\W(\d{3})$/.exec(req.url);
  const status = reqstatus ? parseInt(reqstatus[1]) : 200;
  const reqdelay = /\Wdelay=(\d+)/.exec(req.url);
  const delay = reqdelay ? parseInt(reqdelay[1]) : 100;
  setTimeout(() => {
    res.writeHead(status, {"Content-Type": "text/plain"});
    res.end(`${GREETING} status=${status} after delay=${delay}ms\n`);
  }, delay);
});

server.listen(port, listenHost, () => {
  console.log(`Server running at http://${listenHost}:${port}/`);
});
