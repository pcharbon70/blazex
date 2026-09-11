import { filterCatalog } from "./catalog.js";

const catalog = document.getElementById("catalog");
const count = document.getElementById("catalog-count");
const emptyState = document.getElementById("empty-state");
const search = document.getElementById("catalog-search");
const template = document.getElementById("demo-card-template");
let controllers = [];
let renderSequence = 0;

function eventView(event) {
  return JSON.stringify({
    name: event.name,
    generation: event.generation,
    revision: event.revision,
    sequence: event.sequence,
    payload: event.payload,
  }, null, 2);
}

async function render(query = "") {
  const sequence = ++renderSequence;
  controllers.forEach((controller) => controller.dispose());
  controllers = [];
  catalog.replaceChildren();
  const controls = filterCatalog(query);
  count.value = `${controls.length} ${controls.length === 1 ? "control" : "controls"}`;
  emptyState.hidden = controls.length !== 0;

  for (const control of controls) {
    const card = template.content.firstElementChild.cloneNode(true);
    card.id = `demo-${control.id}`;
    card.querySelector(".demo-category").textContent = control.category;
    card.querySelector(".demo-title").textContent = control.title;
    card.querySelector(".demo-description").textContent = control.description;
    card.querySelector(".demo-status").textContent = control.status;
    card.querySelector(".demo-footer").textContent = `${control.phase} · Full-root experimental DOM projection`;
    const output = card.querySelector(".event-output");
    const target = card.querySelector(".demo-target");
    catalog.append(card);
    try {
      const controller = await control.mount({ target, onEvent: (event) => { output.textContent = eventView(event); } });
      if (sequence === renderSequence) controllers.push(controller);
      else controller.dispose();
    } catch (error) {
      output.textContent = `Demo failed to mount: ${error.message}`;
    }
  }
}

search.addEventListener("input", () => { void render(search.value); });
void render();
