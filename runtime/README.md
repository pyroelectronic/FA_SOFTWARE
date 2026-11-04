# Runtime / Profile

Optionale, **freigegebene** Runtimes statt globalem Blumenstrauß. Hierhin gehören künftig geprüfte Node-RED-/Mosquitto-/InfluxDB-/Python-/PyTorch-/TensorFlow-Containerrezepte und kompatible Image-/Package-Versionen. Keine `latest`-Produktion und kein ungeprüftes All-in-one-Image.

`profiles/lab/` kann temporäre Lehrumgebungen enthalten; `profiles/customer/` eine reduzierte, abgesicherte Auswahl. Compose-Dateien können auch direkt bei einer Anwendung liegen. Bereits laufende Host-Dienste nicht ohne Migrationsplan doppelt starten.
