import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { ContactFormComponent } from '../../modules/contact/contact-form/contact-form.component';
import { HomeComponent } from '../components/home/home.component';
import { PageNotFoundComponent } from '../components/page-not-found/page-not-found.component';
import { ContactMapListComponent } from '../../modules/contact/contact-map-list/contact-map-list.component';
import { AuthGuard } from '../components/auth/auth-guard.service';


const appRoutes: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  { path: 'home', component: HomeComponent },
  { path: 'contact-form', component: ContactFormComponent },
  // { path: 'contact-faune', component: ContactComponent, canActivate: [AuthGuard]},
  { path: 'contact', component: ContactMapListComponent},
  { path: '**', component: PageNotFoundComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(appRoutes)],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
