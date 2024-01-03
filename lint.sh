#!/usr/bin/env bash

# backend
black . --line-length 100

# frontend
cd frontend
source ~/.nvm/nvm.sh
nvm use
npm run format
cd ..
