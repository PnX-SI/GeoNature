import { InjectionToken } from '@angular/core';
// Although the ApplicationConfig interface plays no role in dependency injection,
// it supports typing of the configuration object within the class.
export class AppConfig {
  appName: string;
  defaultLanguage: string;
  API_ENDPOINT: string;
  API_TAXHUB_ENDPOINT: string;
}

// Configuration values for our app
export const CONFIG: AppConfig = {
  appName: 'Geonature 2',
  defaultLanguage: 'en', // value obligatory 'en' or 'fr'
  API_ENDPOINT:'http://127.0.0.1:5050/',
  API_TAXHUB_ENDPOINT: 'http:127.0.0.1:5000/api',
};

// Create a config token to avoid naming conflicts
export let APP_CONFIG = new InjectionToken<AppConfig>('app.config');
