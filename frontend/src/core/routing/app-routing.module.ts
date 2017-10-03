import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { ContactMapFormComponent } from '../../modules/contact/contact-map-form/contact-map-form.component';
import { HomeComponent } from '../components/home/home.component';
import { PageNotFoundComponent } from '../components/page-not-found/page-not-found.component';
import { ContactMapListComponent } from '../../modules/contact/contact-map-list/contact-map-list.component';
import { ContactMapInfoComponent } from '../../modules/contact/contact-map-info/contact-map-info.component';
import { AuthGuard } from '../components/auth/auth-guard.service';


const appRoutes: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  { path: 'home', component: HomeComponent },
  { path: 'contact', component: ContactMapListComponent},
  { path: 'contact-form', component: ContactMapFormComponent },
  { path: 'contact-form/:id', component: ContactMapFormComponent, pathMatch: 'full' },
  { path: 'contact/info/:id', component: ContactMapInfoComponent, pathMatch: 'full' },
  // { path: 'contact-faune', component: ContactComponent, canActivate: [AuthGuard]},
  { path: '**', component: PageNotFoundComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(appRoutes, {useHash: true })],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
