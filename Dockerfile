# Image de base
FROM python:3.6-alpine

LABEL maintener="Cathalina"

ARG APP_VERSION
ARG ODOO_URL
ARG PGADMIN_URL

# Répertoire de travail
WORKDIR /opt

# Copie des fichiers de l'application dans le conteneur
COPY . .

# Installer le module Flask
RUN pip install --no-cache-dir flask
# Exposer le port 8080
EXPOSE 8080

# Créer les variables d'environnement 
#ENV ODOO_URL="https://www.odoo.com/"
#ENV PGADMIN_URL="https://www.pgadmin.org/"

ENV VERSION=${APP_VERSION}
ENV ODOO_URL=${ODOO_URL}
ENV PGADMIN_URL=${PGADMIN_URL}

# Lancer l'application dans l'ENTRYPOINT
ENTRYPOINT ["python", "app.py"]

