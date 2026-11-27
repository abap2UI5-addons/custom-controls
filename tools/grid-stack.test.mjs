// Tests for the pure parts of z2ui5_cci.cc.GridStack: reading the bound rows
// (readItems), writing the positions the grid reports back into them
// (mergeLayout) and the options handed to the library (toOptions).
//
// The control is a UI5 AMD module, loaded through the same shim as in
// network-status-clock.test.mjs.
//
// What this cannot cover: dragging and resizing, the collision rules and the
// click on a box - that is the library and a browser.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function amd(file) {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", file), "utf8");
  const stub = { extend: (name, definition) => ({ ...definition }) };
  let result;
  const sap = {
    ui: {
      define(names, factory) {
        result = factory(...names.map(() => stub));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", source)(sap);
  return result;
}

const { readItems, mergeLayout, toOptions } = amd("GridStack.js");

test("GridStack: a row is read from upper-case and lower-case keys alike", () => {
  const upper = readItems([{ ID: "A", X: 2, Y: 1, W: 3, H: 2, TEXT: "a", STATE: "Error" }]);
  const lower = readItems([{ id: "A", x: "2", y: "1", w: "3", h: "2", text: "a", state: "error" }]);
  const pick = ({ items }) => items.map(({ keys, ...rest }) => rest);
  assert.deepEqual(pick(upper), pick(lower));
  assert.deepEqual(pick(upper)[0], {
    id: "A",
    x: 2,
    y: 1,
    w: 3,
    h: 2,
    text: "a",
    info: "",
    state: "Error",
    color: "",
    selected: false,
    locked: false,
  });
});

test("GridStack: fields a filtered binding left out get their defaults", () => {
  // omit_initial drops x = 0, y = 0 and abap_false
  const { items } = readItems([{ ID: "A", W: 2, H: 1 }]);
  assert.equal(items[0].x, 0);
  assert.equal(items[0].y, 0);
  assert.equal(items[0].locked, false);
});

test("GridStack: a box is at least one cell and never left of or above the grid", () => {
  const { items } = readItems([{ id: "A", x: -3, y: -1, w: 0, h: -2 }]);
  assert.deepEqual([items[0].x, items[0].y, items[0].w, items[0].h], [0, 0, 1, 1]);
});

test("GridStack: an unknown state is no state", () => {
  assert.equal(readItems([{ id: "A", state: "Purple" }]).items[0].state, "");
});

test("GridStack: ABAP booleans in every spelling", () => {
  const { items } = readItems([
    { id: "A", locked: true, selected: "X" },
    { id: "B", locked: "", selected: false },
  ]);
  assert.deepEqual([items[0].locked, items[0].selected], [true, true]);
  assert.deepEqual([items[1].locked, items[1].selected], [false, false]);
});

test("GridStack: a row without an id and a second row with a taken id are dropped", () => {
  const { items, dropped } = readItems([{ id: "A" }, { text: "no id" }, { id: "A" }, { id: "B" }]);
  assert.deepEqual(items.map((item) => item.id), ["A", "B"]);
  assert.equal(dropped.length, 2);
  assert.match(dropped[0], /row 2/);
  assert.match(dropped[1], /duplicate id 'A'/);
});

test("GridStack: no table is no box", () => {
  assert.deepEqual(readItems(null).items, []);
});

test("GridStack: a move is written into the keys the app sent", () => {
  const rows = [
    { ID: "A", X: 0, Y: 0, W: 2, H: 1, TEXT: "a" },
    { ID: "B", X: 2, Y: 0, W: 2, H: 1, TEXT: "b" },
  ];
  const merged = mergeLayout(rows, [
    { id: "A", x: 4, y: 2, w: 2, h: 1 },
    { id: "B", x: 2, y: 0, w: 2, h: 1 },
  ]);
  assert.deepEqual(merged.ids, ["A"]);
  assert.deepEqual(merged.rows[0], { ID: "A", X: 4, Y: 2, W: 2, H: 1, TEXT: "a" });
  // the row that did not move is the very same object, and the input is untouched
  assert.equal(merged.rows[1], rows[1]);
  assert.equal(rows[0].X, 0);
});

test("GridStack: camelCase rows get camelCase positions", () => {
  const merged = mergeLayout([{ id: "A", x: 0, y: 0, w: 1, h: 1 }], [{ id: "A", x: 1, y: 0, w: 3, h: 1 }]);
  assert.deepEqual(merged.rows[0], { id: "A", x: 1, y: 0, w: 3, h: 1 });
});

test("GridStack: a position the binding had filtered out is added in the id's spelling", () => {
  const merged = mergeLayout([{ ID: "A", W: 2, H: 1 }], [{ id: "A", x: 3, y: 0, w: 2, h: 1 }]);
  assert.deepEqual(merged.rows[0], { ID: "A", W: 2, H: 1, X: 3 });
});

test("GridStack: an unchanged layout is not written back", () => {
  const rows = [{ ID: "A", X: 1, Y: 1, W: 2, H: 2 }];
  assert.equal(mergeLayout(rows, [{ id: "A", x: 1, y: 1, w: 2, h: 2 }]), null);
  assert.equal(mergeLayout(rows, []), null);
});

test("GridStack: a box the grid does not know keeps its row", () => {
  const rows = [
    { ID: "A", X: 0, Y: 0, W: 1, H: 1 },
    { ID: "", X: 5, Y: 5, W: 1, H: 1 },
  ];
  const merged = mergeLayout(rows, [{ id: "A", x: 1, y: 0, w: 1, h: 1 }]);
  assert.equal(merged.rows[1], rows[1]);
});

test("GridStack: not editable is a static grid", () => {
  assert.equal(toOptions({}).staticGrid, true);
  assert.equal(toOptions({ editable: true }).staticGrid, false);
});

test("GridStack: boxes stay where they are put unless float is switched off", () => {
  assert.equal(toOptions({}).float, true);
  assert.equal(toOptions({ float: false }).float, false);
});

test("GridStack: rows make a board with an edge, none lets it grow", () => {
  assert.deepEqual([toOptions({ rows: 4 }).minRow, toOptions({ rows: 4 }).maxRow], [4, 4]);
  assert.deepEqual([toOptions({}).minRow, toOptions({}).maxRow], [0, 0]);
});

test("GridStack: sizes have a floor", () => {
  const options = toOptions({ columns: 0, cellHeight: 1, margin: -4 });
  assert.equal(options.column, 1);
  assert.equal(options.cellHeight, 10);
  assert.equal(options.margin, 0);
});
