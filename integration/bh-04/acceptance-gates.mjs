// Evidence recorder: every command exit and output is retained, including failures.
import fs from "node:fs";
import path from "node:path";
import {spawnSync,execFileSync} from "node:child_process";
import {createHash} from "node:crypto";
const prefix="docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-";
const directory=process.cwd(),results=[];
const run=(name,command,args,cwd=directory)=>{
  const start=Date.now(),r=spawnSync(command,args,{cwd,encoding:"utf8",timeout:600000,maxBuffer:30_000_000});
  results.push({name,command:[command,...args],cwd:cwd===directory?".":path.relative(directory,cwd),exit_code:r.status,signal:r.signal,error:r.error?String(r.error):null,elapsed_ms:Date.now()-start,stdout:r.stdout,stderr:r.stderr});
  fs.writeFileSync(prefix+"gate-log-v0.1.0.json",JSON.stringify({schema_version:"1.0.0",phase:10,results},null,2)+"\n");
  console.log(name,r.status);return r.status===0;
};
const mix="set -e; cd /workspace; mix format --check-formatted integration/bh-04/support/*.exs; for package in blazex_core blazex_effects blazex_ui_tree blazex_renderer blazex_renderer_headless blazex_renderer_dom; do cd /workspace/packages/$package; mix test; done; cd /workspace/integration/conformance; mix test; mix run ../bh-04/support/conformance_runner.exs";
run("elixir","docker",["run","--rm","--network","none","-v",directory+":/workspace","-e","MIX_BUILD_PATH=/tmp/bh10-final","a2386c21edd5","sh","-c",mix]);
run("javascript","bash",["-c","node --test js/blazex_runtime/test/*.test.js && node packages/blazex_renderer_dom/js/test/dom-driver.test.js && node integration/bh-04/conformance-test.mjs && node integration/bh-04/acceptance-report.test.mjs"]);
for(const [name,script]of [["atomic","atomic-dom"],["interaction","interaction"],["continuity","continuity"],["effect","effect"],["semantic","conformance"]]){
  const output=prefix+name+"-browser-v0.1.0.json";
  run(name+"-browser","node",["integration/bh-04/"+script+"-browser.mjs",output]);
  if(["interaction","continuity","effect"].includes(name))run(name+"-replay","node",["integration/bh-04/"+name+"-conformance.mjs",output]);
}
run("isolation","node",["integration/bh-04/conformance-isolation.mjs",prefix+"isolation-v0.1.0.json"]);
run("research-tests","python3",["-m","unittest","discover","-p","test_*.py"],path.join(directory,"docs/research"));
for(const script of fs.readdirSync("docs/research").filter(p=>/^validate_.*\.py$/.test(p)&&p!=="validate_bh04_acceptance.py").sort())run(script,"python3",[script],path.join(directory,"docs/research"));
for(const script of fs.readdirSync("docs/research").filter(p=>/^generate_.*\.py$/.test(p)).sort())run(script,"python3",[script,"--check"],path.join(directory,"docs/research"));
run("patch-hygiene","git",["diff","--check"]);
const files=execFileSync("git",["ls-files","--cached","--others","--exclude-standard"],{encoding:"utf8"}).trim().split("\n");
const json=files.filter(p=>p.endsWith(".json"));for(const file of json)JSON.parse(fs.readFileSync(file));
const source_hashes=Object.fromEntries(files.filter(p=>/^(packages|js|integration)\//.test(p)&&!p.includes("node_modules")&&fs.statSync(p).isFile()).sort().map(p=>[p,createHash("sha256").update(fs.readFileSync(p)).digest("hex")]));
fs.writeFileSync(prefix+"execution-index-v0.1.0.json",JSON.stringify({schema_version:"1.0.0",phase:10,json_files:json.length,source_hashes,clean_build:"new offline Docker build path; same host and reviewer, not independent human review",result:results.every(r=>r.exit_code===0)?"passed":"failed"},null,2)+"\n");
if(results.some(r=>r.exit_code!==0))process.exitCode=1;
