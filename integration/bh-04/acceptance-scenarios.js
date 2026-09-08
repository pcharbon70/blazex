import { AtomicDOMRoots } from "../../js/blazex_runtime/src/atomic-dom.js";
import { EffectDOMRoots } from "../../js/blazex_runtime/src/effect-dom.js";
import { seal } from "../../js/blazex_runtime/src/render-transaction-v2.js";
import { digest, encode } from "../../js/blazex_runtime/src/render-transaction-codec.js";
import { decodeIntent } from "../../js/blazex_runtime/src/render-intent-data.js";
const encodeIntent = value => btoa(String.fromCharCode(...encode(value)));
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
const bridge = () => ({ request: async (_op,p) => ({root_id:p.root_id,root_generation:p.root_generation}), metrics:()=>({}), stop(){} });
const txid = n => "tx-"+n.toString(16).padStart(24,"0");
const identity = tx => Object.fromEntries(["owner","root","generation","base_revision","target_revision","transaction_id","digest"].map(k=>[k,tx[k]]));
const assert = (ok, message) => { if(!ok) throw Error(message); };
const frame = () => new Promise(resolve=>requestAnimationFrame(()=>resolve(performance.now())));
export async function runAcceptanceScenarios(document, rows, effectFixture, policy, injectFailure = false) {
  const keyed=[], queues=[], stale=[], errors=[]; let serial=0;
  async function setup(row, options={}) {
    const container=document.createElement("div"); document.body.append(container);
    const roots=new AtomicDOMRoots({scopeId:"acceptance-"+(++serial),createBridge:bridge,...options});
    const handle=await roots.register("root"); await handle.mount({targetId:"owned",tree:{}});
    const token=roots.attach(handle,{owner:row.transaction.owner,generation:1,container,fault:options.fault});
    if(row.setup) assert((await roots.submit(token,row.setup)).state==="committed","setup");
    return {roots,token,container,close:async()=>{await roots.lifecycle.shutdown();assert(roots.resources(token).disposed&&container.childNodes.length===0,"cleanup");container.remove();}};
  }
  try {
  const fixture=rows.find(r=>r.name===policy.keyed.scenario);
  for(let i=0;i<=policy.keyed.samples_per_browser;i++) {
    let active=false; const marks={};
    const a=await setup(fixture,{schedule:task=>queueMicrotask(()=>{if(active)marks.pump=performance.now();task();}),
      onAck:ack=>{if(active)marks[ack.state]=performance.now();},fault:stage=>{if(active&&stage==="before"&&marks.apply===undefined)marks.apply=performance.now();}});
    const old=[...a.container.firstChild.children];
    active=true; marks.receipt=performance.now();
    let ack=null, error=null;
    try {ack=await a.roots.submit(a.token,fixture.transaction);} catch(e){error=String(e);}
    marks.frame1=await frame();marks.frame2=await frame();
    const correct=ack?.state==="committed"&&a.roots.snapshot(a.token).fingerprint===fixture.after.fingerprint&&[...a.container.firstChild.children].every(el=>old.includes(el));
    const trace={sample:i,warmup:i===0,scenario:fixture.name,...identity(fixture.transaction),marks,ack,error,correct,receipt_to_frame_ms:marks.frame2-marks.receipt};
    keyed.push(trace);if(!correct)errors.push("keyed-"+i);await a.close();
    if(injectFailure&&i===1)throw Error("injected partial-result retention probe");
  }
  for(let run=0;run<policy.queue.runs_per_browser;run++) {
    const tasks=[],a=await setup(rows[0],{schedule:task=>tasks.push(task)}),pending=[],offered=[];
    for(let i=0;i<policy.queue.offered_per_run;i++) {
      const tx=await seal({...rows[0].transaction,transaction_id:txid(10000+run*100+i)}),receipt=performance.now();
      pending.push(a.roots.submit(a.token,tx).then(ack=>({...identity(tx),receipt,terminal:performance.now(),ack})));
      offered.push(a.roots.snapshot(a.token).queued);
    }
    const h=await a.roots.register("sibling");await h.mount({targetId:"sibling",tree:{}});
    const c=document.createElement("div");document.body.append(c);
    const t=a.roots.attach(h,{container:c,owner:rows[0].transaction.owner,generation:1});
    const p=a.roots.submit(t,rows[0].transaction);tasks.pop()();const sibling=await p;
    while(tasks.length){tasks.shift()();await pause(0);}
    const outcomes=await Promise.all(pending),snapshot=a.roots.snapshot(a.token);
    const correct=snapshot.max_depth===64&&sibling.state==="committed"&&outcomes.filter(o=>o.ack.state==="committed").length===1&&outcomes.filter(o=>o.ack.diagnostic==="limit").length===1&&outcomes.filter(o=>o.ack.diagnostic==="stale").length===63;
    queues.push({run,scenario:"producer-over-renderer",offered,coalesced:0,backpressure:"reject-limit",outcomes,snapshot,sibling,correct});
    if(!correct)errors.push("queue-"+run);await a.close();c.remove();
  }
  let seed=policy.stale.seed;
  const next=()=>seed=(seed*1664525+1013904223)>>>0;
  const replaced=rows.find(r=>r.name==="generation-replace"),a=await setup(replaced);
  assert((await a.roots.submit(a.token,replaced.transaction)).state==="committed","replacement");
  const before=a.container.innerHTML, state=a.roots.snapshot(a.token);
  for(let i=0;i<policy.stale.renderer_per_browser;i++) {
    const random=next(),delay=random%3,tx=await seal({...rows[1].transaction,transaction_id:txid(20000+i),generation:1+random%(state.generation-1)});
    await pause(delay);const start=performance.now();const ack=await a.roots.submit(a.token,tx),after=a.roots.snapshot(a.token);
    const correct=ack.state==="rejected"&&ack.diagnostic==="stale"&&a.container.innerHTML===before&&after.fingerprint===state.fingerprint&&after.revision===state.revision;
    stale.push({path:"renderer",sample:i,seed:random,delay_ms:delay,...identity(tx),elapsed_ms:performance.now()-start,ack,correct});if(!correct)errors.push("stale-renderer-"+i);
  }
  await a.close();
  // A fresh generation-3 root receives validly sealed generation-1/2 envelopes.
  // Each includes an executable timer, so accepting one would mutate DOM/effects.
  const roots=new EffectDOMRoots({scopeId:"stale-effects",createBridge:bridge});
  const handle=await roots.register("effects");await handle.mount({targetId:"effects",tree:{}});
  const container=document.createElement("div");document.body.append(container);
  const token=roots.attach(handle,{container,owner:effectFixture.continuity.transaction.owner,generation:3,grants:["time"]});
  async function envelope(generation,n,effects) {
    const operations=effectFixture.continuity.transaction.operations.map(op=>{
      if(op.type!=="intent"||op.name!=="listeners"||op.new===null)return op;
      return {...op,new:encodeIntent(decodeIntent(op.new).map(l=>({...l,owner:{...l.owner,generation},source:{...l.source,generation}})))};
    });
    const transaction=await seal({...effectFixture.continuity.transaction,operations,generation,transaction_id:txid(n)});
    const {digest:_,...c}=effectFixture.continuity;const body={...c,transaction};
    const continuity={...body,digest:await digest(body)};
    const payload={protocol:"blazex.dom-effects/1",continuity,effects};return {...payload,digest:await digest(payload)};
  }
  const mount=await roots.submit(token,await envelope(3,30000,[]));
  assert(mount.state==="committed","effect mount: "+JSON.stringify(mount));
  const html=container.innerHTML,baseline=roots.snapshot(token);
  for(let i=0;i<policy.stale.effects_per_browser;i++) {
    const random=next(),generation=1+random%2,delay=random%3,id="delayed-"+i;
    const effects=[{id,owner:effectFixture.continuity.transaction.root,generation,revision:1,capability:"time",operation:"schedule",payload:{delay_ms:0},timeout_ms:50,fallback:"fail",barrier:"post-commit",depends:[]}];
    const raw=await envelope(generation,31000+i,effects);await pause(delay);const start=performance.now();let diagnostic=null;
    try{await roots.submit(token,raw);}catch(e){diagnostic=e.code??String(e);}
    const snapshot=roots.snapshot(token),correct=diagnostic==="stale"&&container.innerHTML===html&&snapshot.fingerprint===baseline.fingerprint&&snapshot.revision===baseline.revision&&snapshot.resources.active===baseline.resources.active&&snapshot.results.length===0;
    stale.push({path:"effects",sample:i,seed:random,delay_ms:delay,...identity(raw.continuity.transaction),effect_id:id,envelope_digest:raw.digest,elapsed_ms:performance.now()-start,diagnostic,correct});if(!correct)errors.push("stale-effect-"+i);
  }
  roots.dispose(token);await pause(policy.failure.observation_ms);const cleanup=roots.snapshot(token);
  if(cleanup.resources.active!==0||cleanup.inventory.nodes!==0||cleanup.queued!==0)errors.push("effect-cleanup");
  await roots.lifecycle.shutdown();container.remove();
  return {keyed,queues,stale,cleanup,errors,result:errors.length?"failed":"passed",support_state:"unsupported"};
  } catch(error) {
    errors.push(String(error));
    // Retain every completed observation; the driver closes the entire browser
    // context to release any root whose setup or teardown threw.
    return {keyed,queues,stale,cleanup:null,errors,result:"failed",support_state:"unsupported"};
  }
}
