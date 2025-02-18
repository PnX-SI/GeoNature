#! /bin/bash

cd frontend
cp src/custom/components/footer/footer.component.ts.sample src/custom/components/footer/footer.component.ts
cp src/custom/components/footer/footer.component.html.sample src/custom/components/footer/footer.component.html
cp src/custom/components/introduction/introduction.component.ts.sample src/custom/components/introduction/introduction.component.ts
cp src/custom/components/introduction/introduction.component.html.sample src/custom/components/introduction/introduction.component.html

echo "Installation des paquets Npm"


cd /GeoNature/frontend
npm install . --legacy-peer-deps


echo "Lancement du frontend..."

#npm rebuild node-sass --force
npm run docker_start
