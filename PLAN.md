# 🎵 Cancionero — Plan de Desarrollo

## Objetivo
Aplicación multiplataforma para leer y mostrar canciones con acordes desde archivos locales,
sin necesidad de internet. Los archivos se sincronizan entre dispositivos con **Syncthing**.

---

## 📱 Plataformas objetivo
- ✅ Android
- ✅ Windows
- ✅ Linux

---

## 🛠️ Stack tecnológico
- **Framework**: Flutter (Dart)
- **Por qué Flutter**:
  - Un solo código para Android + Windows + Linux
  - Acceso nativo al sistema de archivos en todas las plataformas
  - Hot reload: ver cambios al instante sin reiniciar la app
  - Dart es fácil de aprender (similar a JavaScript)
  - Gran ecosistema de paquetes

---

## 📄 Formatos de archivo soportados
- `.chord` / `.pro` / `.chopro` — Formato ChordPro (acordes entre corchetes)
- `.txt` — Texto plano (sin formato de acordes)

### Ejemplo de formato ChordPro:
```
{title: Amazing Grace}
{artist: John Newton}
{key: G}

[Verso 1]
[G]Amazing [D]grace, how [Em]sweet the [C]sound
[G]That saved a [D]wretch like [G]me
```

---

## 🗂️ Estructura de carpetas del proyecto Flutter
```
cancionero/
├── lib/
│   ├── main.dart                  # Punto de entrada
│   ├── models/
│   │   └── song.dart              # Modelo de datos de una canción
│   ├── parsers/
│   │   └── chordpro_parser.dart   # Parser del formato ChordPro
│   ├── screens/
│   │   ├── home_screen.dart       # Pantalla principal
│   │   ├── song_list_screen.dart  # Lista de canciones
│   │   └── song_view_screen.dart  # Vista de una canción
│   └── widgets/
│       ├── chord_chip.dart        # Widget para mostrar un acorde
│       └── song_line.dart         # Widget para una línea con acordes
├── assets/
│   └── sample_songs/             # Canciones de ejemplo
│       └── amazing_grace.chord
├── pubspec.yaml                   # Dependencias del proyecto
└── README.md
```

---

## 🗺️ Fases de desarrollo

### ✅ Fase 0 — Planificación (ACTUAL)
- [x] Definir plataformas objetivo
- [x] Elegir stack tecnológico
- [x] Entender el formato ChordPro
- [ ] Instalar Flutter y configurar el entorno
- [ ] Crear el proyecto Flutter base

### 🔲 Fase 1 — Fundación: Leer y mostrar archivos
- [ ] Configurar acceso al sistema de archivos
- [ ] Elegir una carpeta donde están las canciones
- [ ] Listar archivos `.chord`/`.pro`/`.txt` de esa carpeta
- [ ] Mostrar el nombre de cada canción en una lista

### 🔲 Fase 2 — Parser ChordPro
- [ ] Parsear metadatos: `{title:}`, `{artist:}`, `{key:}`, `{tempo:}`
- [ ] Parsear líneas con acordes: `[G]Texto [D]con [Em]acordes`
- [ ] Separar bloques: versos, coros, puentes

### 🔲 Fase 3 — Visualización de canciones
- [ ] Mostrar acordes encima del texto correspondiente
- [ ] Diferenciar visualmente: acordes, letra, secciones
- [ ] Soporte para modo claro/oscuro

### 🔲 Fase 4 — Transposición de acordes
- [ ] Subir/bajar tono con botones +/-
- [ ] Soporte para sostenidos (#) y bemoles (b)

### 🔲 Fase 5 — Auto-scroll
- [ ] Scroll automático a velocidad configurable
- [ ] Pausar/reanudar con tap

### 🔲 Fase 6 — Gestión de Setlists
- [ ] Crear y guardar setlists
- [ ] Ordenar canciones dentro de un setlist
- [ ] Navegar entre canciones del setlist

---

## 🧰 Paquetes Flutter a usar (preliminar)
| Paquete | Para qué |
|---|---|
| `file_picker` | Elegir carpeta de canciones |
| `shared_preferences` | Guardar configuraciones (carpeta elegida, tema) |
| `provider` o `riverpod` | Manejo de estado de la app |
| `path` / `path_provider` | Manejo de rutas de archivos |

---

## 📝 Notas y decisiones tomadas
- Los archivos de canciones se almacenan **localmente** y se sincronizan con **Syncthing**
- La app **no requiere internet** en ningún momento
- El usuario elige la **carpeta raíz** de sus canciones desde la app
- Formato principal: **ChordPro** (`.chord` / `.pro`)

---

## ⏭️ Próximo paso
Instalar Flutter y crear el proyecto base.
Ver sección: **Cómo instalar Flutter** abajo.

---

## 🛠️ Cómo instalar Flutter (Linux)
```bash
# Opción recomendada: via snap
sudo snap install flutter --classic

# Verificar instalación
flutter doctor

# Habilitar soporte para Linux desktop
flutter config --enable-linux-desktop
```

## 🛠️ Cómo instalar Flutter (para compilar Android)
```bash
# Flutter doctor te dirá si falta algo
# Vas a necesitar Android Studio o Android SDK
flutter doctor --android-licenses
```

---

*Última actualización: 2026-04-08*
