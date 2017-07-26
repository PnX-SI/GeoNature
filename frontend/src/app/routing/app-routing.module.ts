import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { ContactFauneComponent } from '../apps/contact-faune/contact-faune.component';
import { ContactFloreComponent } from '../apps/contact-flore/contact-flore.component';
import { AccueilComponent } from '../apps/accueil/accueil.component';
import { PageNotFoundComponent } from '../components/page-not-found/page-not-found.component';
import { AuthGuard } from '../components/auth/auth-guard.service';


const appRoutes: Routes = [
  { path: '', redirectTo: '/accueil', pathMatch: 'full' },
  { path: 'accueil', component: AccueilComponent },
  { path: 'contact-faune', component: ContactFauneComponent, canActivate: [AuthGuard]},
  { path: 'contact-flore', component: ContactFloreComponent, canActivate: [AuthGuard]},
  { path: '**', component: PageNotFoundComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(appRoutes)],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
