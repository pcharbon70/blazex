import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import {createHash} from "node:crypto";
import {fileURLToPath} from "node:url";
import {chromium,firefox} from "../../../js/blazex_runtime/node_modules/playwright-core/index.mjs";

const root=fileURLToPath(new URL("../../../",import.meta.url));
const output=process.argv[2],bundle=process.argv[3];
if(!output||!bundle)throw Error("usage: run-browser.mjs OUTPUT BUNDLE");
const files={"/AtomVM.mjs":path.join(root,"packages/blazex_runtime_popcorn/runtime/generated/release-web/artifacts/AtomVM.mjs"),"/AtomVM.wasm":path.join(root,"packages/blazex_runtime_popcorn/runtime/generated/release-web/artifacts/AtomVM.wasm"),"/bundle.avm":path.resolve(bundle)};
const server=http.createServer((request,response)=>{response.setHeader("Cross-Origin-Opener-Policy","same-origin");response.setHeader("Cross-Origin-Embedder-Policy","require-corp");if(request.url==="/"){response.setHeader("content-type","text/html");response.end("<!doctype html><title>BH05 AtomVM conformance</title><div id=target></div>");return;}const file=files[request.url];if(!file){response.writeHead(404).end();return;}response.setHeader("content-type",request.url.endsWith(".wasm")?"application/wasm":request.url.endsWith(".avm")?"application/octet-stream":"text/javascript");response.end(fs.readFileSync(file));});
await new Promise(resolve=>server.listen(0,"127.0.0.1",resolve));
const record={schema_version:"1.0.0",phase:11,support_state:"unsupported",runtime:{atomvm_wasm_sha256:createHash("sha256").update(fs.readFileSync(files["/AtomVM.wasm"])).digest("hex"),bundle_sha256:createHash("sha256").update(fs.readFileSync(bundle)).digest("hex")},results:[]};
try{
 for(const [name,launcher,executablePath] of [["chrome",chromium,"/usr/bin/google-chrome"],["firefox",firefox,"/home/ducky/.cache/ms-playwright/firefox-1538/firefox/firefox"]]){
  const browser=await launcher.launch({executablePath,headless:true,...(name==="chrome"?{args:["--no-sandbox","--disable-dev-shm-usage"]}:{})});
  try{
   const page=await browser.newPage(),errors=[];page.on("pageerror",e=>errors.push(String(e)));await page.goto(`http://127.0.0.1:${server.address().port}/`);
   const result=await page.evaluate(async()=>{const logs=[];let abortReason=null;try{
    const createRuntime=(await import("/AtomVM.mjs")).default,wasmBinary=new Uint8Array(await(await fetch("/AtomVM.wasm")).arrayBuffer()),applicationBundle=new Uint8Array(await(await fetch("/bundle.avm")).arrayBuffer());
    const memory=new WebAssembly.Memory({initial:256,maximum:256,shared:true});let readyResolve;const ready=new Promise(r=>readyResolve=r);
    const options={arguments:["/bundle.avm"],locateFile:p=>new URL(p,location.href).href,mainScriptUrlOrBlob:"/AtomVM.mjs",wasmBinary,wasmMemory:memory,preRun:[m=>m.FS.writeFile("/bundle.avm",applicationBundle)],print:v=>logs.push(String(v)),printErr:v=>logs.push(String(v)),onAbort:r=>{abortReason=String(r)},onRuntimeInitialized:()=>{options.serialize=JSON.stringify;options.deserialize=raw=>JSON.parse(raw,(k,v)=>v&&typeof v==="object"&&Object.hasOwn(v,"popcorn_ref")&&Object.keys(v).length===1?options.trackedObjectsMap.get(v.popcorn_ref):v);options.cleanupFunctions=new Map();options.onTrackedObjectDelete=k=>options.trackedObjectsMap.delete(k);options.onRunTrackedJs=source=>{const indirectEval=eval,fn=indirectEval(source),result=fn(options);return (result??[]).map(value=>{const key=options.nextTrackedObjectKey();options.trackedObjectsMap.set(key,value);return key;});};options.onGetTrackedObjects=keys=>keys.map(k=>options.serialize(options.trackedObjectsMap.get(k)));options.sendEvent=name=>{if(name==="popcorn_app_ready")readyResolve();};}};
    const runtime=await createRuntime(options),originalCall=runtime.call;runtime.call=(process,value)=>originalCall(process,runtime.serialize(value));
    await Promise.race([ready,new Promise((_,reject)=>setTimeout(()=>reject(Error("application-ready-timeout")),5000))]);const raw=await Promise.race([runtime.call("main",{operation:"run"}),new Promise((_,reject)=>setTimeout(()=>reject(Error("scenario-timeout")),10000))]);const response=runtime.deserialize(raw);
    document.getElementById("target").textContent=response.final_state.root===1?"Conformance: 1":"failed";
    return {response,dom:{text:document.getElementById("target").textContent,role:"status"},memory_pages:memory.buffer.byteLength/65536,logs};
    }catch(error){return {error:String(error),abortReason,logs};}
   });
   record.results.push({browser:name,version:browser.version(),executable:executablePath,result:result.response?.result??"failed",trace:result.response?.trace??null,final_state:result.response?.final_state??null,dom:result.dom??null,memory_pages:result.memory_pages??null,page_errors:errors,runtime_error:result.error??null,abort_reason:result.abortReason??null,runtime_logs:result.logs??[]});
  }finally{await browser.close();}
 }
}catch(error){record.fatal_error=String(error?.stack??error);process.exitCode=1;}finally{server.close();fs.writeFileSync(output,JSON.stringify(record,null,2)+"\n");}
if(record.results.length===2){const canonical=row=>JSON.stringify({trace:row.trace,final_state:row.final_state,dom:row.dom});const exact=record.results.every(r=>r.result==="passed")&&canonical(record.results[0])===canonical(record.results[1]);record.comparison={state:exact?"exact-match":"fail",sha256:createHash("sha256").update(canonical(record.results[0])).digest("hex")};fs.writeFileSync(output,JSON.stringify(record,null,2)+"\n");if(!exact)process.exitCode=1;}
