import { enableProdMode } from '@angular/core';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';

// import { AppModule } from '@geonature/app.module';
import { AppModule } from './app/app.module';
import { AppConfig } from './conf/app.config';

if (AppConfig.FRONTEND.PROD_MOD) {
  enableProdMode();
}

platformBrowserDynamic().bootstrapModule(AppModule);
