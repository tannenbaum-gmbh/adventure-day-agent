#!/bin/bash

# Pull environment variable inline from local device and set in .env file
cp .azure/$AZURE_ENV_NAME/.env ./

# Run the healthcheck script
python azd-hooks/healthcheck.py
