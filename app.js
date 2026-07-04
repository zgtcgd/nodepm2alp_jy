const port = process.env.PORT || 3000;
const FILE_PATH = process.env.FILE_PATH || '/tmp';
const UUID = process.env.UUID;
const express = require("express");
const app = express();
const fs = require("fs");
const path = require("path");
const { spawn } = require('child_process');
const ENABLE_ARGO = process.env.ENABLE_ARGO || '1';

app.get('/', (req, res) => {
  const indexPath = path.join(__dirname, 'index.html');
  fs.access(indexPath, fs.constants.F_OK, (err) => {
    if (err) {
      res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('hello world');
    } else {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      fs.createReadStream(indexPath).pipe(res);
    }
  });
});

app.get(`/${UUID}`, (req, res) => {
  let subfilePath = path.join(FILE_PATH, "log.txt");
  fs.readFile(subfilePath, (err, data) => {
    if (err) {
      return res.status(500).send('Error reading file');
    }
    res.type("txt").send(data);
  });
});

if (ENABLE_ARGO === '1') {
  // do nothing
} else if (ENABLE_ARGO === '0') {
  const { createProxyMiddleware } = require("http-proxy-middleware");
  app.use(
    "/",
    createProxyMiddleware({
      changeOrigin: true,
      onProxyReq: function onProxyReq(proxyReq, req, res) {},
      pathRewrite: {
        "^/": "/"
      },
      target: "http://127.0.0.1:8080/",
      ws: true
    })
  );
}

// run
const startScriptPath = `/app/start.sh`;
const childProcess = spawn(startScriptPath, [], {
  detached: false,
  stdio: 'inherit',
});

app.listen(port, () => console.log(`server is listening on port ${port}!`));
