// Angular core
import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { HttpClient } from '@angular/common/http';

import { HttpClientModule, HttpClientXsrfModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { HttpModule, Http } from '@angular/http';

// For Angular Dependencies
import 'hammerjs';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { FlexLayoutModule } from '@angular/flex-layout';
import { ChartModule } from 'angular2-chartjs';
import { TranslateModule, TranslateLoader, TranslateService } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { ToastrModule } from 'ngx-toastr';

// Modules
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

// Angular created component
import { AppComponent } from './app.component';
import { routing } from './routing/app-routing.module'; // RoutingModule
import { HomeContentComponent } from './components/home-content/home-content.component';
import { SidenavItemsComponent } from './components/sidenav-items/sidenav-items.component';
import { PageNotFoundComponent } from './components/page-not-found/page-not-found.component';
import { LoginComponent } from './components/login/login.component';
import { NavHomeComponent } from './components/nav-home/nav-home.component';

// Custom component (footer, presentation etc...)
import { FooterComponent } from '../custom/components/footer/footer.component';
import { IntroductionComponent } from '../custom/components/introduction/introduction.component';

// Service
import { AppConfig } from '../conf/app.config';
import { AuthService } from './components/auth/auth.service';
import { CookieService } from 'ng2-cookies';
import { AuthGuard, ModuleGuardService } from '@geonature/routing/routes-guards.service';
import { ModuleService } from './services/module.service';
import { CruvedStoreService } from './services/cruved-store.service';
import { SideNavService } from './components/sidenav-items/sidenav-service';

import { MyCustomInterceptor } from './services/http.interceptor';
import { GlobalSubService } from './services/global-sub.service';
// AoT requires an exported function for factories
export function HttpLoaderFactory(http: Http) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

@NgModule({
  imports: [
    BrowserModule,
    HttpModule,
    HttpClientModule,
    BrowserAnimationsModule,
    FlexLayoutModule,
    routing,
    ChartModule,
    ToastrModule.forRoot(),
    GN2CommonModule,
    TranslateModule.forRoot({
      loader: {
        provide: TranslateLoader,
        useFactory: HttpLoaderFactory,
        deps: [Http]
      }
    })
  ],
  declarations: [
    AppComponent,
    HomeContentComponent,
    SidenavItemsComponent,
    PageNotFoundComponent,
    LoginComponent,
    NavHomeComponent,
    FooterComponent,
    IntroductionComponent
  ],
  providers: [
    AuthService,
    AuthGuard,
    ModuleService,
    GlobalSubService,
    CookieService,
    HttpClient,
    ModuleGuardService,
    SideNavService,
    CruvedStoreService,
    { provide: HTTP_INTERCEPTORS, useClass: MyCustomInterceptor, multi: true }
  ],
  bootstrap: [AppComponent]
})
export class AppModule {}
