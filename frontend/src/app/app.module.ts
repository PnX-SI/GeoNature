// Angular core
import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { Observable, of } from 'rxjs';

import { HttpClientModule, HttpClient, HttpClientXsrfModule, HTTP_INTERCEPTORS } from '@angular/common/http';

// For Angular Dependencies
import 'hammerjs';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { FlexLayoutModule } from '@angular/flex-layout';
import { ChartModule } from 'angular2-chartjs';
import { TranslateModule, TranslateLoader, TranslateService } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { ToastrModule, ToastrService, Toast } from 'ngx-toastr';

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

import * as contentCn from '../assets/i18n/cn.json';
import * as contentEn from '../assets/i18n/en.json';
import * as contentFr from '../assets/i18n/fr.json';

const TRANSLATIONS = {
  cn: contentCn,
  en: contentEn,
  fr: contentFr
};

export class TranslateUniversalLoader implements TranslateLoader {
  getTranslation(lang: string): Observable<any> {
    return of(TRANSLATIONS[lang].default);
  }
}

@NgModule({
  imports: [
    BrowserModule,
    HttpClientModule,
    BrowserAnimationsModule,
    FlexLayoutModule,
    routing,
    ChartModule,
    ToastrModule.forRoot({
      positionClass: 'toast-top-center',
      tapToDismiss: true,
      timeOut: 3000
    }),
    GN2CommonModule,
    TranslateModule.forRoot({
      loader: {
        provide: TranslateLoader,
        useClass: TranslateUniversalLoader
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
    ToastrService,
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
