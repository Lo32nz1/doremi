# Proyecto: Do Re Mi (Aplicaciones Móviles)

## Descripción General
Aplicación móvil desarrollada en Flutter (Android/iOS) que funciona como herramienta integral para músicos en ensayos y escenarios en vivo. El proyecto está diseñado para ser desarrollado en paralelo por **3 integrantes** sin conflictos de integración.

Cuenta con tres módulos principales:
1. **Módulo 1 — Cancionero (Formato ChordPro):** Visualización, búsqueda, creación y edición de canciones con letra y acordes integrados entre corchetes (formato ChordPro, ej. `[La m]`, `[Do]`, `[Fa]`, `[Sol]`). Permite alinear cada acorde exactamente sobre su sílaba, ajustar el tamaño de fuente sin perder la alineación, transportar la tonalidad por semitonos (`-1` / `+1`) en notación latina y americana, e importar/exportar canciones en formato `.cho`.
2. **Módulo 2 — Repertorios (Setlists):** Creación y gestión de listas ordenadas de canciones (`Canción 1 -> Canción 2 -> Canción 3 -> Canción 4`) pensadas para presentaciones en vivo o ensayos.
3. **Módulo 3 — Afinador de Guitarra:** Herramienta interactiva para afinar las 6 cuerdas estándar de la guitarra (`Mi`, `La`, `Re`, `Sol`, `Si`, `Mi`) mediante indicador central de nota, medidor visual de desviación (cents/Hz) y selector de cuerdas.

## Arquitectura de Carpetas (dentro de `lib/`)
- `lib/models/`: Modelos de datos y serialización.
  - `song.dart`: Modelo `Song`, conversión/parseo de formato `.cho` (ChordPro) y repositorio/estado en memoria con canciones iniciales.
  - `setlist.dart`: Modelo `Setlist` con secuencias ordenadas de canciones.
- `lib/screens/`: Pantallas principales y de navegación.
  - `main_navigation_screen.dart`: Contenedor principal con `NavigationBar` de 3 pestañas (`Cancionero`, `Repertorios`, `Afinador`).
  - `songs_screen.dart`: Lista de canciones con buscador en tiempo real, importación `.cho` y acceso al editor.
  - `song_detail_screen.dart`: Lector de escenario con controles de transporte (`-` / `+`), zoom tipográfico, exportación `.cho` y edición.
  - `song_editor_screen.dart`: Editor con inserción rápida de acordes en la posición del cursor.
  - `setlists_screen.dart`: Vista de repertorios con flujo ordenado de canciones (`Canción 1 -> Canción 2 -> ...`).
  - `tuner_screen.dart`: Interfaz del afinador cromático/de guitarra para las 6 cuerdas.
- `lib/widgets/`: Componentes reutilizables.
  - `chord_lyrics_viewer.dart`: Motor de renderizado ChordPro y transposición musical (soporta notación latina `Do..Si` y americana `C..B`, acordes menores `m`, sostenidos `#` y bajos con `/`).
- `lib/services/`: Lógica de negocio, almacenamiento local, importación/exportación `.cho` y procesamiento de audio.
  - `song_service.dart`: Servicio compartido de canciones y utilidades de archivos `.cho`.

## Reglas de Desarrollo para los 3 Integrantes
- **Tema Visual:** Usar Material 3 con un tema oscuro moderno de alto contraste (pensado para lectura rápida en escenarios con poca luz).
- **Trabajo en Paralelo sin Conflictos:**
  - `lib/main.dart` y `lib/screens/main_navigation_screen.dart` actúan únicamente como punto de entrada y enrutador de pestañas.
  - **Integrante 1 (Cancionero):** Trabaja en `song.dart`, `chord_lyrics_viewer.dart`, `songs_screen.dart`, `song_detail_screen.dart` y `song_editor_screen.dart`.
  - **Integrante 2 (Repertorios):** Trabaja en `setlist.dart` y `setlists_screen.dart` (consumiendo canciones desde `song.dart`/`song_service.dart`).
  - **Integrante 3 (Afinador):** Trabaja en `tuner_screen.dart` y futuros servicios de captura de audio en `lib/services/`.
- **Dependencias:** No agregar paquetes externos sin consenso del equipo; priorizar soluciones nativas del SDK de Flutter.
