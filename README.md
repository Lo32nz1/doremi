# DOREMI

DOREMI es una aplicación para android y próximamente para las demás plataforma, la misma sirve para organizar, leer canciones con
acordes, afinar los instrumentos, etc. 
En lo que se centra la aplicación es en intentar facilitar el uso, y la centralización de las canciones de los músicos, conteniendo las canciones con información importante para el músico, como los acordes, expecificaciones importantes en las canciones, creación de canciones, formateo de las mismas, transpocisión músical, entre otras necesidades.
Se centraliza en poder enfocar todo en un punto central donde no se necesite pagar o tener muchas aplicaciones distintas 

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
