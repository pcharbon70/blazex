import { AtomicDOMRoots } from "../../js/blazex_runtime/src/atomic-dom.js";
import { FormContinuity } from "../../js/blazex_runtime/src/form-continuity.js";
import { InteractionListeners } from "../../js/blazex_runtime/src/interaction-listeners.js";
import { EVENT_MAPPINGS } from "../../js/blazex_runtime/src/interaction-record.js";
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
const check = (ok, message) => { if (!ok) throw Error(message); };
const bridge = () => ({ request: async (_op, p) => ({ root_id: p.root_id, root_generation: p.root_generation }), metrics: () => ({}), stop() {} });

export async function presentationSamples(fixture, injectCleanupFailure = false) {
  const samples = [];
  for (let sample = 0; sample <= 100; sample++) {
    const prefix = `bh04-${injectCleanupFailure ? "retention-probe" : "presentation"}-${sample}-`, marks = {};
    let active = false;
    const mark = name => { marks[name] = performance.now(); performance.mark(prefix + name); };
    const container = document.createElement("div"); document.body.append(container);
    const roots = new AtomicDOMRoots({ scopeId: "presentation-" + sample, createBridge: bridge,
      schedule: task => queueMicrotask(() => { if (active) mark("pump"); task(); }),
      onAck: ack => { if (active) mark(ack.state); } });
    let ack = null, error = null, token = null;
    const paints = [], afterPaint = event => { if (active) paints.push({ time: performance.now(), trusted: event.isTrusted }); };
    addEventListener("MozAfterPaint", afterPaint);
    try {
      const handle = await roots.register("root"); await handle.mount({ targetId: "owned", tree: {} });
      token = roots.attach(handle, { owner: fixture.transaction.owner, generation: 1, container,
        fault: stage => { if (active && stage === "before" && marks.apply === undefined) mark("apply"); } });
      check((await roots.submit(token, fixture.setup)).state === "committed", "setup failed");
      await pause(100);
      const old = [...container.firstChild.children];
      active = true; mark("receipt");
      ack = await roots.submit(token, fixture.transaction);
      await pause(125); mark("observation-end"); active = false;
      check(ack.state === "committed", "transaction rejected");
      check(roots.snapshot(token).fingerprint === fixture.after.fingerprint, "projection mismatch");
      check([...container.firstChild.children].every(el => old.includes(el)), "lost keyed node identity");
    } catch (e) { error = String(e); active = false; }
    finally {
      removeEventListener("MozAfterPaint", afterPaint);
      try {
        await roots.lifecycle.shutdown();
        check(container.childNodes.length === 0 && (!token || roots.resources(token).disposed), "cleanup failed");
        if (injectCleanupFailure && sample === 1) throw Error("injected late cleanup failure");
      } catch (e) { error = [error, String(e)].filter(Boolean).join("; "); }
      container.remove();
    }
    samples.push({ sample, warmup: sample === 0, marks, ack, error, paints });
    if (error) break;
  }
  return samples;
}

// Real browser elements and listener dispatch exercise the independent review's
// regression, separately from timed compositor windows.
export function controlledDraftRegression() {
  const cases = [], source = "bx-" + "a".repeat(24), owner = "root-owner";
  for (const kind of ["text", "check"]) for (const semantic of ["activate", "move", "reorder"]) {
    const element = document.createElement("input"); document.body.append(element);
    const continuity = new FormContinuity(), nodes = new Map([[source, element]]), received = [];
    const control = { owner: source, kind, value: kind === "text" ? "initial" : true, choices: [], edit_sequence: 0, disabled: false, readonly: false, required: false, invalid: false, indeterminate: false };
    continuity.apply({ controls: [control] }, nodes);
    const listeners = new InteractionListeners({ rootId: "root", lifecycleGeneration: 1, owner,
      receiver: { enqueue: r => { received.push(r); return Promise.resolve({ outcome: "accepted" }); }, setContext() {}, dispose() {} } });
    listeners.setContinuity(continuity); listeners.claim({ state: "ready", root_id: "root", root_generation: 1 }, owner);
    const binding = listeners.register(source, element, { semantic, native: EVENT_MAPPINGS[semantic], source: { generation: 1 } });
    element.addEventListener(EVENT_MAPPINGS[semantic], binding.handler);
    listeners.publish({ owner, generation: 1, target_revision: 1, transaction_id: "tx-" + "b".repeat(24), digest: "c".repeat(64) });
    const dispatch = () => element.dispatchEvent(new MouseEvent(EVENT_MAPPINGS[semantic], { bubbles: true, cancelable: true }));
    dispatch(); continuity.apply({ controls: [control] }, nodes);
    check((kind === "text" ? element.value : element.checked) === control.value, "non-edit corrupted control");
    continuity.admitted(source, { value: "draft", checked: false }, 2);
    dispatch(); continuity.apply({ controls: [control] }, nodes);
    check((kind === "text" ? element.value : element.checked) === (kind === "text" ? "draft" : false), "non-edit corrupted pending draft");
    continuity.apply({ controls: [{ ...control, edit_sequence: 2 }] }, nodes);
    check((kind === "text" ? element.value : element.checked) === control.value && received.length === 2, "edit acknowledgement fence");
    element.removeEventListener(EVENT_MAPPINGS[semantic], binding.handler); listeners.dispose(); continuity.dispose(); element.remove();
    cases.push({ kind, semantic, result: "passed" });
  }
  return cases;
}
