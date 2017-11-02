import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { ContactMapFormComponent } from '../../modules/contact/contact-map-form/contact-map-form.component';
import { HomeContentComponent } from '../components/home-content/home-content.component';
import { PageNotFoundComponent } from '../components/page-not-found/page-not-found.component';
import { ContactMapListComponent } from '../../modules/contact/contact-map-list/contact-map-list.component';
import { ContactMapInfoComponent } from '../../modules/contact/contact-map-info/contact-map-info.component';
import { AuthGuard } from '../components/auth/auth-guard.service';
import { LoginComponent } from '../components/login/login.component';
import { NavHomeComponent } from '../components/nav-home/nav-home.component';
import { ExportsComponent } from '../exports/exports.component';

const appRoutes: Routes = [
  { path: 'login',  component: LoginComponent},
  // uncomment to activate login
   { path: '', component: NavHomeComponent, canActivateChild: [AuthGuard],
     children: [
      { path: '', component: HomeContentComponent },
      { path: 'exports', loadChildren: 'core/exports/exports.module#ExportsModule'},
      { path: 'contact', loadChildren: 'modules/contact/contact.module#ContactModule'},
      { path: '**',  component: PageNotFoundComponent }

     ] },

];

@NgModule({
  imports: [RouterModule.forRoot(appRoutes, {useHash: true })],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
