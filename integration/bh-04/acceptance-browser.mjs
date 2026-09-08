import fs from "node:fs";
import os from "node:os";
import http from "node:http";
import path from "node:path";
import assert from "node:assert/strict";
import {createHash} from "node:crypto";
import {fileURLToPath} from "node:url";
import {chromium,firefox} from "../../js/blazex_runtime/node_modules/playwright-core/index.mjs";
import {decode} from "../../js/blazex_runtime/src/render-transaction-v2.js";
const root=fileURLToPath(new URL("../../",import.meta.url));
const prefix="docs/research/assets/bh-04-baseline/blazex-bh-04-phase-";
const authPath=prefix+"10-authorization-v0.1.0.json", fixturePath="integration/bh-04/atomic-dom-fixtures-v0.1.0.txt",effectPath=prefix+"09-effect-browser-v0.1.0.json";
const read=p=>fs.readFileSync(path.join(root,p));const sha=b=>createHash("sha256").update(b).digest("hex");
const auth=JSON.parse(read(authPath)), rows=read(fixturePath).toString().trim().split("\n").map(l=>decode(Buffer.from(l.split("|")[1],"base64")));
const effect=JSON.parse(read(effectPath)).results[0].runtime[0].response.transaction;
const server=http.createServer((request,response)=>{
  const pathname=new URL(request.url,"http://localhost").pathname;
  if(pathname==="/"){response.setHeader("content-type","text/html");response.end("<!doctype html><html lang=en><title>BH-04 acceptance</title><body></body></html>");return;}
  const file=path.resolve(root,"."+pathname);
  if(!["integration/bh-04/","js/blazex_runtime/src/"].some(p=>file.startsWith(path.join(root,p)))||!file.endsWith(".js")){response.writeHead(404).end();return;}
  try{response.setHeader("content-type","text/javascript");response.end(fs.readFileSync(file));}catch{response.writeHead(404).end();}
});
await new Promise(r=>server.listen(0,"127.0.0.1",r));
const output={schema_version:"1.0.0",phase:10,recorded_at:new Date().toISOString(),platform:process.platform,node:process.version,
  environment:{kernel:os.release(),arch:os.arch(),cpus:os.cpus().map(c=>c.model),memory_bytes:os.totalmem(),load_at_start:os.loadavg(),headless:true,network:"localhost",qualification:"active Linux development; not governed BH-22 hardware"},
  source_hashes:Object.fromEntries([authPath,fixturePath,effectPath,"integration/bh-04/acceptance-scenarios.js","integration/bh-04/acceptance-browser.mjs"].map(p=>[p,sha(read(p))])),results:[]};
const target=process.argv[2];if(!target)throw Error("Output path required");
try{
  for(const [name,launcher,executablePath]of [["chrome",chromium,"/usr/bin/google-chrome"],["firefox",firefox,"/home/ducky/.cache/ms-playwright/firefox-1538/firefox/firefox"]]){
    const browser=await launcher.launch({executablePath,headless:true,...(name==="chrome"?{args:["--no-sandbox","--disable-dev-shm-usage"]}:{})});
    try{const page=await browser.newPage(),errors=[];page.on("pageerror",e=>errors.push(String(e)));await page.goto(`http://127.0.0.1:${server.address().port}/`);
      const result=await page.evaluate(async({rows,effect,policy})=>{const {runAcceptanceScenarios}=await import("/integration/bh-04/acceptance-scenarios.js");return runAcceptanceScenarios(document,rows,effect,policy);},{rows,effect,policy:auth.metrics});
      const probe=await page.evaluate(async({rows,effect,policy})=>{const {runAcceptanceScenarios}=await import("/integration/bh-04/acceptance-scenarios.js");return runAcceptanceScenarios(document,rows,effect,policy,true);},{rows,effect,policy:auth.metrics});
      assert.equal(probe.result,"failed");assert.equal(probe.keyed.length,2);assert.match(probe.errors[0],/injected partial-result/);
      for(const row of [...result.keyed,...result.queues,...result.stale])row.trace_sha256=sha(JSON.stringify(row));
      output.results.push({browser:name,version:browser.version(),executable:executablePath,page_errors:errors,partial_retention_probe:probe,...result});console.log(name,result.result,result.errors);
      if(result.result!=="passed")process.exitCode=1;
    }finally{await browser.close();}
  }
}catch(error){output.fatal_error=String(error);process.exitCode=1;}
finally{server.close();fs.writeFileSync(target,JSON.stringify(output,null,2)+"\n");}
