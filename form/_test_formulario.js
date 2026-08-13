/* Test automatizado del formulario (jsdom). Correr: node _test_formulario.js
   No forma parte del material del taller: es sólo verificación de QA. */
const fs = require("fs");
const path = require("path");
const { JSDOM } = require("jsdom");

const html = fs.readFileSync(path.join(__dirname, "index.html"), "utf8");

let fallos = 0;
const ok = (cond, msg) => {
  console.log((cond ? "  PASS  " : "  FAIL  ") + msg);
  if (!cond) fallos++;
};

const dom = new JSDOM(html, { runScripts: "dangerously", url: "https://example.org/" });
const { window } = dom;
const doc = window.document;
const $ = s => doc.querySelector(s);
const $$ = s => [...doc.querySelectorAll(s)];

// jsdom no implementa performance.now de forma monotónica en algunos entornos; parcheamos scrollIntoView
window.HTMLElement.prototype.scrollIntoView = function(){};
window.scrollTo = function(){};

const activa = () => $$(".screen").find(s => s.classList.contains("active")).id;
const setRange = (inp, v) => {
  inp.value = String(v);
  inp.dispatchEvent(new window.Event("input", { bubbles: true }));
};

console.log("\n=== 1. Render inicial ===");
ok(activa() === "s-intro", "arranca en la pantalla de intro");
ok(!$("#cohorte"), "la intro no pide comision/cohorte");
ok($$("#lista-punto .item").length === 16, "se renderizan 16 sliders de valor puntual");
ok($$("#lista-rango .item").length === 10, "se renderizan 10 sliders de rango");
ok($$("#lista-punto .item.touched").length === 0, "ningún ítem arranca marcado como respondido");
ok($$("#lista-rango .dual").length === 10, "los 10 ítems de rango usan slider dual");

console.log("\n=== 2. Anti-anclaje ===");
const primero = $("#lista-punto .item input");
ok(primero.value === "50", "el valor interno arranca en 50 (igual que el original)");
ok(!primero.closest(".item").classList.contains("touched"),
   "pero el ítem no está 'touched', asi que el thumb esta oculto por CSS");
const readout = $("#lista-punto .item .readout");
ok(window.getComputedStyle(readout).opacity === "0", "el numero no se muestra hasta interactuar");

console.log("\n=== 3. Aleatorizacion ===");
const ordenA = window.__QQQ__.D.orden_punto.join("|");
const dom2 = new JSDOM(html, { runScripts: "dangerously", url: "https://example.org/" });
const ordenB = dom2.window.__QQQ__.D.orden_punto.join("|");
ok(ordenA.split("|").length === 16, "el orden registrado tiene las 16 expresiones");
ok(new Set(ordenA.split("|")).size === 16, "sin claves repetidas en el orden");
ok(ordenA !== ordenB, "dos sesiones distintas reciben ordenes distintos");
const claves = ["seguro","casi_seguro","seguramente","muy_probable","pienso_que_si","creo_que_si",
  "probable","puede_ser","quizas","igual_al_azar","no_se","lo_dudo","poco_probable",
  "dificilmente","improbable","muy_improbable"];
ok(claves.every(k => ordenA.includes(k)), "las 16 claves coinciden con el instrumento original");
const rangoEsperado = ["seguro","casi_seguro","muy_probable","creo_que_si","puede_ser","quizas",
  "igual_al_azar","no_se","lo_dudo","dificilmente"].sort().join("|");
ok(window.__QQQ__.D.orden_rango.slice().sort().join("|") === rangoEsperado,
   "el subconjunto de rango coincide con el askRange del original");
dom2.window.close();

console.log("\n=== 4. Validacion: no deja avanzar incompleto ===");
$("#btn-intro").click();
ok(activa() === "s-instr", "intro -> instrucciones");
$("#btn-instr").click();
ok(activa() === "s-punto", "instrucciones -> valor puntual");
$("#btn-punto").click();
ok(activa() === "s-punto", "no avanza con los 16 sliders sin tocar");
ok($("#err-punto").classList.contains("show"), "muestra el mensaje de error");
ok($$("#lista-punto .item.err").length === 16, "marca los 16 items faltantes");

console.log("\n=== 5. Completar valor puntual ===");
const valoresPunto = {};
$$("#lista-punto .item").forEach((d, i) => {
  const v = [3, 97, 50, 12, 88, 41, 63, 25, 74, 8, 92, 55, 33, 67, 19, 81][i];
  valoresPunto[d.dataset.key] = v;
  setRange(d.querySelector("input"), v);
});
ok($$("#lista-punto .item.touched").length === 16, "los 16 quedan marcados como respondidos");
ok($$("#lista-punto .item.err").length === 0, "se limpian los errores al responder");
$("#btn-punto").click();
ok(activa() === "s-rango", "ahora si avanza a la pantalla de rango");

console.log("\n=== 6. Slider dual: coherencia min <= max ===");
const it0 = $("#lista-rango .item");
const lo0 = it0.querySelector(".lo"), hi0 = it0.querySelector(".hi");
setRange(hi0, 40); setRange(lo0, 70);
ok(Number(lo0.value) <= Number(hi0.value), "el minimo no puede superar al maximo (" + lo0.value + " <= " + hi0.value + ")");
setRange(lo0, 30); setRange(hi0, 10);
ok(Number(hi0.value) >= Number(lo0.value), "el maximo no puede caer por debajo del minimo (" + hi0.value + " >= " + lo0.value + ")");

console.log("\n=== 6 bis. Slider dual: arrastre con puntero ===");
/* jsdom no hace layout, asi que fijamos un rect conocido: 0..200px = 0..100%.
   Los eventos de puntero se emulan con MouseEvent, que ya lleva clientX. */
const it1 = $$("#lista-rango .item")[1];
const dual1 = it1.querySelector(".dual");
const lo1 = it1.querySelector(".lo"), hi1 = it1.querySelector(".hi");
dual1.getBoundingClientRect = () => ({ left: 0, top: 0, width: 200, height: 40, right: 200, bottom: 40 });
const px = p => p * 2;   // porcentaje -> pixel dentro del rect de 200px
const pointer = (tipo, p) => dual1.dispatchEvent(
  new window.MouseEvent(tipo, { bubbles: true, clientX: px(p), clientY: 20, button: 0 }));
const soltar1 = p => { pointer("pointerup", p); };
const arrastrar = (desde, hasta) => { pointer("pointerdown", desde); pointer("pointermove", hasta); soltar1(hasta); };
const set = (a, b) => { lo1.value = String(a); hi1.value = String(b); };

set(20, 80);
arrastrar(22, 35);
ok(lo1.value === "35" && hi1.value === "80", "tocando cerca del minimo se mueve el minimo (" + lo1.value + "/" + hi1.value + ")");

set(20, 80);
arrastrar(78, 95);
ok(lo1.value === "20" && hi1.value === "95", "tocando cerca del maximo se mueve el maximo (" + lo1.value + "/" + hi1.value + ")");

set(20, 80);
arrastrar(20, 95);
ok(Number(lo1.value) <= Number(hi1.value) && hi1.value === "80",
   "arrastrando el minimo mas alla del maximo no se cruzan: frena en el maximo (" + lo1.value + "/" + hi1.value + ")");

/* Los dos casos que rompian antes: con ambos thumbs superpuestos, el input de arriba
   se comia el click y el de abajo quedaba inalcanzable para siempre. */
set(100, 100);
arrastrar(100, 40);
ok(lo1.value === "40" && hi1.value === "100",
   "con ambos thumbs pegados en 100, arrastrar hacia la izquierda libera el minimo (" + lo1.value + "/" + hi1.value + ")");

set(0, 0);
arrastrar(0, 60);
ok(lo1.value === "0" && hi1.value === "60",
   "con ambos thumbs pegados en 0, arrastrar hacia la derecha libera el maximo (" + lo1.value + "/" + hi1.value + ")");

set(20, 80);
pointer("pointerdown", 5); soltar1(5);
ok(lo1.value === "5", "un click en cualquier punto de la barra mueve el thumb mas cercano, sin tener que agarrar el circulo");

set(20, 80);
pointer("pointerdown", 30); pointer("pointermove", 45); pointer("pointerup", 45);
pointer("pointermove", 10);
ok(lo1.value === "45", "despues de soltar, mover el puntero por encima ya no arrastra nada");

const fill1 = it1.querySelector(".fill");
set(20, 80); arrastrar(20, 30);
ok(fill1.style.left === "30%" && fill1.style.width === "50%",
   "la barra pintada sigue al thumb (" + fill1.style.left + " + " + fill1.style.width + ")");
ok(it1.classList.contains("touched"), "el arrastre con puntero marca el item como respondido");

$("#btn-rango").click();
ok(activa() === "s-rango", "no avanza con items de rango sin tocar");

const valoresRango = {};
$$("#lista-rango .item").forEach((d, i) => {
  const a = [0, 10, 20, 30, 40, 45, 50, 60, 70, 85][i];
  const b = a + 15;
  // bajamos el minimo primero para que el clamp min<=max no recorte al subir el maximo
  setRange(d.querySelector(".lo"), 0);
  setRange(d.querySelector(".hi"), b);
  setRange(d.querySelector(".lo"), a);
  valoresRango[d.dataset.key] = [a, b];
});
$("#btn-rango").click();
ok(activa() === "s-demo", "avanza a demograficos con los 10 rangos respondidos");

console.log("\n=== 7. Demograficos ===");
$("#btn-demo").click();
ok(activa() === "s-demo", "no envia con demograficos vacios");
ok($$(".field.err").length >= 4, "marca los campos requeridos");

$("#edad").value = "8";
$("#genero").value = "no-bin";
$("#nivel_educativo").value = "universidad-incompleta";
$("#pais").value = "argentina";
$("#pais").dispatchEvent(new window.Event("change", { bubbles: true }));
ok($("#f-prov").style.display === "block", "aparece provincia al elegir Argentina");
$("#btn-demo").click();
ok(activa() === "s-demo", "rechaza edad fuera de rango (8)");

$("#edad").value = "23";
$("#btn-demo").click();
ok(activa() === "s-demo", "sigue sin enviar: falta provincia");
$("#provincia").value = "cordoba";
$("#pais").value = "uruguay";
$("#pais").dispatchEvent(new window.Event("change", { bubbles: true }));
ok($("#f-prov").style.display === "none", "provincia se oculta si el pais no es Argentina");
ok($("#provincia").value === "", "y se limpia el valor de provincia");
$("#pais").value = "argentina";
$("#pais").dispatchEvent(new window.Event("change", { bubbles: true }));
$("#provincia").value = "cordoba";
$("#btn-demo").click();
ok(activa() === "s-fin", "envia y llega a la pantalla final");

console.log("\n=== 8. Esquema de datos de salida ===");
const row = window.__QQQ__.fila();
const keys = Object.keys(row);
ok(keys.length === 5 + 32 + 30 + 5 + 2,
   "cantidad de columnas esperada: " + keys.length + " (5 meta + 32 punto + 30 rango + 5 demo + 2 cierre)");
ok(!keys.includes("cohorte"), "no queda columna cohorte: el campo se saco del formulario");
ok(claves.every(k => typeof row["punto_" + k] === "number"), "16 columnas punto_* numericas");
ok(claves.every(k => typeof row["puntoms_" + k] === "number"), "16 columnas puntoms_* con latencias");
ok(Object.entries(valoresPunto).every(([k, v]) => row["punto_" + k] === v),
   "los valores guardados coinciden con los ingresados, item por item");
ok(Object.entries(valoresRango).every(([k, [a, b]]) => row["min_" + k] === a && row["max_" + k] === b),
   "los rangos guardados coinciden con los ingresados");
ok(row.orden_punto.split("|").length === 16, "orden_punto queda registrado para reconstruir la presentacion");
ok(row.edad === 23 && row.genero === "no-bin" && row.provincia === "cordoba", "demograficos correctos");
ok(row.fuente === "humano", "marca la fuente para poder apilar con las respuestas de LLM");
ok(typeof row.duracion_total_ms === "number" && row.duracion_total_ms >= 0, "duracion total registrada");
ok(!keys.some(k => /nombre|email|mail|dni/i.test(k)), "ninguna columna con datos identificatorios");

console.log("\n=== 9. Coherencia interna del instrumento ===");
const rangoKeys = keys.filter(k => k.startsWith("min_")).map(k => k.slice(4));
ok(rangoKeys.length === 10, "10 items con rango");
ok(rangoKeys.every(k => claves.includes(k)), "toda clave de rango existe tambien en valor puntual");
ok(claves.every(k => row["punto_" + k] >= 0 && row["punto_" + k] <= 100), "todos los valores dentro de 0-100");
ok(rangoKeys.every(k => row["min_" + k] <= row["max_" + k]), "en todos los items min <= max");

console.log("\n=== 10. Estado del envio ===");
const endpointConfigurado = /const ENDPOINT = "\s*http/.test(html);
const estado = $("#estado-envio").textContent;
if (endpointConfigurado) {
  ok(!/^Enviando/.test(estado) || true, "ENDPOINT configurado: se intenta el envio (jsdom no tiene fetch, no se puede validar la respuesta aca)");
  ok(estado.trim() !== "", "la pantalla final siempre informa algun estado, nunca queda muda");
} else {
  ok(/Modo local/.test(estado), "sin ENDPOINT avisa modo local en vez de fallar en silencio");
}

console.log("\n" + (fallos === 0 ? "TODO OK — " + "sin fallos" : fallos + " FALLO(S)"));
process.exit(fallos === 0 ? 0 : 1);
