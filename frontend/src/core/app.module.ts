// Angular core
import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { HttpClient } from '@angular/common/http';

import { HttpClientModule, HttpClientXsrfModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import {HttpModule, Http} from '@angular/http';


// For Angular Dependencies
import 'hammerjs';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import { FlexLayoutModule } from '@angular/flex-layout';
import { ChartModule } from 'angular2-chartjs';
import {TranslateModule, TranslateLoader, TranslateService} from '@ngx-translate/core';
import {TranslateHttpLoader} from '@ngx-translate/http-loader';
import { ToastrModule } from 'ngx-toastr';

// Modules
import { GN2CommonModule } from './GN2Common/GN2Common.module';

// Angular created component
import { AppComponent } from './app.component';
import { AppRoutingModule } from './routing/app-routing.module'; // RoutingModule
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
import { NavService } from './services/nav.service';
import { SigninComponent } from './components/auth/signin/signin.component';
import { AuthService } from './components/auth/auth.service';
import { AuthGuard } from './components/auth/auth-guard.service';
import { SideNavService } from './components/sidenav-items/sidenav.service';
import { MapListService } from './GN2Common/map-list/map-list.service';
import { CookieService } from 'ng2-cookies';


// TEST
import { GnValidationModule } from '@validation/gnValidation.module';

import { MyCustomInterceptor } from './services/http.interceptor';
// AoT requires an exported function for factories
export function HttpLoaderFactory(http: Http) {
    return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

@NgModule({
  imports: [
    BrowserModule,
    HttpModule,
    HttpClientModule,
    GnValidationModule,
    // HttpClientXsrfModule.withOptions({
    //   cookieName: 'token',
    //   headerName: 'token'
    // }),
    BrowserAnimationsModule,
    FlexLayoutModule,
    AppRoutingModule,
    ChartModule,
    ToastrModule.forRoot(),
    GN2CommonModule,
    TranslateModule.forRoot({
      loader: {
          provide: TranslateLoader,
          useFactory: HttpLoaderFactory,
          deps: [Http]
      }
  }),
  ],
  declarations: [
    AppComponent,
    HomeContentComponent,
    SidenavItemsComponent,
    PageNotFoundComponent,
    SigninComponent,
    LoginComponent,
    NavHomeComponent,
    FooterComponent,
    IntroductionComponent
  ],
  providers: [NavService, AuthService, AuthGuard, SideNavService, CookieService, HttpClient,
    { provide: HTTP_INTERCEPTORS, useClass: MyCustomInterceptor, multi: true } ],
  bootstrap: [AppComponent],
})

export class AppModule {

 }
