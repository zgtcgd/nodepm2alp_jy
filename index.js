const port = process.env.PORT || 3000;
const FILE_PATH = process.env.FILE_PATH || '/tmp';
const express = require("express");
const app = express();
var fs = require("fs");
const { spawn } = require('child_process');

app.get("/", function (req, res) {
  res.status(200).send("hello world");
});

app.get("/healthcheck", function (req, res) {
  res.status(200).send("ok");
});

//获取节点数据
app.get("/list", function (req, res) {
  let filePath = FILE_PATH + "/list.txt";
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.type("html").send("<pre>文件读取错误：\n" + err + "</pre>");
    }
    else {
      res.type("html").send("<pre>节点数据：\n\n" + data + "</pre>");
    }
  });
});

//获取订阅数据
app.get("/sub", (req, res) => {
  let subfilePath = FILE_PATH + "/sub.txt";
  fs.readFile(subfilePath, (err, data) => {
    if (err) {
      res.status(500).send('Error reading file');
    }
    else {
      res.type("txt").send(data);
    }
  });
});

//获取系统进程表
app.get("/status", function (req, res) {
  let cmdStr = "ps -ef";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    }
    else {
      res.type("html").send("<pre>获取系统进程表：\n" + stdout + "</pre>");
    }
  });
});

// 启动主程序
const startScriptPath = `/app/start.sh`;
const childProcess = spawn(startScriptPath, [], {
  detached: false,
  stdio: 'inherit',
});

app.listen(port, () => console.log(`Example app listening on port ${port}!`));
