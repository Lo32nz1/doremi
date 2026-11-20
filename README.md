# DOREMI

DOREMI es una aplicación multiplataforma para organizar y leer canciones con
acordes. Incluye biblioteca e historial de canciones, setlists, controles de
lectura y un afinador cromático para guitarra, bajo, ukelele y violín.

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
