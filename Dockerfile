# Image de base
FROM python:3.6-alpine

LABEL maintainer="Cathalina"


# Répertoire de travail
WORKDIR /opt

# Installation de Flask 1.1.2
RUN pip install --no-cache-dir flask==1.1.2

# Copie des fichiers de l'application dans le conteneur
#COPY . .
COPY app.py .
COPY templates ./templates
COPY static ./static

# Exposer le port 8080
EXPOSE 8080

# Valeurs transmises par Jenkins lors du build
ARG APP_VERSION=1.1
ARG ODOO_URL=https://www.odoo.com/
ARG PGADMIN_URL=https://www.pgadmin.org/

# Variables d'environnement disponibles dans le conteneur
ENV APP_VERSION=${APP_VERSION}
ENV ODOO_URL=${ODOO_URL}
ENV PGADMIN_URL=${PGADMIN_URL}


# Lancer l'application dans l'ENTRYPOINT
ENTRYPOINT ["python", "app.py"]
