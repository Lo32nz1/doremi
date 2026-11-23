# DOREMI

DOREMI es una aplicación para android y próximamente para las demás plataforma, la misma sirve para organizar, leer canciones con
acordes, afinar los instrumentos, etc. 

## ¿Por qué DOREMI? (Origen del proyecto)

La idea de DOREMI nació de una necesidad cotidiana de los músicos: digitalizar el repertorio para dejar atrás las carpetas físicas enormes, pesadas y llenas de hojas sueltas. El formato en papel trae problemas frecuentes al ensayar o tocar en vivo, como que las hojas se pierdan, se mojen, se deterioren o terminar imprimiendo canciones duplicadas por desorganización. 

Para resolver esto, se creó esta aplicación como un espacio único, accesible y ordenado donde llevar todo el cancionero en el bolsillo, sin depender de múltiples herramientas ni suscripciones.

## Funcionalidades principales 

- **Gestión de canciones:** Creación, edición, organización y lectura de canciones con acordes posicionados directamente sobre la letra y notas o especificaciones adicionales para el músico.
- **Formateo de canciones:** Estructuración clara y ordenada del contenido musical para facilitar su lectura en cualquier momento.
- **Transposición musical:** Cambio rápido de tonalidad para adaptar cualquier canción al registro vocal o a la afinación del instrumento.
- **Organización de repertorios (Setlists):** Agrupación y ordenamiento de canciones para ensayos o presentaciones en vivo sin duplicar material.
- **Afinador de instrumentos integrado:** Detección de frecuencia en tiempo real mediante el micrófono del dispositivo, sin necesidad de instalar aplicaciones externas.
- **Uso centralizado y sin conexión:** Todo el cancionero disponible en un solo lugar, pensado para acceder rápido sin depender de carpetas físicas ni suscripciones.

## Requisitos

- Flutter 3.41 o posterior (Dart 3.11.4 o posterior).
- Android Studio o Android SDK instalado para compilar para Android.
- Java 17 o posterior.
- Un emulador Android o un teléfono con depuración USB para probar la app.

Comprueba que el entorno esté configurado con:

```bash
flutter doctor -v
```

Si Android solicita aceptar sus licencias:

```bash
flutter doctor --android-licenses
```

## Instalación y ejecución

Clona el repositorio y entra en la carpeta del proyecto:

```bash
git clone https://github.com/Lo32nz1/Cancionero.git
cd Cancionero
```

Descarga las dependencias y ejecuta la aplicación:

```bash
flutter pub get
flutter run
```

En Android, acepta el permiso de micrófono cuando quieras usar el afinador.

## Crear el APK para Android

Para generar un APK de entrega:

```bash
flutter build apk --release
```

El archivo se genera en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Para instalarlo en un teléfono conectado por USB con depuración activada:

```bash
flutter install
```

También se puede instalar el APK copiándolo al teléfono y abriéndolo desde allí.
Android puede pedir autorización para instalar aplicaciones desde esa fuente.

El proyecto actualmente firma la variante release con la clave de depuración.
Ese APK sirve para pruebas y entregas de evaluación, pero antes de publicar la
app en Google Play hay que configurar una clave de firma release propia.

## Comprobaciones

Ejecuta las pruebas y el analizador antes de entregar cambios:

```bash
flutter test
flutter analyze
```
