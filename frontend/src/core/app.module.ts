// Angular core
import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import {HttpModule, Http} from '@angular/http';

// For Angular Dependencies
import 'hammerjs';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import { CdkTableModule } from '@angular/cdk';
import { FlexLayoutModule } from '@angular/flex-layout';
import { CarouselModule } from 'ngx-bootstrap/carousel';
import { ChartModule } from 'angular2-chartjs';
import {TranslateModule, TranslateLoader} from '@ngx-translate/core';
import {TranslateHttpLoader} from '@ngx-translate/http-loader';
import { ToastrModule } from 'ngx-toastr';

// Modules
import { GN2CommonModule }  from './GN2Common/GN2Common.module'
import { ContactModule } from '../modules/contact/contact.module'

// Angular created component
import { AppComponent } from './app.component';
import { AppRoutingModule } from './routing/app-routing.module'; // RoutingModule
import { HomeComponent } from './components/home/home.component';
import { SidenavItemsComponent } from './components/sidenav-items/sidenav-items.component';
import { PageNotFoundComponent } from './components/page-not-found/page-not-found.component';


// Service
import { AppConfig } from '../conf/app.config';
import { NavService } from './services/nav.service';
import { SigninComponent } from './components/auth/signin/signin.component';
import { AuthService } from './components/auth/auth.service';
import { AuthGuard } from './components/auth/auth-guard.service';
import { SideNavService } from './components/sidenav-items/sidenav.service';


// AoT requires an exported function for factories
export function HttpLoaderFactory(http: Http) {
    return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}
@NgModule({
  imports: [
    BrowserModule,
    HttpModule,
    BrowserAnimationsModule,
    CdkTableModule,
    FlexLayoutModule,
    AppRoutingModule,
    CarouselModule.forRoot(),
    ChartModule,
    ToastrModule.forRoot(),
    GN2CommonModule,
    ContactModule,
  ],
  declarations: [
    AppComponent,
    HomeComponent,
    SidenavItemsComponent,
    PageNotFoundComponent,
    SigninComponent,
  ],
  providers: [NavService, AuthService, AuthGuard, SideNavService],
  bootstrap: [AppComponent],
})

export class AppModule { }