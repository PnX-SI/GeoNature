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
import  { SharedModule }  from './components/shared.module'
import { ContactModule } from '../modules/contact/contact.module'

// Angular created component
import { AppComponent } from './app.component';
import { AppRoutingModule } from './routing/app-routing.module'; // RoutingModule
import { AccueilComponent } from './components/accueil/accueil.component';
import { SidenavItemsComponent } from './components/sidenav-items/sidenav-items.component';
import { PageNotFoundComponent } from './components/page-not-found/page-not-found.component';
import { MapComponent } from './components/map/map.component';


// Service
import { AppConfigs } from '../conf/app.configs';
import { MapService } from './services/map.service';
import { NavService } from './services/nav.service';
import { SigninComponent } from './components/auth/signin/signin.component';
import { AuthService } from './components/auth/auth.service';
import { AuthGuard } from './components/auth/auth-guard.service';


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
    SharedModule,
    ContactModule,
  ],
  declarations: [
    AppComponent,
    AccueilComponent,
    SidenavItemsComponent,
    PageNotFoundComponent,
    SigninComponent,
  ],
  providers: [NavService, MapService, AuthService, AuthGuard],
  bootstrap: [AppComponent],
})

export class AppModule { }