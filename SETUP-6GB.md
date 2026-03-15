# 🚀 SETUP REAL PARA 6GB RAM - OPCIÓN B (Build Local)

**IMPORTANTE**: Este setup compila las dependencias EN TU MÁQUINA primero, luego Docker solo orquesta.

**Tiempo total**: ~40 minutos
**RAM requerida**: 6GB mínimo (3GB Docker + 3GB compilación)

---

## PASO 0: PREPARAR MÁQUINA

### Verificar Docker
```bash
docker --version
docker-compose --version
```

### Verificar RAM disponible
```bash
# Linux
free -h

# macOS
sysctl hw.memsize

# Windows (PowerShell)
Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory
```

### Liberar espacio (importante!)
```bash
# Limpiar Docker
docker system prune -a --volumes

# Necesitas mínimo 50GB libres
```

---

## PASO 1: CLONAR REPOSITORIO

```bash
cd ~/projects  # O tu carpeta
git clone https://github.com/biopelayo/opencb-docker-stack.git
cd opencb-docker-stack
```

---

## PASO 2: CONFIGURAR PARA 6GB

Edita `.env`:

```bash
# CAMBIAR ESTO (es lo crítico para 6GB)
OPENCGA_JAVA_MEMORY=2g        # ← IMPORTANTE: reducir de 8g a 2g

# Mantener igual
MONGO_ROOT_USER=opencb
MONGO_ROOT_PASSWORD=opencb_secure_pass
LOG_LEVEL=INFO
```

---

## PASO 3: COMPILAR DEPENDENCIAS LOCALMENTE

### 3.1 Instalar Maven en tu máquina

**macOS:**
```bash
brew install maven
mvn --version
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install maven
mvn --version
```

**Windows:**
- Descargar de https://maven.apache.org/download.cgi
- O usar: `choco install maven`

### 3.2 Compilar dependencias (EN TU MÁQUINA, NO EN DOCKER)

Este es el "pre-build local" de la OPCIÓN B:

```bash
#!/bin/bash
set -e

echo "=== Building OpenCB Dependencies Locally ==="

# Si no existe, crear directorio
mkdir -p ~/opencb-build
cd ~/opencb-build

echo "1/5: Building java-common-libs..."
if [ ! -d "java-common-libs" ]; then
  git clone -b develop https://github.com/opencb/java-common-libs.git
fi
cd java-common-libs
mvn clean install -DskipTests -q
cd ..
echo "✓ java-common-libs done"

echo "2/5: Building biodata..."
if [ ! -d "biodata" ]; then
  git clone -b develop https://github.com/opencb/biodata.git
fi
cd biodata
mvn clean install -DskipTests -q
cd ..
echo "✓ biodata done"

echo "3/5: Building datastore..."
if [ ! -d "datastore" ]; then
  git clone -b develop https://github.com/opencb/datastore.git
fi
cd datastore
mvn clean install -DskipTests -q
cd ..
echo "✓ datastore done"

echo "4/5: Building cellbase..."
if [ ! -d "cellbase" ]; then
  git clone -b develop https://github.com/opencb/cellbase.git
fi
cd cellbase
mvn clean install -DskipTests -q
cd ..
echo "✓ cellbase done"

echo "5/5: Building opencga..."
if [ ! -d "opencga" ]; then
  git clone -b develop https://github.com/opencb/opencga.git
fi
cd opencga
mvn clean install -DskipTests -q
echo "✓ opencga done"

echo ""
echo "========================================"
echo "✓ ALL DEPENDENCIES COMPILED!"
echo "✓ Maven cache is in ~/.m2/repository"
echo "========================================"
```

**Copia y pega esto en tu terminal:**

```bash
# Primero guarda como script
cat > ~/build-opencb-deps.sh << 'EOF'
[PEGA EL CONTENIDO ARRIBA]
EOF

chmod +x ~/build-opencb-deps.sh

# Ejecuta (ESTO TARDA ~30 MINUTOS)
~/build-opencb-deps.sh
```

**¿Qué hace?**
- Clona 5 repositorios
- Compila cada uno con Maven
- Guarda en `~/.m2/repository` (tu cache local de Maven)
- **Ahora Docker no necesita compilar nada!**

---

## PASO 4: ACTUALIZAR DOCKERFILE PARA USAR CACHE

Reemplaza el Dockerfile actual por este (optimizado para 6GB):

```dockerfile
FROM openjdk:8-jdk-slim

ENV OPENCGA_HOME=/opt/opencga \
    JAVA_OPTS="-Xmx2g -Xms1g"

RUN apt-get update && apt-get install -y \
    curl netcat git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/opencga

# Copiar solo el build final (NO compilar en Docker)
COPY --chown=1000:1000 opencga-build/ .

RUN mkdir -p logs && chmod -R 755 bin

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

---

## PASO 5: COPIAR BUILD A DOCKER

Una vez compilado localmente:

```bash
# En tu carpeta opencb-docker-stack:
mkdir -p opencga-build

# Copiar el build de OpenCGA compilado
cp -r ~/opencb-build/opencga/build/* ./opencga-build/
```

---

## PASO 6: BUILD DOCKER IMAGE (AHORA SÍ)

```bash
cd ~/opencb-docker-stack

# Build de la imagen (RÁPIDO, 2-3 minutos)
docker-compose build
```

---

## PASO 7: INICIAR STACK

```bash
# Iniciar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f opencga
```

**Esperar a ver:**
```
[INFO] Starting OpenCGA REST server...
```

---

## PASO 8: VERIFICAR QUE FUNCIONA

```bash
# Esperar 30 segundos
sleep 30

# Test 1: OpenCGA API
curl http://localhost:8080/opencga/rest/v2/api/version

# Deberías ver algo como:
# {"apiVersion":"v2","version":"5.0.0",...}

# Test 2: MongoDB
docker-compose exec mongodb mongosh -u opencb -p opencb_secure_pass --eval "db.adminCommand('ping')"

# Test 3: OpenSearch
curl -u elastic:OpenSearch@123 http://localhost:9200/
```

---

## ⚠️ PROBLEMAS COMUNES CON 6GB

### Problema: "Java heap space"
**Solución:**
```bash
# Editar .env
OPENCGA_JAVA_MEMORY=1.5g  # Reducir más si es necesario
docker-compose restart opencga
```

### Problema: "Out of memory"
**Solución:**
```bash
# Limitar otros servicios en docker-compose.yml:
mongodb:
  mem_limit: 1g

opensearch:
  mem_limit: 1.5g

opencga:
  mem_limit: 2.5g
```

### Problema: Build tarda demasiado
**Solución:**
- Los builds posteriores son MUCHO más rápidos (Maven cache)
- Primera vez: 30 min
- Siguientes: 2-3 min

---

## 🎯 RESUMIDO - LOS 3 COMANDOS PRINCIPALES

```bash
# 1. Compilar dependencias localmente (solo PRIMERA VEZ)
~/build-opencb-deps.sh

# 2. Copiar a Docker
cp -r ~/opencb-build/opencga/build/* ./opencga-build/

# 3. Iniciar
docker-compose up -d
```

---

## ✅ CUANDO FUNCIONA

Verás:
- ✓ MongoDB en puerto 27017
- ✓ OpenSearch en puerto 9200  
- ✓ OpenCGA API en puerto 8080
- ✓ Adminer en puerto 8081

```bash
curl http://localhost:8080/opencga/rest/v2/api/version
```

**SI ESTO DEVUELVE JSON = ¡FUNCIONA!** 🎉

---

## 📞 SI ALGO FALLA

1. **Ver logs:**
```bash
docker-compose logs opencga
```

2. **Verificar memoria:**
```bash
docker stats
```

3. **Restart:**
```bash
docker-compose down
docker-compose up -d
```

---

**¿Problemas? Reporta los errores exactos y lo solucionamos juntos!**
