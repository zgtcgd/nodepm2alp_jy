const port = process.env.PORT || 3000;
const FILE_PATH = process.env.FILE_PATH || '/tmp';
const intervalInseconds = process.env.TIME || 180;
const express = require("express");
const app = express();
const fs = require("fs");
const { spawn } = require('child_process');

app.get("/", function (req, res) {
  res.status(200).send("hello world");
});

app.get("/healthcheck", function (req, res) {
  res.status(200).send("ok");
});

app.get("/list", function (req, res) {
  let filePath = FILE_PATH + "/tmp.txt";
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.type("html").send("<pre>File read error：\n" + err + "</pre>");
    }
    else {
      res.type("html").send("<pre>Node data：\n\n" + data + "</pre>");
    }
  });
});

app.get("/sub", (req, res) => {
  let subfilePath = FILE_PATH + "/log.txt";
  fs.readFile(subfilePath, (err, data) => {
    if (err) {
      res.status(500).send('Error reading file');
    }
    else {
      res.type("txt").send(data);
    }
  });
});

// run
const startScriptPath = `/app/start.sh`;
const childProcess = spawn(startScriptPath, [], {
  detached: false,
  stdio: 'inherit',
});

app.listen(port, () => console.log(`server is listening on port ${port}!`));
