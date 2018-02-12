import { enableProdMode } from '@angular/core';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';

import { AppModule } from '@geonature/core/app.module';
import { environment } from './environments/environment';
import { AppConfig } from './conf/app.config';

if (AppConfig.PROD_MOD) {
  enableProdMode();
}

platformBrowserDynamic().bootstrapModule(AppModule);
