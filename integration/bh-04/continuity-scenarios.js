import { AtomicDOMRoots } from "../../js/blazex_runtime/src/atomic-dom.js";
import { InteractionListeners } from "../../js/blazex_runtime/src/interaction-listeners.js";
import { InteractionBridge, InteractionStream } from "../../js/blazex_runtime/src/interaction-stream.js";
import { digest } from "../../js/blazex_runtime/src/render-transaction-codec.js";
const check = (value, message) => { if (!value) throw new Error(message); };
const tick = () => new Promise(resolve => setTimeout(resolve, 0));
async function until(fn) { for (let n=0;n<5000;n++) { if (fn()) return; await tick(); } throw new Error("continuity deadline"); }
export async function runContinuityScenarios(document, runtime, trusted) {
  const traces = [], roots = new AtomicDOMRoots({ scopeId: "continuity", createBridge: () => ({ request: async (_op,p) => ({ root_id:p.root_id, root_generation:p.root_generation }), metrics:()=>({}), stop(){} }) });
  async function setup(rootId) {
    const handle = await roots.register(rootId); await handle.mount({ targetId: rootId, tree: {} });
    const init = await runtime({ control:"init",root_id:rootId,lifecycle_generation:handle.snapshot().root_generation });
    const container = document.createElement("div"), wrapper=document.createElement("div");wrapper.append(container);document.body.append(wrapper);
    let envelope = init.transaction, release = null, hold = false, fault = false;
    const outcomes = [], requests = [];
    const bridge = new InteractionBridge({ protocol:"blazex.host-bridge/3",rootId,transport:{ request:async request => {
      requests.push(request); const response = await runtime(request);
      if (response.result?.transaction) envelope = response.result.transaction;
      if (hold && request.operation === "root.interaction") { hold=false; await new Promise(resolve=>{release=resolve;}); }
      return response;
    },cancel(){} } });
    const stream = new InteractionStream({ bridge, rootHandle:handle });
    const listeners = new InteractionListeners({ rootId, lifecycleGeneration:handle.snapshot().root_generation, owner:envelope.transaction.owner, receiver:stream, onOutcome:o=>outcomes.push(o) });
    const token = roots.attach(handle,{container,owner:envelope.transaction.owner,generation:1,interactions:listeners,continuity:true,fault:stage=>{if(fault&&stage==="finalize"){fault=false;throw Error("injected");}}}); stream.bindDOM(roots,token);
    const ack=await roots.submit(token,envelope); check(ack.state==="committed","initial "+JSON.stringify(ack)); await runtime({control:"initial_ack",root_id:rootId,ack});
    const element=id=>[...container.querySelectorAll("[id]")].find(e=>e.id.endsWith(id));
    const form=kind=>envelope.controls.find(c=>c.kind===kind);
    async function update(props, expected="committed") {
      const response=await runtime({control:"update",root_id:rootId,props}); envelope=response.transaction;
      const ack=await roots.submit(token,envelope); check(ack.state===expected,"update "+JSON.stringify(ack));
      if(expected==="committed")await runtime({control:"update_ack",root_id:rootId,ack}); return ack;
    }
    return {handle,container,token,outcomes,requests,stream,listeners,element,form,update,get envelope(){return envelope;},hold(){hold=true;},release(){release();},get waiting(){return release!==null;},fail(){fault=true;}};
  }
  const a=await setup("continuity-a"), b=await setup("continuity-b");
  const field=a.element(a.form("text").owner); check(document.activeElement===field,"initial autofocus ownership");
  async function accepted(root, action) { const n=root.outcomes.length; await action(); await until(()=>root.outcomes.length>n); const result=root.outcomes[n]; check(result.outcome==="accepted",JSON.stringify(result)); return result; }
  const fire=(element,name="input",options={})=>element.dispatchEvent(new InputEvent(name,{bubbles:true,cancelable:false,...options}));
  field.focus(); field.setSelectionRange(0,field.value.length);
  await accepted(a,()=>trusted({text:"typed value"}));
  check(field.value==="typed value" && a.form("text").value==="typed value","typed round trip");
  traces.push({name:"typed",value:field.value,sequence:a.outcomes.at(-1).sequence});
  field.setSelectionRange(1,5,"backward"); const identity=field;
  await a.update({reverse:true}); check(a.element(a.form("text").owner)===identity && document.activeElement===field && field.selectionStart===1 && field.selectionEnd===5 && field.selectionDirection==="backward","keyed reorder/caret");
  traces.push({name:"keyed-move",identity:true,range:[field.selectionStart,field.selectionEnd,field.selectionDirection]});
  const valueDescriptor=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,"value");let writes=0;
  Object.defineProperty(field,"value",{configurable:true,get(){return valueDescriptor.get.call(this);},set(value){writes++;valueDescriptor.set.call(this,value);}});
  await a.update({reverse:true});check(writes===0,"redundant controlled value write");delete field.value;
  traces.push({name:"redundant-value",writes:0});
  await a.update({value:"xy",range:{anchor:50,focus:1,backward:true}}); check(field.value==="xy"&&field.selectionStart===1&&field.selectionEnd===2&&field.selectionDirection==="backward","clamp explicit range");
  traces.push({name:"explicit-range",range:[field.selectionStart,field.selectionEnd,field.selectionDirection]});
  await a.update({});
  // A newer user edit exists before the older event's renderer acknowledgement.
  a.hold(); field.value="first"; fire(field); await until(()=>a.waiting);
  field.value="newer draft"; fire(field); a.release(); await until(()=>a.stream.snapshot().queued===0);
  check(field.value==="newer draft","pending edit lost");
  traces.push({name:"pending-edit",value:field.value,outcomes:a.outcomes.slice(-2)});
  await accepted(a,()=>fire(field)); check(a.form("text").value==="newer draft","later genuine edit accepted");
  const before=a.requests.length;
  field.dispatchEvent(new CompositionEvent("compositionstart",{bubbles:true})); field.value="IME draft"; field.dispatchEvent(new CompositionEvent("compositionupdate",{bubbles:true,data:"ignored"})); fire(field,"input",{isComposing:true});
  await a.update({value:"conflicting semantic"}); check(field.value==="IME draft","composition overwritten");
  field.dispatchEvent(new CompositionEvent("compositionend",{bubbles:true})); check(a.requests.length===before,"composition fabricated input");
  await a.update({}); check(field.value==="IME draft","ended composition lost before genuine input");
  await accepted(a,()=>fire(field)); check(a.form("text").value==="IME draft","composition final input");
  traces.push({name:"composition",value:field.value,fabricated:0});
  field.dispatchEvent(new CompositionEvent("compositionstart",{bubbles:true}));field.blur();check(roots.continuitySnapshot(a.token).composing===0,"blur composition leak");
  field.focus();await accepted(a,()=>fire(field));
  const action=a.container.querySelector("button");
  await accepted(a,()=>{action.focus();return trusted({key:"Enter"});});
  await accepted(a,()=>action.dispatchEvent(new Event("submit",{bubbles:true,cancelable:true})));
  traces.push({name:"keyboard-submit",keyboard:true,submit:true});
  const checkbox=a.element(a.form("check").owner); await accepted(a,async()=>{const r=checkbox.getBoundingClientRect();await trusted({x:r.x+r.width/2,y:r.y+r.height/2});});
  check(checkbox.checked && a.form("check").value,"checkbox native round trip");
  await a.update({mixed:true,invalid:true}); check(checkbox.indeterminate&&field.required&&field.getAttribute("aria-invalid")==="true","mixed and validation");
  traces.push({name:"checkbox-validation",checked:checkbox.checked,mixed:checkbox.indeterminate,required:field.required,invalid:field.getAttribute("aria-invalid")});
  for(const kind of ["multiple","single"]){
    const choice=a.form(kind).choices.find(c=>c.value==="beta"), option=a.element(choice.owner);
    await accepted(a,()=>{option.checked=true;fire(option,"change");});
    check(kind==="multiple"?a.form(kind).value.includes("beta"):a.form(kind).value==="beta","selection round trip");
    await a.update({reverse:true}); check(a.element(choice.owner)===option&&option.checked,"selection identity reorder");
    traces.push({name:kind+"-selection",value:a.form(kind).value,identity:true});
  }
  const bfield=b.element(b.form("text").owner); bfield.focus(); await a.update({focus_action:true}); check(document.activeElement===bfield,"cross-root focus stolen");
  field.focus(); await a.update({focus_action:true}); check(document.activeElement===field,"unchanged autofocus replayed");
  await a.update({}); await a.update({focus_action:true}); check(document.activeElement.tagName==="BUTTON"&&a.container.contains(document.activeElement),"new explicit focus missing");
  await a.update({});field.focus();a.container.parentElement.hidden=true;await a.update({focus_action:true});check(document.activeElement!==action,"hidden target focused");a.container.parentElement.hidden=false;
  traces.push({name:"focus-authority",sibling_preserved:true,new_intent:true,hidden_skipped:true});
  field.focus(); await a.update({remove:true}); check(document.activeElement===checkbox,"focused removal fallback");
  await a.update({replace:true}); const replacement=a.element(a.form("text").owner); check(replacement!==field&&document.activeElement===replacement,"replacement focus");
  await a.update({replace:true,disabled:true}); check(document.activeElement!==replacement,"disabled focus target retained");
  traces.push({name:"remove-replace-disabled",fallback:true,replacement:true});
  await a.update({replace:true,readonly:true}); const count=a.requests.length; fire(replacement); check(a.requests.length===count,"readonly delivered");
  // A correctly hashed but unknown selected value rejects without mutation.
  const current=a.envelope, bad=structuredClone(current); bad.controls.find(c=>c.kind==="single").value="removed"; bad.control_digest=await digest(bad.controls); delete bad.digest; bad.digest=await digest(bad);
  const dom=a.container.innerHTML; let rejected=false; try{await roots.submit(a.token,bad);}catch{rejected=true;} check(rejected&&a.container.innerHTML===dom,"invalid selection mutation");
  rejected=false;try{await roots.submit(a.token,{...current,digest:"0".repeat(64)});}catch{rejected=true;}check(rejected&&a.container.innerHTML===dom,"digest mutation");
  const stale=await roots.submit(a.token,current);check(stale.state==="rejected"&&a.container.innerHTML===dom,"stale continuity mutation");
  traces.push({name:"negative-manifests",rejected:3,no_mutation:true});
  const negativeCount=a.requests.length;replacement.setAttribute("type","file");fire(replacement);replacement.setAttribute("type","text");
  check(a.requests.length===negativeCount,"file data transport");
  traces.push({name:"file-policy",delivered:0});
  const old=await runtime({control:"snapshot",root_id:"continuity-a"});
  a.fail(); await a.update({replace:true,value:"rollback"},"rolled-back"); check(replacement.value!=="rollback","rollback lost draft");
  const after=await runtime({control:"snapshot",root_id:"continuity-a"});check(after.count.value===old.count.value,"rollback promoted semantic state");
  traces.push({name:"rollback",state:"rolled-back",accepted_state_preserved:true});
  await accepted(b,()=>trusted({key:"Tab"}).then(()=>{bfield.focus();bfield.value="sibling";fire(bfield);}));
  const late=a.requests.length;await a.handle.dispose();fire(replacement);check(a.requests.length===late,"post-disposal input");await runtime({control:"stop",root_id:"continuity-a"});
  bfield.dispatchEvent(new CompositionEvent("compositionstart",{bubbles:true}));roots.lifecycle.runtimeLost();await runtime({control:"stop",root_id:"continuity-b"});await roots.lifecycle.shutdown();
  const cleanup=[roots.continuitySnapshot(a.token),roots.continuitySnapshot(b.token)];check(cleanup.every(c=>c.controls===0&&c.composing===0&&c.listeners===0&&c.disposed),"continuity cleanup");
  check(a.container.childNodes.length===0&&b.container.childNodes.length===0&&a.listeners.snapshot().listeners===0&&b.listeners.snapshot().listeners===0,"root cleanup");
  traces.push({name:"cleanup",roots:2,leaked:0});a.container.parentElement.remove();b.container.parentElement.remove();
  return {result:"passed",support_state:"unsupported",counters:{scenarios:traces.length,roots:2,cleanup:2},traces,cleanup};
}
