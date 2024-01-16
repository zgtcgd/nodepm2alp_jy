const port = process.env.PORT || 3000;
const FILE_PATH = process.env.FILE_PATH || '/tmp';
const http = require('http');
const fs = require('fs');
var exec = require("child_process").exec;

const listFilePath = FILE_PATH + '/list.txt';
const subFilePath = FILE_PATH + '/sub.txt';

const server = http.createServer((req, res) => {
  if (req.url === '/') {
    res.writeHead(200);
    res.end('hello world');

  } else if (req.url === '/healthcheck') {
    res.writeHead(200);
    res.end('ok');

  } else if (req.url === '/list') {
    fs.readFile(listFilePath, 'utf8', (error, data) => {
      if (error) {
        res.writeHead(500);
        res.end('Error reading file');
      } else {
        res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end(data);
      }
    });

  } else if (req.url === '/sub') {
    fs.readFile(subFilePath, 'utf8', (error, data) => {
      if (error) {
        res.writeHead(500);
        res.end('Error reading file');
      } else {
        res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end(data);
      }
    });
  } else {
    res.writeHead(404);
    res.end('Not found');
  }
});

//启动主程序
exec("bash /app/start.sh", function (err, stdout, stderr) {
  if (err) {
    console.error(err);
    return;
  }
  console.log(stdout);
});

server.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
