"""Run Phase 11 gates against one source closure and publish only passes."""
import argparse,json,os,platform,subprocess,sys,time
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh05_conformance import AREA,GATES,completion,gate_errors,sources,validate

def run(args):
    log=args.output/"execution.json"
    if log.exists() or not args.output.is_dir() or args.output.resolve().is_relative_to(REPO_ROOT): raise ValueError("fresh external output required")
    record={"schema_version":"1.0.0","phase":11,"environment":{"python":platform.python_version(),"node":subprocess.check_output(["node","--version"],text=True).strip(),"elixir_image":"a2386c21edd5","elixir":"1.17.3","otp":"26.0.2","active":["ERTS/headless","Linux Chrome AtomVM/DOM","Linux Firefox development AtomVM/DOM","GTK portability"]},"source_hashes":sources(),"results":[]}
    def execute(name,command,cwd=REPO_ROOT):
        start=time.monotonic()
        try:
            result=subprocess.run(command,cwd=cwd,capture_output=True,text=True,timeout=900);row={"name":name,"command":command,"cwd":str(cwd),"exit_code":result.returncode,"stdout":result.stdout,"stderr":result.stderr,"error":None}
        except (OSError,subprocess.TimeoutExpired) as error: row={"name":name,"command":command,"cwd":str(cwd),"exit_code":None,"stdout":"","stderr":"","error":str(error)}
        row["elapsed_seconds"]=round(time.monotonic()-start,3);record["results"].append(row);log.write_text(json.dumps(record,indent=2)+"\n");print(name+(": PASS" if row["exit_code"]==0 else ": FAIL"),flush=True)
    docker=["docker","run","--rm","--network","none","--user",f"{os.getuid()}:{os.getgid()}","-v",str(REPO_ROOT)+":/workspace:ro","-v",str(args.output)+":/output","-e","MIX_BUILD_PATH=/tmp/bh05-phase11","a2386c21edd5"]
    execute("packages",docker+["sh","-c","set -e; for p in blazex_core blazex_effects blazex_ui_tree blazex_renderer blazex_renderer_headless blazex_renderer_dom blazex_test; do cd /workspace/packages/$p; mix format --check-formatted; mix test; done; cd /workspace/integration/conformance; mix format --check-formatted; mix test"])
    execute("browser-project",docker+["sh","-c","cd /workspace/integration/bh-05/browser_conformance; MIX_ENV=prod MIX_BUILD_PATH=/tmp/bh05-browser mix format --check-formatted; MIX_ENV=prod MIX_BUILD_PATH=/tmp/bh05-browser mix bh05.browser_package --out-dir /output/bundle"])
    execute("javascript",["bash","-c","node --test js/blazex_runtime/test/*.test.js && node packages/blazex_renderer_dom/js/test/dom-driver.test.js"])
    execute("local-repeat",[sys.executable,"docs/research/70-tools/run_bh05_local_conformance.py","--output","integration/bh-05/local-conformance-v0.1.0.json","--check"])
    execute("browser-repeat",["bash","-c",f"node integration/bh-05/browser_conformance/run-browser.mjs {args.output}/browser.json {args.output}/bundle/bundle.avm && diff -u integration/bh-05/browser-conformance-v0.1.0.json {args.output}/browser.json"])
    execute("phase10-replay",["bash","-c","python3 docs/research/70-tools/validate_bh05_recovery.py --final && python3 docs/research/70-tools/generate_bh05_recovery.py --check"],args.phase10)
    execute("historical-sweep",[sys.executable,"docs/research/70-tools/check_all.py","--report",str(args.output/"historical.json")],args.historical)
    execute("validator-tests",[sys.executable,"-m","unittest","discover","-s","docs/research/70-tools","-p","test_validate_bh05_conformance.py"])
    execute("authority",[sys.executable,"docs/research/70-tools/generate_bh05_conformance.py","--check"])
    execute("corpus",[sys.executable,"docs/research/70-tools/generate_bh05_conformance_corpus.py","--check"])
    execute("browser-validator",[sys.executable,"docs/research/70-tools/validate_bh05_browser_conformance.py"])
    execute("archive",[sys.executable,"docs/research/70-tools/validate_archive.py"])
    execute("json",[sys.executable,"-c","import json,pathlib,subprocess; p=[x for x in subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard'],text=True).splitlines() if x.endswith('.json')];[json.loads(pathlib.Path(x).read_text()) for x in p];print(len(p),'JSON files valid')"])
    execute("hygiene",["git","diff","--check","HEAD"])
    record["final_source_hashes"]=sources();log.write_text(json.dumps(record,indent=2)+"\n");return not gate_errors(record,sources())
def publish(output):
    value=json.loads((output/"execution.json").read_text())
    if validate() or gate_errors(value,sources()): raise ValueError("cannot publish")
    for name,data in [("conformance-gates-v0.1.0.json",value),("conformance-completion-v0.1.0.json",None)]:
        with (REPO_ROOT/AREA/name).open("x") as stream: stream.write(json.dumps(completion() if data is None else data,indent=2)+"\n")
    print("Phase 11 conformance complete; Phase 12 eligible, unauthorized.")
if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("--output",type=Path,required=True);parser.add_argument("--phase10",type=Path);parser.add_argument("--historical",type=Path);parser.add_argument("--publish",action="store_true");args=parser.parse_args()
    if args.publish: publish(args.output)
    elif not args.phase10 or not args.historical: parser.error("replay paths required")
    elif not run(args): raise SystemExit(1)
