# Etapa 1 de "Quizás, quizás, quizás" — réplica para el taller

Reimplementación de la **Etapa 1** del experimento de El Gato y La Caja / Decision-making Lab
(University of Rochester), para que los estudiantes respondan el instrumento en primera persona
antes de simularlo con LLMs.

El experimento original cerró la toma de datos en octubre de 2025, así que esta réplica genera
datos propios y no interfiere con el estudio original.

---

## 1. Qué mide

| Bloque | Ítems | Escala | Variables de salida |
|---|---|---|---|
| Valor puntual | 16 expresiones verbales | slider continuo 0–100 | `punto_*`, `puntoms_*` |
| Rango | 10 de esas 16 (subconjunto `askRange` del original) | slider dual min–max 0–100 | `min_*`, `max_*`, `rangoms_*` |
| Demográficos | edad, género, nivel educativo, país, provincia | — | `edad`, `genero`, … |

Las 16 expresiones, en el wording exacto del original:

`Seguro`, `Casi seguro`, `Seguramente`, `Muy probable`, `Pienso que sí`, `Creo que sí`,
`Probable`, `Puede ser`, `Quizás`, `Igual al azar`, `No sé`, `Lo dudo`, `Poco probable`,
`Difícilmente`, `Improbable`, `Muy improbable`.

Las 10 con rango: `Seguro`, `Casi seguro`, `Muy probable`, `Creo que sí`, `Puede ser`, `Quizás`,
`Igual al azar`, `No sé`, `Lo dudo`, `Difícilmente`.

### Dos decisiones de diseño que importan para la pregunta de investigación

**Anti-anclaje.** Como en el original, cada slider arranca internamente en 50 pero **el círculo está
oculto hasta que la persona lo toca**, y el número tampoco se muestra. Nadie ve un punto medio
sugerido. Esto es deliberado: si el instrumento humano anclara en el midpoint, cualquier
concentración central que midan después sería un artefacto del instrumento y no un hallazgo
comparable con el sesgo de punto medio de los LLMs.

**Orden aleatorizado.** Cada participante ve las expresiones en orden distinto, y el orden efectivo
queda registrado en `orden_punto` / `orden_rango`. Sin esto no se puede descartar que un efecto de
posición explique parte de la variabilidad. Para desactivarlo (útil si quieren que el orden humano
sea idéntico al del prompt del LLM), poner `ALEATORIZAR = false` arriba del `<script>`.

---

## 2. Publicar el formulario

Es un único archivo sin dependencias: se puede abrir con doble clic para probarlo.

El repo ya publica con GitHub Pages desde la raíz (`_config.yml` con el tema `cayman`). Como
`form/index.html` no tiene front matter de Jekyll, se copia tal cual al sitio, sin pasar por el
layout. Una vez pusheado queda en:

```
https://gefero.github.io/factor_data_silicon_tutorial/form/
```

> Si en algún momento Jekyll llegara a interferir con el archivo, basta con crear un `.nojekyll`
> vacío en la raíz del repo.

---

## 3. Recolectar las respuestas en un Google Sheet

Sin esto el formulario funciona igual, pero cada estudiante tiene que descargar su CSV a mano.

**a.** Crear la hoja de cálculo. Desde la hoja, **Extensiones → Apps Script**, y pegar el
contenido completo de [`apps_script.gs`](apps_script.gs) reemplazando lo que haya.

Arriba de todo hay que poner el ID de la hoja:

```javascript
const SHEET_ID = '1AbC....';   // el tramo largo entre /d/ y /edit en la URL de la hoja
```

> **Por qué `openById()` y no `getActiveSpreadsheet()`.** `getActiveSpreadsheet()` sólo devuelve
> algo si el proyecto de Apps Script está *vinculado* a la hoja, es decir, si se creó desde
> Extensiones → Apps Script **dentro** de la hoja. Si en algún momento el proyecto se creó suelto
> desde `script.google.com`, devuelve `null`, `doPost` explota, el `catch` lo convierte en un
> HTTP 200 con `{ok:false}` en el cuerpo — y el formulario, si sólo mira el código de estado,
> muestra el tilde verde mientras la hoja queda vacía. Es un fallo silencioso y difícil de ver.
> `openById()` funciona en los dos casos, así que evita la categoría entera de problema.

**b.** **Implementar → Nueva implementación → Aplicación web**, con:

- *Ejecutar como*: **Yo**
- *Quién tiene acceso*: **Cualquier usuario** ← si esto queda en "solo yo", los estudiantes reciben error

**c.** Copiar la URL (`https://script.google.com/macros/s/…/exec`) y pegarla en `index.html`:

```javascript
const ENDPOINT = "https://script.google.com/macros/s/AKfycb.../exec";
```

**d.** **Verificar antes de la clase, en este orden.** Cada paso descarta una causa distinta:

1. **Abrir la URL `/exec` en el navegador.** Tiene que devolver
   `{"ok":true,"hoja":"respuestas","respuestas":0,...}`.
   - Si devuelve **`Script function not found: doGet`** → la implementación está publicada y es
     pública (buena noticia), pero está sirviendo una **versión vieja** del código. Guardar no
     alcanza: *Implementar → Administrar implementaciones → lápiz → Versión: **Nueva***.
   - Si devuelve una **pantalla de login de Google** → el acceso no quedó en "Cualquier usuario".
   - Si devuelve `{"ok":false,...}` → el script corre pero no puede abrir la hoja: revisar
     `SHEET_ID` y aceptar los permisos.
2. **Correr `doPost_prueba()` desde el editor** (botón Ejecutar). Escribe una fila de prueba sin
   pasar por el navegador. Si esto anda y el formulario no, el problema es CORS, no la hoja.
   Borrar la fila después.
3. **Completar una respuesta real** desde el formulario servido por HTTP (no con doble clic) y
   verificar que aparezca la fila.



> El `fetch` usa `Content-Type: text/plain` a propósito: con `application/json` el navegador dispara
> un preflight CORS que Apps Script no responde y el envío falla en silencio. Es el error más común
> de este setup.

Si el envío falla, la pantalla final lo dice explícitamente y ofrece el CSV como respaldo.

### Si aparece "NetworkError when attempting to fetch resource"

Es un error de CORS, no del Apps Script. Por orden de probabilidad:

1. **Estás abriendo el archivo con doble clic** (`file:///C:/...`). El origen es `null` y el navegador
   bloquea la lectura de la respuesta. El formulario reintenta automáticamente en modo `no-cors`:
   el dato llega igual, pero la pantalla avisa que no puede confirmarlo. Para tener confirmación
   real hay que servirlo por HTTP — desde GitHub Pages, o localmente con:

   ```bash
   cd form && python -m http.server 8000   # y abrir http://localhost:8000
   ```

2. **La implementación no quedó en "Cualquier usuario"**. Revisar en
   *Implementar → Administrar implementaciones*.

3. **La URL es la de `/dev` en lugar de `/exec`**. La de `/dev` sólo funciona con tu sesión
   iniciada y no sirve para los estudiantes.

4. **Se editó el script después de implementar.** Guardar no alcanza: hay que ir a
   *Implementar → Administrar implementaciones → editar (lápiz) → Versión: Nueva*.

Para ver si el POST está llegando aunque el navegador no lo confirme: en el editor de Apps Script,
**Ejecuciones** (ícono de reloj en la barra izquierda) lista cada invocación de `doPost` con su
estado y sus errores.

---

## 3 bis. Dónde quedan los datos y cómo acceden los estudiantes

```
navegador del estudiante ──POST──► Apps Script ──► Google Sheet (tu Drive, vos sos dueña)
        │
        └──► botón "Descargar CSV": solo su propia fila
```

Por defecto **cada estudiante ve únicamente su respuesta**. La tabla completa vive en tu hoja y no
se comparte sola. Para que puedan trabajar con el dataset completo hay que habilitarlo a mano.

### Opción A — hoja compartida en modo lectura (para usar en clase)

1. En la hoja: **Compartir → Acceso general → Cualquier persona con el enlace → Lector**.
2. Anotar el ID de la hoja (el tramo largo entre `/d/` y `/edit` en la URL).
3. En el notebook, los estudiantes leen el dataset con una sola línea:

```python
import pandas as pd

SHEET_ID = "1AbC...."          # el de tu hoja
GID      = "0"                 # gid de la pestaña "respuestas", visible en la URL

url = f"https://docs.google.com/spreadsheets/d/{SHEET_ID}/export?format=csv&gid={GID}"
humanos = pd.read_csv(url)

print(humanos.shape)
humanos.filter(like="punto_").describe().T[["mean", "std"]]
```

Ventaja: se actualiza en vivo, así que se puede proyectar la distribución mientras la clase todavía
está respondiendo. Desventaja: depende de que la hoja siga existiendo y compartida.

### Opción B — congelar el CSV en el repo (para que el tutorial sea reproducible)

Cuando terminó la toma:

```bash
# Archivo → Descargar → CSV, y después:
cp ~/Downloads/respuestas.csv input_data/respuestas_humanas.csv
git add input_data/respuestas_humanas.csv
git commit -m "Muestra humana etapa 1 (n=NN)"
```

Y en el notebook: `humanos = pd.read_csv("input_data/respuestas_humanas.csv")`.

**Recomendación: las dos.** Opción A durante la clase, Opción B al cerrar, para que el tutorial
quede corriendo solo el año que viene sin depender de tu Drive.

### Antes de compartir, dos chequeos

- **El consentimiento tiene que decirlo.** La pantalla inicial ya avisa que las respuestas se juntan
  con las del curso, que todo el curso accede a la tabla y que puede quedar publicada. Si cambian el
  destino de los datos (por ejemplo, publicarlos en un paper), ese texto hay que actualizarlo.
- **`user_agent`.** Es la única columna con algo de potencial de fingerprinting. Es inocua en un
  aula, pero si van a publicar el CSV en un repo público conviene borrar esa columna, o directamente
  sacarla de la función `fila()` en `index.html`.

---

## 4. Estructura del CSV (74 columnas, una fila por participante)

| Columna | Tipo | Notas |
|---|---|---|
| `participant_id` | uuid | anónimo, generado en el navegador |
| `fuente` | texto | `humano`; usen `gpt-4o`, `gpt-oss-20b`, etc. para apilar las respuestas simuladas |
| `timestamp_iso` | ISO 8601 | inicio de la sesión |
| `orden_punto` | texto | claves separadas por `\|`, en el orden en que se presentaron |
| `orden_rango` | texto | ídem para el bloque de rango |
| `punto_<expr>` | 0–100 | 16 columnas |
| `puntoms_<expr>` | ms | latencia hasta la primera interacción con ese ítem |
| `min_<expr>` / `max_<expr>` | 0–100 | 10 pares |
| `rangoms_<expr>` | ms | 10 columnas |
| `edad` | entero 14–99 | |
| `genero`, `nivel_educativo`, `pais`, `provincia` | texto | slugs sin tildes |
| `duracion_total_ms` | ms | |
| `user_agent` | texto | útil para detectar respuestas desde celular |

La columna `fuente` es la que permite apilar humanos y modelos en un mismo dataframe y correr el
análisis comparado sin reestructurar nada.

---

## 5. Cómo se conecta con el análisis de sesgo de punto medio

El análisis de Q130 que ya está en el repo opera sobre una escala ordinal de 4 categorías sin punto
medio, y define el sesgo como *concentración en las categorías interiores*. Acá la escala es
continua 0–100 **con** punto medio, así que la operacionalización cambia y en algún sentido es más
directa:

- **Masa en el midpoint**: proporción de respuestas en `[45, 55]` por expresión. En humanos esto
  debería ser alto sólo para `Igual al azar` y `No sé`; si un modelo lo infla para `Casi seguro` o
  `Lo dudo`, eso es el sesgo.
- **Exceso exacto en 50**: proporción de respuestas *exactamente* iguales a 50. En el instrumento
  humano ese valor sólo se alcanza moviendo el slider a propósito, porque el thumb arranca oculto.
  En los LLMs el 50 es un atractor fuerte. Es probablemente la métrica más limpia que van a tener.
- **Dispersión entre participantes**: desvío estándar de `punto_<expr>` por expresión. El hallazgo
  central del paper original es la *enorme* dispersión ("el casi seguro de algunos es el puede ser
  de otros"). Los LLMs típicamente colapsan esa varianza. Comparar el SD humano contra el simulado
  por modelo es la réplica directa del *flattening of within-group variability* que menciona el
  README del repo.
- **Ancho del rango** (`max - min`): en humanos varía sistemáticamente por expresión. Sirve como
  segunda prueba de si el modelo representa incertidumbre de segundo orden o sólo repite un número.
- **Coherencia interna**: proporción de casos en que `min ≤ punto ≤ max` para la misma persona y la
  misma palabra. En el estudio original fue 81%. Un modelo que dé 100% está siendo *más* consistente
  que los humanos, lo cual también es un hallazgo.

---

## 6. Archivos

- `index.html` — el formulario, autocontenido, sin dependencias externas.
- `apps_script.gs` — el backend que escribe en el Google Sheet. Se pega en el editor de Apps
  Script; no se ejecuta desde el repo. Incluye un `doGet()` de chequeo de salud y una función
  `doPost_prueba()` para verificar la escritura sin pasar por el navegador.
- `_test_formulario.js` — suite de QA con jsdom (60 chequeos: render, anti-anclaje, aleatorización,
  validaciones, arrastre y clamp del slider dual, esquema de salida). No es material del taller.

```bash
cd form && npm install jsdom && node _test_formulario.js
```

---

## 7. Pendiente de definir antes de la clase

- **Consentimiento**: la pantalla inicial dice que los datos son anónimos y voluntarios. Si esto
  pasa por un comité de ética institucional, ese texto probablemente haya que ajustarlo.
- **n de la muestra humana**: con una comisión van a tener n≈30. Alcanza para mostrar la dispersión
  y comparar medias, pero es chico para comparar formas de distribución con bootstrap. Vale
  discutirlo en clase como limitación.
- **Separar grupos**: el formulario no pregunta comisión ni cohorte — con una sola toma no hacía
  falta y era una fricción más en la primera pantalla. Si en algún momento hay que apilar varias
  comisiones, `timestamp_iso` alcanza para separarlas por fecha de toma; si no, se puede usar una
  copia del `index.html` por comisión con un valor fijo agregado en `fila()`.
