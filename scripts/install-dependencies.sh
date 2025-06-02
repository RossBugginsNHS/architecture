#!/bin/bash
# This script installs the necessary dependencies for the project.

bundle install || true

wget https://github.com/nhsuk/nhsuk-frontend/releases/download/v9.6.1/nhsuk-frontend-9.6.1.zip -O nhsuk-frontend.zip
unzip -o -d ./assets/nhsuk nhsuk-frontend.zip
rm nhsuk-frontend.zip

