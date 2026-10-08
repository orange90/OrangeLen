import { createServer } from "node:http";
const port = Number(process.env.PORT || 3000);
createServer((_request, response) => {
  response.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" });
  response.end("OrangeLen Docker 示例 🍊\n");
}).listen(port, "0.0.0.0");
