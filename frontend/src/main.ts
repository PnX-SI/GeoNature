import { enableProdMode } from '@angular/core';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';

import { AppModule } from '@geonature/core/app.module';
<<<<<<< HEAD
import { environment } from './environments/environment';
import { AppConfig } from './conf/app.config';

if (AppConfig.PROD_MOD) {
=======
import { AppConfig } from './conf/app.config';

if (AppConfig.FRONTEND.PROD_MOD) {
>>>>>>> install_all
  enableProdMode();
}

platformBrowserDynamic().bootstrapModule(AppModule);
