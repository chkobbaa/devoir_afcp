# Student management application

This repository contains a Flutter client (`auth/`) and a Spring Boot REST API (`rp/`).

## Run the backend

From the repository root, start the API with the included Maven wrapper and the local H2 database profile:

```powershell
cd rp
.\mvnw.bat spring-boot:run -Dspring-boot.run.profiles=local
```

The API listens at `http://localhost:8081`. The local profile uses an in-memory H2 database, so no separate MySQL setup is needed for a local demo.

## Run the Flutter client

In another terminal:

```powershell
cd auth
flutter pub get
flutter run -d chrome
```

The web client connects to the API at `http://localhost:8081`. For an Android emulator, the client uses `10.0.2.2:8081` to reach the host machine.
