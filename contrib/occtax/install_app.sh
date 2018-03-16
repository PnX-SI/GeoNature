#!/bin/bash

if [ ! -f frontend/app/occtax.config.ts ]; then
  cp frontend/app/occtax.config.ts.sample frontend/app/occtax.config.ts
fi