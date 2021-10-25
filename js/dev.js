const { spawn } = require("child_process");

const child = spawn("./node_modules/.bin/vite", { stdio: "inherit" });

process.stdin.on("end", function () {
  console.log("stdin close");
  child.kill();
  process.exit();
});

process.stdin.resume();
