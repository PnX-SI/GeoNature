#!/bin/bash

# backend
black --config pyproject.toml backend/geonature contrib/*/backend

# frontend
cd frontend
source ~/.nvm/nvm.sh
nvm use
npm run format
cd ..
