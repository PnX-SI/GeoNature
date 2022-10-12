// Angular core
import { BrowserModule } from '@angular/platform-browser';
import { NgModule, APP_INITIALIZER } from '@angular/core';

import {
  HttpClientModule,
  HttpClient,
  HttpClientXsrfModule,
  HTTP_INTERCEPTORS,
} from '@angular/common/http';

// For Angular Dependencies
import 'hammerjs';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { FlexLayoutModule } from '@angular/flex-layout';
import { ChartModule } from 'angular2-chartjs';
import { TranslateModule, TranslateLoader, TranslateService } from '@ngx-translate/core';
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

// Custom component (footer, presentation etc...)
import { FooterComponent } from '../custom/components/footer/footer.component';
import { IntroductionComponent } from '../custom/components/introduction/introduction.component';

// Service
import { AuthService } from './components/auth/auth.service';
import { CookieService } from 'ng2-cookies';
import { ChartsModule } from 'ng2-charts';
import {
  AuthGuard,
  ModuleGuardService,
  PublicAccessGuard,
} from '@geonature/routing/routes-guards.service';
import { ModuleService } from './services/module.service';
import { CruvedStoreService } from './GN2CommonModule/service/cruved-store.service';
import { SideNavService } from './components/sidenav-items/sidenav-service';

import { MyCustomInterceptor } from './services/http.interceptor';
import { UnauthorizedInterceptor } from './services/unauthorized.interceptor';
import { GlobalSubService } from './services/global-sub.service';

export function createTranslateLoader(http: HttpClient) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}
import { UserDataService } from './userModule/services/user-data.service';
import { NotificationDataService } from './components/notification/notification-data.service';

// Config
import { APP_CONFIG_TOKEN, AppConfig } from '@geonature_config/app.config';

export function get_modules(moduleService: ModuleService) {
  return () => {
    return moduleService.fetchModules().toPromise();
  };
}

@NgModule({
  imports: [
    BrowserModule,
    HttpClientModule,
    BrowserAnimationsModule,
    FlexLayoutModule,
    routing,
    ChartModule,
    ChartsModule,
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
    UserDataService,
    PublicAccessGuard,
    NotificationDataService,
    { provide: APP_CONFIG_TOKEN, useValue: AppConfig },
    { provide: HTTP_INTERCEPTORS, useClass: MyCustomInterceptor, multi: true },
    { provide: HTTP_INTERCEPTORS, useClass: UnauthorizedInterceptor, multi: true },
    // { provide: APP_INITIALIZER, useFactory: get_cruved, deps: [CruvedStoreService], multi: true},
    { provide: APP_INITIALIZER, useFactory: get_modules, deps: [ModuleService], multi: true },
  ],
  bootstrap: [AppComponent],
})
export class AppModule {}
