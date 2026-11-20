# Reglas Globales de Desarrollo - Ecosistema CachyOS / Kity / CachyOS.UI

## 1. Política Estricta de Instalación: ÚNICAMENTE `/usr`

> [!IMPORTANT]
> **ESTÁ ESTRICTAMENTE PROHIBIDO duplicar instalaciones en `~/.local`**.
> Todos los proyectos del ecosistema (`cachyos-ui`, `kity`, `kcm-kity`, `audiotube-extended`, `kreminders`, etc.) se instalan **ÚNICAMENTE en `/usr`**.

- **Comando de instalación estándar**:
  ```bash
  sudo -n cmake --install build --prefix /usr
  ```
  *(o `sudo -n ninja -C build install` / `sudo -n make -C build install` según el generador empleado)*
- **Prohibido**:
  - `cmake --install build --prefix ~/.local`
  - Copiar binarios, plasmoides, librerías `.so`, archivos `.desktop` o iconos a `~/.local`.
- **Razón**: Evitar conflictos de versiones, duplicidades innecesarias y sombreado (*shadowing*) de librerías en KDE Plasma 6 y CachyOS.

---

## 2. Protocolo Universal de Pre-Verificación QML (Tolerancia Cero a Fallos de Carga)

> [!CAUTION]
> **ESTÁ TERMINANTEMENTE PROHIBIDO dar por finalizada una tarea sin verificar previamente en tiempo de ejecución que el motor QML carga sin errores**.

Cada vez que se añadan o modifiquen archivos QML o componentes de `CachyOS.UI`:

1. **Verificación de Tipos y Propiedades**:
   - Nunca inventar nombres de componentes o propiedades asumidas. Verificar siempre su existencia y firma en los archivos fuente (`cachyos-ui/src/controls/`, `CachyPalette.qml`, `CachyTheme.qml`).
2. **Ciclo Obligatorio de Verificación en Ejecución**:
   - Tras compilar e instalar en `/usr`, ejecutar siempre un ciclo de prueba con el binario correspondiente:
     - Si se modificó una aplicación concreta (ej. `audiotube`, `kreminders`):
       ```bash
       timeout 2s <nombre-binario>
       ```
     - Si se modificó la librería `cachyos-ui` de forma general:
       ```bash
       timeout 2s cachyos-ui-gallery
       ```
3. **Criterio de Aceptación Estricto**:
   - La tarea solo se considera lista si la salida de la terminal está **100% limpia** de los siguientes errores críticos de QML:
     - `QQmlApplicationEngine failed to load component`
     - `Type ... unavailable`
     - `... is not a type`
     - `Cannot assign to non-existent property`
   - Si aparece cualquiera de estos errores, debe corregirse y verificarse de nuevo antes de responder al usuario.

---

## 3. Fidelidad Absoluta macOS Golden Gate y Migración Integral de Aplicaciones

> [!IMPORTANT]
> **Fidelidad Píxel a Píxel (Aspecto, Funcionalidad y Distribución)**
> Cuando se desarrolle una réplica de una aplicación o herramienta existente en **macOS Golden Gate**, la réplica debe ser **fiel píxel a píxel**:
> 1. **Aspecto visual y proporciones**: Radios de curvatura de ventana (20px), tarjetas (12px), botones (8px), bordes especulares (1px), refracción Liquid Glass y colores semánticos.
> 2. **Funcionalidad y experiencia UX**: Comportamiento operativo idéntico al de macOS (por ejemplo, creación de tareas/elementos en línea sin diálogos modales innecesarios, inspectores de detalles mediante hojas/popovers flotantes, soporte simultáneo e interactivo de rueda de ratón y clics en selectores, atajos de teclado estándar como <kbd>Ctrl+N</kbd>).
> 3. **Distribución espacial de elementos**: Estructura de cabeceras de 44px con semáforos integrados, barras laterales mediante SplitView, centrado de píldoras de navegación y títulos grandes en el contenido principal.

> [!IMPORTANT]
> **Migración Integral de Aplicaciones de KDE Plasma / CachyOS**
> Al migrar una aplicación preexistente de KDE Plasma hacia el ecosistema `CachyOS.UI`:
> 1. **Cumplimiento estricto de CachyOS.UI**: Reemplazo total de componentes heredados de Kirigami o controles sin tematizar por los componentes estándar del sistema de diseño.
> 2. **Paridad funcional del 100%**: Migración íntegra y exhaustiva de todas las funciones, opciones, atajos, filtros y flujos de datos existentes en la versión original. Está terminantemente prohibido omitir, recortar o degradar funcionalidades durante el proceso de rediseño.
