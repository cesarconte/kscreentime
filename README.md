# KScreenTime — Tiempo de Uso para KDE Plasma 6 (Wayland)

**KScreenTime** replica la funcionalidad **Tiempo de Uso (*Screen Time*)** de macOS en **CachyOS / Arch Linux con KDE Plasma 6.8 (Wayland)**, integrando el diseño visual **Liquid Glass** (tarjetas translúcidas con refracción luminosa y acento `#00e5ff`) y `Kirigami`.

## Características principales

- **Seguimiento nativo en Wayland (KWin Scripting + D-Bus)**:
  - Registra el servicio D-Bus `org.cesar.kscreentime` (`/Tracker`) y carga un script transitorio en `org.kde.KWin /Scripting` conectado a `workspace.windowActivated` para detectar en tiempo real la aplicación activa sin depender de X11.
  - Incrementa segundo a segundo el uso diario por aplicación y persiste las estadísticas en `~/.local/share/kscreentime/usage.json`.
- **Panel de control Liquid Glass**:
  - **Resumen diario**: Tiempo total de pantalla hoy (`Xh Ym`), comparativa porcentual frente a la media de los últimos 7 días e indicador en vivo de la ventana activa en Wayland.
  - **Desglose por categorías**: Clasificación automática en *Desarrollo*, *Navegación*, *Multimedia*, *Comunicación* y *Sistema*.
  - **Gráfica interactiva de 7 días**: Barras diarias proporcionales; al hacer clic en cualquier día se inspecciona el desglose detallado de esa fecha.
  - **Límites diarios por aplicación (*App Limits*)**: Configuración rápida de límites (`15m`, `30m`, `60m`, `Sin límite`) con alerta visual y notificación nativa de escritorio (`org.freedesktop.Notifications`) al superar el tiempo asignado.

## Requisitos

- KDE Plasma 6.8+ (sesión Wayland)
- Qt 6.7+ (`Core`, `Gui`, `Widgets`, `Qml`, `Quick`, `QuickControls2`, `DBus`, `Test`)
- KDE Frameworks 6 (`CoreAddons`, `I18n`, `Kirigami`)
- CMake 3.20+ y compilador C++20

## Compilación e instalación

```bash
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=$HOME/.local -DBUILD_TESTING=ON
cmake --build build -j$(nproc)
ctest --test-dir build --output-on-failure
cmake --install build
kbuildsycoca6 >/dev/null 2>&1
```

## Uso

Ejecuta la aplicación desde el lanzador de aplicaciones de KDE (**KScreenTime (Tiempo de Uso)**) o desde terminal:

```bash
~/.local/bin/kscreentime
```

Los datos se guardan automáticamente en `~/.local/share/kscreentime/usage.json`.

## Limitaciones conocidas

- El seguimiento continuo requiere que `kscreentime` esté en ejecución durante la sesión de KDE Plasma Wayland.
- Las ventanas del propio shell (`plasmashell`) se excluyen deliberadamente del cómputo para reflejar únicamente el uso real de aplicaciones.
