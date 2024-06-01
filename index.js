const port = process.env.PORT || 3000;
const FILE_PATH = process.env.FILE_PATH || '/tmp';
const axios = require("axios");
const projectPageURL = process.env.URL || '';
const intervalInMilliseconds = process.env.TIME || 5 * 60 * 1000;
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

// 启动主程序
const startScriptPath = `/app/start.sh`;
const childProcess = spawn(startScriptPath, [], {
  detached: false,
  stdio: 'inherit',
});

// 自动访问项目URL
let hasLoggedEmptyMessage = false;
async function visitProjectPage() {
  try {
    // 如果URL和TIME变量为空时跳过访问项目URL
    if (!projectPageURL || !intervalInMilliseconds) {
      if (!hasLoggedEmptyMessage) {
        console.log("URL or TIME variable is empty,Skipping visit url");
        console.clear()
        hasLoggedEmptyMessage = true;
      }
      return;
    } else {
      hasLoggedEmptyMessage = false;
    }

    await axios.get(projectPageURL);
    // console.log(`Visiting project page: ${projectPageURL}`);
    console.log('Page visited successfully');
    console.clear()
  } catch (error) {
    console.error('Error visiting project page:', error.message);
  }
}
setInterval(visitProjectPage, intervalInMilliseconds);

visitProjectPage();

app.listen(port, () => console.log(`Example app listening on port ${port}!`));
