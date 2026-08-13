/* ═══════════════════════════════════════════════════════════════════════════
   Backend del formulario — Google Apps Script
   ═══════════════════════════════════════════════════════════════════════════

   Pegar TODO este archivo en el editor de Apps Script, reemplazando lo que haya.
   Después: Implementar → Administrar implementaciones → lápiz → Versión: Nueva.
   (Guardar no alcanza. Una implementación sirve la versión congelada, no el código
   que estás viendo en pantalla. Es el error más común de este setup.)

   Verificación: abrir la URL /exec en el navegador. Tiene que devolver JSON con
   {"ok":true,...}. Si dice "Script function not found: doGet", la implementación
   quedó en una versión vieja y hay que rehacer el paso de arriba.
   ═══════════════════════════════════════════════════════════════════════════ */

/* ID de la hoja de cálculo: el tramo largo entre /d/ y /edit en su URL.
   Usamos openById() y no getActiveSpreadsheet() a propósito. getActiveSpreadsheet()
   sólo funciona si el script está *vinculado* a la hoja (creado desde
   Extensiones → Apps Script dentro de la hoja). Si el proyecto se creó suelto desde
   script.google.com, devuelve null, doPost falla, y como el error queda atrapado en
   el try/catch el formulario recibe un HTTP 200 y cree que todo salió bien mientras
   no se escribe ninguna fila. openById() funciona en los dos casos. */
const SHEET_ID = '1V_3baEk7XSe36Mdlvn47bVgDBBcbMaYE8NmguHS9Zn8';
const HOJA = 'respuestas';

function hoja_() {
  const ss = SpreadsheetApp.openById(SHEET_ID);
  return ss.getSheetByName(HOJA) || ss.insertSheet(HOJA);
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

/* Chequeo de salud. Abrir la URL /exec en el navegador ejecuta esto y confirma de una
   sola vez tres cosas: que la implementación está publicada, que corre la versión con
   este código, y que el script puede efectivamente abrir y escribir en la hoja. */
function doGet() {
  try {
    const h = hoja_();
    return json_({
      ok: true,
      hoja: h.getName(),
      respuestas: Math.max(0, h.getLastRow() - 1),
      revisado: new Date().toISOString()
    });
  } catch (err) {
    return json_({ ok: false, error: String(err) });
  }
}

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.waitLock(30000);                      // evita filas pisadas con 30 personas a la vez
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return json_({ ok: false, error: 'POST sin cuerpo' });
    }
    const datos = JSON.parse(e.postData.contents);
    if (!datos.participant_id) {
      return json_({ ok: false, error: 'falta participant_id' });
    }

    const hoja = hoja_();

    // la primera respuesta define el encabezado
    if (hoja.getLastRow() === 0) {
      hoja.appendRow(Object.keys(datos));
    }
    const encabezado = hoja.getRange(1, 1, 1, hoja.getLastColumn()).getValues()[0];
    const valores = encabezado.map(function (k) {
      return datos[k] !== undefined ? datos[k] : '';
    });

    // Idempotencia: participant_id es la columna 1. Si ya existe, se pisa la fila en vez de
    // agregar otra. Sin esto, el reintento del formulario ante un error de CORS duplicaría.
    const previos = hoja.getLastRow() > 1
      ? hoja.getRange(2, 1, hoja.getLastRow() - 1, 1).getValues().map(function (f) { return f[0]; })
      : [];
    const i = previos.indexOf(datos.participant_id);

    if (i === -1) {
      hoja.appendRow(valores);
    } else {
      hoja.getRange(i + 2, 1, 1, valores.length).setValues([valores]);
    }

    return json_({ ok: true, fila: i === -1 ? hoja.getLastRow() : i + 2 });
  } catch (err) {
    return json_({ ok: false, error: String(err) });
  } finally {
    lock.releaseLock();
  }
}

/* Correr esto una vez desde el editor (botón Ejecutar, con doPost_prueba seleccionada)
   sirve para dos cosas: dispara el pedido de permisos sobre la hoja, y deja una fila de
   prueba que confirma que la escritura funciona sin depender del navegador ni de CORS.
   Después borrar la fila a mano. */
function doPost_prueba() {
  const r = doPost({ postData: { contents: JSON.stringify({
    participant_id: 'PRUEBA-' + Date.now(),
    fuente: 'prueba',
    timestamp_iso: new Date().toISOString()
  }) } });
  Logger.log(r.getContent());
}
