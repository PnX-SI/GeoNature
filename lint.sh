#!/usr/bin/env bash

# backend
black .

# frontend
cd frontend
source ~/.nvm/nvm.sh
nvm use
npm run format
cd ..
