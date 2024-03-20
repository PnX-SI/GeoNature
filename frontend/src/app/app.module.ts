// Angular core
import { BrowserModule } from '@angular/platform-browser';
import { NgModule, APP_INITIALIZER, Injector } from '@angular/core';

import { HttpClientModule, HttpClient, HTTP_INTERCEPTORS } from '@angular/common/http';

// For Angular Dependencies
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { TranslateModule, TranslateLoader } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { ToastrModule, ToastrService } from 'ngx-toastr';

// Modules
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

// Angular created components/modules
import { AppComponent } from './app.component';
import { routing } from './routing/app-routing.module'; // RoutingModule
import { HomeContentComponent } from './components/home-content/home-content.component';
import { SidenavItemsComponent } from './components/sidenav-items/sidenav-items.component';
import { PageNotFoundComponent } from './components/page-not-found/page-not-found.component';
import { NavHomeComponent } from './components/nav-home/nav-home.component';
import { LoginModule } from './modules/login/login.module';
import { NotificationComponent } from './components/notification/notification.component';
import { RulesComponent } from './components/notification/rules/rules.component';

// Custom component (footer, presentation etc...)
import { FooterComponent } from './components/footer/footer.component';
import { IntroductionComponent } from './components/introduction/introduction.component';

// Service
import { AuthService } from './components/auth/auth.service';
import { CookieService } from 'ng2-cookies';
import { NgChartsModule } from 'ng2-charts';

// PublicAccessGuard,

import { AuthGuard } from '@geonature/routing/auth-guard.service';
import { ModuleGuardService } from '@geonature/routing/module-guard.service';
import { ModuleService } from './services/module.service';
import { CruvedStoreService } from './GN2CommonModule/service/cruved-store.service';
import { SideNavService } from './components/sidenav-items/sidenav-service';
import { ConfigService } from './services/config.service';

import { MyCustomInterceptor } from './services/http.interceptor';
import { UnauthorizedInterceptor } from './services/unauthorized.interceptor';
import { GlobalSubService } from './services/global-sub.service';
export function createTranslateLoader(http: HttpClient) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}
import { UserDataService } from './userModule/services/user-data.service';
import { NotificationDataService } from './components/notification/notification-data.service';

import { UserPublicGuard } from '@geonature/modules/login/routes-guard.service';

export function loadConfig(injector) {
  const configService = injector.get(ConfigService);
  return configService._getConfig().toPromise();
}

export function initApp(injector) {
  return async () => {
    await loadConfig(injector);

    const configService = injector.get(ConfigService);

    let favicon = document.getElementById('favicon') as HTMLLinkElement;
    favicon.type = 'image/x-icon';
    favicon.href = `${configService.API_ENDPOINT}${configService.STATIC_URL}/images/favicon.ico`;

    let style = document.createElement('link');
    style.type = 'text/css';
    style.rel = 'stylesheet';
    style.href = `${configService.API_ENDPOINT}${configService.STATIC_URL}/css/frontend.css`;
    document.getElementsByTagName('head')[0].append(style);
  };
}

@NgModule({
  imports: [
    BrowserModule,
    HttpClientModule,
    BrowserAnimationsModule,
    routing,
    NgChartsModule,
    ToastrModule.forRoot({
      positionClass: 'toast-top-center',
      tapToDismiss: true,
      timeOut: 3000,
    }),
    GN2CommonModule,
    TranslateModule.forRoot({
      loader: {
        provide: TranslateLoader,
        useFactory: createTranslateLoader,
        deps: [HttpClient],
      },
    }),
    LoginModule,
  ],
  declarations: [
    AppComponent,
    HomeContentComponent,
    SidenavItemsComponent,
    PageNotFoundComponent,
    NavHomeComponent,
    FooterComponent,
    IntroductionComponent,
    NotificationComponent,
    RulesComponent,
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
    UserPublicGuard,
    SideNavService,
    CruvedStoreService,
    UserDataService,
    NotificationDataService,
    ConfigService,
    { provide: HTTP_INTERCEPTORS, useClass: MyCustomInterceptor, multi: true },
    { provide: HTTP_INTERCEPTORS, useClass: UnauthorizedInterceptor, multi: true },
    {
      provide: APP_INITIALIZER,
      useFactory: initApp,
      deps: [Injector],
      multi: true,
    },
  ],
  bootstrap: [AppComponent],
})
export class AppModule {}
