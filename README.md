# FranFundir — Léeme

Addon para **World of Warcraft Forever** que, con los precios de **TradeSkillMaster**, dice qué te conviene hacer con cada mena y cada lingote: **venderlo tal cual o fundirlo**, y en ese caso en qué. No mira solo un paso: un lingote de cobre puede valer más convertido en dos lingotes de bronce, y eso hace que la mena de cobre valga más fundida.

- **En el tooltip** de cada mena y lingote: lo que te deja venderlo, la mejor opción con sus pasos y cuánto ganas respecto a vender.
- **Un informe de lo que llevas** (botón del minimapa o `/fundir`): mira las bolsas y te dice qué fundir, qué vender, qué te hace falta comprar y cuánto ganas con todo.
- **Una tabla de precios** (clic derecho en el botón o `/fundir tabla`) con todos los materiales, los lleves o no.
- **Todas las recetas** de Forever que gastan menas o lingotes: las de minería (fundir, aleaciones incluidas) y las transmutaciones de alquimia.
- **Solo las recetas que sabe tu personaje**, o todas, si quieres ver qué daría aprenderlas.
- **Las recetas se leen del juego** al abrir la ventana de minería o de alquimia: si Forever cambia una o añade otra, se usa la del juego y te avisa en el chat.

Necesita TradeSkillMaster con datos de precios. Sin él, el addon carga pero lo dice y no calcula nada.

---

## Índice

1. [Instalación](#instalación)
2. [Uso](#uso)
3. [Cómo se calcula](#cómo-se-calcula)
4. [Recetas](#recetas)
5. [El addon por dentro](#el-addon-por-dentro)
6. [Datos guardados](#datos-guardados)
7. [Estructura del proyecto](#estructura-del-proyecto)

---

## Instalación

1. Copia la carpeta `FranFundir` en `World of Warcraft\_forever_\Interface\AddOns\`.
2. Instala y activa **TradeSkillMaster**, y deja que tenga precios (su aplicación de escritorio o un escaneo de la casa de subastas).
3. Entra con el personaje y **abre una vez la ventana de minería** (y la de alquimia, si la tienes): así el addon sabe qué recetas tienes.

---

## Uso

### Tooltip

Al pasar el ratón por una mena o un lingote:

```
FranFundir
Vender: 95c
Mejor: Cobre fundido › Bronce fundido › vender Lingote de bronce — 1p 94c (+99c)
```

Todo es **por unidad** y con la comisión de la casa de subastas (5 %) ya descontada. Si lo mejor es venderlo, lo dice. Si una transmutación deja todavía más, sale en otra línea con su tiempo de espera:

```
Con espera (cada 1 h): Hierro fundido › Transmutar: hierro a oro › vender Lingote de oro — 9p 50c (+6p 65c)
```

### Informe de lo que llevas

**Clic en el botón del minimapa** (el lingote de bronce) o `/fundir`: el addon mira las menas y lingotes de tus bolsas y te dice qué hacer con ellos.

```
 Venderlo tal cual    Siguiendo los consejos        Ganas
      38p 55c                56p 36c               +17p 81c

 Fundir y fabricar                                    Te deja · ganas
 ──────────────────────────────────────────────────────────────────
 [icono] 10 Mena de cobre                                    19p 40c
         Cobre fundido › Bronce fundido › vender 20 ...      +9p 90c

 Para eso te hace falta                           Cuesta lo que falta
 ──────────────────────────────────────────────────────────────────
 [icono] 10 Lingote de estaño                                 5p 40c
         Llevas 4, faltan 6                                  comprar

 Vender tal cual · Aún mejor, con espera · Sin precio ...

 [x] Contar también las recetas que no sé        [Tabla de precios]
 Precios de TSM. Venta: dbmarket (menos el 5% de comisión). Compra: ...
```

- **Arriba, el resumen**: lo que sacarías vendiéndolo todo tal cual, lo que sacas siguiendo los consejos y la diferencia.
- **Fundir y fabricar**: lo que deja más convertido en otra cosa, con los pasos y **cuántos salen de verdad**. Solo cuenta recetas enteras: de 13 menas de hierro negro sale 1 lingote y sobran 5, y si aún no llega para una, dice cuántas faltan. Lo que más gana va arriba.
- **Para eso te hace falta**: lo demás que piden esas recetas (el estaño del bronce, el carbón del acero), sumado, con lo que ya llevas y lo que cuesta comprar lo que falta.
- **Vender tal cual**: lo que mejor se vende sin tocarlo.
- **Aún mejor, con espera**: si una transmutación deja más, por unidad y con su tiempo de espera (no sirve para todo el montón).
- **Sin precio**: lo que TSM aún no sabe valorar.

Al pasar el ratón por una fila sale el tooltip del objeto. El informe se pone al día solo al cambiar lo que llevas, y la ventana crece o encoge según lo que haya que enseñar.

Lo que pide una receta se valora a precio de compra, cada material por separado. Si llevas lingotes de estaño, el informe puede aconsejarte hacer bronce con ellos y, a la vez, contarlos para el bronce del cobre. La sección «Para eso te hace falta» lo deja a la vista.

### Botón del minimapa

| Acción | Qué hace |
|---|---|
| Clic | Abre o cierra el informe de lo que llevas |
| Clic derecho | Abre o cierra la tabla de precios |
| Arrastrar | Lo mueve alrededor del minimapa |

`/fundir minimapa` lo oculta o lo vuelve a mostrar. Cada personaje recuerda dónde lo dejaste.

### Tabla de precios

`/fundir tabla` (o clic derecho en el botón) abre o cierra una tabla con cada material:

| Columna | Qué es |
|---|---|
| Material | La mena o el lingote |
| Vender | Lo que te deja venderlo tal cual, por unidad |
| Mejor opción | «Vender» o lo que acabas vendiendo al final de los pasos (por ejemplo «Lingote de bronce») |
| Te deja | Lo que da por unidad la mejor opción |
| Llevas | Cuántos tienes en las bolsas |
| Ganas | Lo que sacas de más con todo lo que llevas, respecto a venderlo tal cual |

Al pasar el ratón por una fila sale el tooltip del objeto, con los pasos. La tabla se pone al día sola al cambiar lo que llevas.

Abajo, la casilla **Contar también las recetas que no sé** calcula como si las supieras todas, para ver qué daría aprenderlas o qué hacer con las menas desde otro personaje. Debajo se ven los precios de TSM que se están usando.

### Comandos

| Comando | Qué hace |
|---|---|
| `/fundir` | Abre o cierra el informe de lo que llevas |
| `/fundir tabla` | Abre o cierra la tabla de precios de todos los materiales |
| `/fundir minimapa` | Oculta o vuelve a mostrar el botón del minimapa |
| `/fundir venta <precio de TSM>` | Con qué precio de TSM se vende. Por defecto `dbmarket`. Ejemplo: `/fundir venta dbminbuyout`. Sin nada, vuelve al de por defecto |
| `/fundir compra <precio de TSM>` | Con qué precio se compra lo que piden las recetas además del material (el estaño del bronce, el carbón del acero). Por defecto `min(vendorbuy, dbmarket)`: lo más barato entre el vendedor y la subasta |
| `/fundir recetas` | Qué recetas tiene en cuenta, cuáles sabe este personaje y cuáles ha cambiado o añadido el juego |
| `/fundir errores` | Errores de Lua apuntados; con un número, uno entero con su pila; con `borrar`, vacía la lista |
| `/fundir ayuda` | Versión y lista de comandos (también sale con cualquier otro texto) |

Los precios aceptan cualquier fuente o fórmula de TSM; si TSM no la acepta, no se cambia y te dice por qué.

---

## Cómo se calcula

Para cada material se busca lo que más te deja **por unidad**:

```
valor(material) = el mayor de
    vender(material)
    para cada receta que lo gasta:
        (cantidad que sale × valor(lo que sale) − precio de compra de lo demás que pide)
        / cantidad del material que gasta
```

Es recursivo: lo que sale de una receta vale lo mejor que se pueda hacer con ello, que puede ser venderlo o gastarlo en otra receta. Por ejemplo, con el bronce a 1p 50c, el estaño a 90c y el cobre a 1p 20c:

- **Lingote de cobre:** venderlo deja 1p 14c (tras el 5 %). Gastarlo en bronce deja 2 × 1p 42c − 90c (el lingote de estaño) = **1p 94c**.
- **Mena de cobre:** venderla deja 95c; fundirla da un lingote que vale 1p 94c, así que **1p 94c**.

Detalles:

- **Vender** es lo que da la casa de subastas menos la comisión del 5 %, o lo que paga un vendedor si es más.
- **Lo demás que pide una receta** se valora a precio de compra: lo que cuesta tenerlo o, si ya lo tienes, lo que dejas de ganar al no venderlo.
- **Sin precio** de algo que hace falta, esa opción no se cuenta.
- Solo se cambia de opción si deja al menos 1 cobre más: con un empate, mejor vender y no complicarse.
- **Las recetas con tiempo de espera** (las transmutaciones) no sirven para un montón de menas: las ventanas no las cuentan en el plan y las enseñan aparte, con su espera, igual que el tooltip.

---

## Recetas

Todas las de Forever que gastan una mena o un lingote, comprobadas una a una en Wowhead Forever (IDs, cantidades y tiempos de espera). Forever solo tiene el contenido del juego original: no hay hierro vil ni cobalto.

| Receta | Gasta | Da | Espera |
|---|---|---|---|
| Fundir cobre | Mena de cobre | Lingote de cobre | |
| Fundir estaño | Mena de estaño | Lingote de estaño | |
| Fundir bronce | Lingote de cobre + lingote de estaño | **2** lingotes de bronce | |
| Fundir plata | Mena de plata | Lingote de plata | |
| Fundir hierro | Mena de hierro | Lingote de hierro | |
| Fundir acero | Lingote de hierro + carbón | Lingote de acero | |
| Fundir oro | Mena de oro | Lingote de oro | |
| Fundir mitril | Mena de mitril | Lingote de mitril | |
| Fundir veraplata | Mena de veraplata | Lingote de veraplata | |
| Fundir torio | Mena de torio | Lingote de torio | |
| Fundir hierro negro | **8** menas de hierro negro | Lingote de hierro negro (solo en la Forja Negra) | |
| Fundir elementium | Mena de elementium + **10** lingotes de arcanita + núcleo de fuego + **3** flujos elementales | Lingote de elementium | |
| Transmutar: hierro a oro | Lingote de hierro | Lingote de oro | 1 h |
| Transmutar: mitril a veraplata | Lingote de mitril | Lingote de veraplata | 1 h |
| Transmutar: arcanita | Lingote de torio + cristal arcano | Lingote de arcanita | 2 días |

Las transmutaciones de hierro y mitril tienen **1 hora** de espera en Forever según Wowhead (no los 2 días del juego original).

### Lo que dice el juego manda

Esta tabla es el punto de partida, para que el addon funcione desde el primer momento. Pero **al abrir la ventana de la profesión** (minería o alquimia) el addon lee sus recetas tal y como las da el juego y apunta:

- **Cuáles sabe el personaje**, y cuáles salen en la ventana sin aprender. Mientras no la abra, se pregunta al juego por los hechizos, que no siempre las incluye: por eso el tooltip pide abrir la ventana de minería si aún no conoce ninguna.
- **Lo que gasta y lo que da cada receta**, para toda la cuenta. Si no coincide con la tabla (Forever ha cambiado la receta) o es una receta nueva que gasta o da una mena o lingote, **los cálculos usan la del juego** y lo avisa una vez en el chat:

  ```
  FranFundir: Hierro negro fundido ha cambiado en el juego: 6 Mena de hierro negro → Lingote de hierro negro. Se usa la del juego.
  ```

  `/fundir recetas` vuelve a enseñar cuáles están cambiadas o son nuevas. Así se sabe qué poner al día en `Data/Recipes.lua`.

El juego no da el tiempo de espera en la ventana: ese sale siempre de la tabla. Una receta nueva que no esté en ella se trata como si no tuviera espera.

Solo se pueden leer las profesiones que tiene el personaje que abre la ventana (las transmutaciones, con un alquimista).

---

## El addon por dentro

Todos los archivos reciben la misma tabla privada (`local _, ns = ...`). Las únicas globales son las que exige WoW (el comando, las ventanas `FranFundirReport` y `FranFundirWindow` para cerrarlas con Escape, el botón `FranFundirMinimapButton`) y `FranFundir`, que expone esa tabla para inspeccionarla con `/dump`.

| Archivo | Qué hace |
|---|---|
| [`Core/Constants.lua`](Core/Constants.lua) | Constantes: comisión, precios de TSM por defecto, medidas y textos de la interfaz |
| [`Core/Util.lua`](Core/Util.lua) | *Compartido con FranTools.* Utilidades: eventos protegidos, mensajes entre módulos, *debounce*, chat |
| [`Core/Api.lua`](Core/Api.lua) | *Compartido con FranTools.* Única puerta a la API del juego: objetos y sus tooltips, recetas de la profesión abierta, dinero… |
| [`Core/ErrorLog.lua`](Core/ErrorLog.lua) | *Compartido con FranTools.* Registro de errores de Lua (`/fundir errores`) |
| [`Core/Storage.lua`](Core/Storage.lua) | Único módulo que toca las SavedVariables de preferencias y recetas |
| [`Core/Tsm.lua`](Core/Tsm.lua) | Única puerta a TradeSkillMaster (`TSM_API`): precios y validar fórmulas, sin errores de Lua si falta algo |
| [`Data/Recipes.lua`](Data/Recipes.lua) | Las recetas y la lista de materiales, con sus IDs comprobados |
| [`Core/Recipes.lua`](Core/Recipes.lua) | Las recetas combinadas (las del juego mandan sobre las de los datos), qué gasta cada material y cuáles sabe el personaje |
| [`Core/RecipeScan.lua`](Core/RecipeScan.lua) | Lee la ventana de la profesión al abrirla: qué recetas sabe y lo que gasta y da cada una según el juego |
| [`Core/Prices.lua`](Core/Prices.lua) | Precio de venta (menos la comisión, o el del vendedor) y de compra; fuentes de TSM configurables |
| [`Core/Planner.lua`](Core/Planner.lua) | El cálculo: el mejor plan para cada material, aparte el que usa recetas con espera, y las cantidades de verdad con lo que llevas |
| [`Core/BagReport.lua`](Core/BagReport.lua) | El informe de las bolsas: qué fundir, qué vender, qué hace falta comprar y los totales |
| [`UI/Tooltip.lua`](UI/Tooltip.lua), [`UI/Checkbox.lua`](UI/Checkbox.lua), [`UI/MinimapButton.lua`](UI/MinimapButton.lua) | *Compartidos con FranTools.* Tooltips de ayuda, casillas y el botón del minimapa |
| [`UI/PlanText.lua`](UI/PlanText.lua) | Un plan en texto: pasos, dinero, ganancia y espera |
| [`UI/ItemTooltip.lua`](UI/ItemTooltip.lua) | Las líneas del tooltip de menas y lingotes |
| [`UI/RecipeNotice.lua`](UI/RecipeNotice.lua) | El aviso en el chat de una receta cambiada o nueva en el juego |
| [`UI/BaseWindow.lua`](UI/BaseWindow.lua) | Lo común a las dos ventanas: marco que se mueve y recuerda su sitio, ponerse al día, tooltip de las filas y la casilla de las recetas |
| [`UI/Window.lua`](UI/Window.lua) | La tabla de precios (`/fundir tabla`) |
| [`UI/ReportLayout.lua`](UI/ReportLayout.lua) | El informe convertido en bloques (resumen, secciones, filas, avisos), sin tocar la interfaz |
| [`UI/ReportWindow.lua`](UI/ReportWindow.lua) | La ventana del informe: pinta los bloques reutilizando sus marcos |
| [`UI/Minimap.lua`](UI/Minimap.lua) | El botón del minimapa de este addon: qué hace cada clic |
| [`Core/Commands.lua`](Core/Commands.lua) | Los comandos `/fundir` |

Los archivos compartidos se editan en [FranTools](https://github.com/fran76yt/FranTools) y se copian aquí con su `tools/sync_shared.py`.

### Pruebas

El addon se puede probar sin abrir el juego: [`tests/run.js`](tests/run.js) carga sus archivos en el orden del `.toc`, como hace WoW, sobre una API del juego simulada en Lua, y ejecuta las pruebas de [`tests/test.lua`](tests/test.lua): precios, el cálculo con sus cadenas de recetas, el tooltip, el informe de las bolsas, las dos ventanas, el botón del minimapa, los comandos y la lectura de recetas del juego (cambiadas, nuevas, sin aprender, cliente antiguo). Hace falta [Node.js](https://nodejs.org/).

```bash
cd tests
npm install   # la primera vez: instala fengari, un Lua escrito en JavaScript
npm test
```

Cada comprobación que pasa escribe `ok` y la primera que falla para con un error (y el comando sale con código 1). Las SavedVariables que quedarían se escriben en `tests/out/FranFundir.lua`.

| Archivo | Qué es |
|---|---|
| [`tests/test.lua`](tests/test.lua) | Las pruebas |
| [`tests/stubs.lua`](tests/stubs.lua) | Lo que solo simula este addon: TradeSkillMaster, los tooltips y la ventana de profesión |
| [`tests/api_stubs.lua`](tests/api_stubs.lua) | *Compartido con FranTools.* La API de WoW simulada |
| [`tests/run.js`](tests/run.js) | *Compartido con FranTools.* Carga la API simulada, el addon y las pruebas |

Aquí corre Lua 5.3 y WoW usa Lua 5.1, así que lo que cambia entre ambos (como los números enteros y decimales) no queda probado.

---

## Datos guardados

```
WTF\Account\<CUENTA>\SavedVariables\FranFundir.lua                     FranFundirDB y FranFundirLog
WTF\Account\<CUENTA>\<Reino>\<Personaje>\SavedVariables\FranFundir.lua  FranFundirChar
```

Solo se guarda lo que has cambiado:

```lua
FranFundirDB = {                       -- toda la cuenta
    ["sellSource"] = "dbminbuyout",     -- precio de venta, si no es el de por defecto
    ["allRecipes"] = true,              -- contar también las recetas que no sabes
    ["point"] = { "CENTER", "CENTER", 0, 0 },         -- posición de la tabla
    ["reportPoint"] = { "CENTER", "CENTER", 0, 0 },   -- y la del informe
    ["gameRecipes"] = {                 -- recetas leídas del juego, por hechizo
        [2659] = { ["reagents"] = { { 2840, 1 }, { 3576, 1 } }, ["output"] = { 2841, 2 } },
    },
}
FranFundirChar = {                     -- cada personaje
    ["known"] = { [2657] = true, [2659] = true, [3569] = false },   -- sabe (true) o sale sin aprender (false)
    ["minimap"] = { ["angle"] = 195 },  -- botón del minimapa (y hidden, si lo ocultas)
}
```

`FranFundirLog` son los errores de Lua apuntados (`/fundir errores`).

---

## Estructura del proyecto

```
FranFundir/
├── FranFundir.toc                     metadatos y orden de carga
├── Core/
│   ├── Constants.lua                  constantes
│   ├── Util.lua                       utilidades genéricas (compartido)
│   ├── Api.lua                        acceso a la API del juego (compartido)
│   ├── ErrorLog.lua                   registro de errores de Lua (compartido)
│   ├── Storage.lua                    SavedVariables
│   ├── Tsm.lua                        acceso a TradeSkillMaster
│   ├── Recipes.lua                    recetas combinadas, por material y las que sabes
│   ├── RecipeScan.lua                 leer las recetas de la ventana de la profesión
│   ├── Prices.lua                     precios de venta y compra
│   ├── Planner.lua                    el cálculo
│   ├── BagReport.lua                  el informe de lo que llevas
│   └── Commands.lua                   comandos /fundir
├── Data/
│   └── Recipes.lua                    recetas de minería y alquimia
├── UI/
│   ├── Tooltip.lua                    tooltips de ayuda (compartido)
│   ├── Checkbox.lua                   casillas (compartido)
│   ├── MinimapButton.lua              botón del minimapa (compartido)
│   ├── PlanText.lua                   planes en texto
│   ├── ItemTooltip.lua                líneas del tooltip de los materiales
│   ├── RecipeNotice.lua               aviso de recetas cambiadas o nuevas
│   ├── BaseWindow.lua                 lo común a las dos ventanas
│   ├── Window.lua                     la tabla de precios
│   ├── ReportLayout.lua               el informe en bloques
│   ├── ReportWindow.lua               la ventana del informe
│   └── Minimap.lua                    qué hace el botón del minimapa
└── tests/                             pruebas fuera del juego (WoW no lo carga)
    ├── test.lua                       las pruebas
    ├── stubs.lua                      TSM y profesiones simulados
    ├── api_stubs.lua                  API de WoW simulada (compartido)
    ├── run.js                         carga el addon y ejecuta las pruebas (compartido)
    └── package.json                   dependencia: fengari (compartido)
```
