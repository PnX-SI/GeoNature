import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { ContactMapFormComponent } from '../../modules/contact/contact-map-form/contact-map-form.component';
import { HomeContentComponent } from '../components/home-content/home-content.component';
import { PageNotFoundComponent } from '../components/page-not-found/page-not-found.component';
import { AuthGuard } from '../components/auth/auth-guard.service';
import { LoginComponent } from '../components/login/login.component';
import { NavHomeComponent } from '../components/nav-home/nav-home.component';
import { ExportsComponent } from '../exports/exports.component';

// import { GnValidationModule } from '@validation/app/gnValidation.module';

//import { ValidationComponent } from '@validation/gnValidation.component';

const appRoutes: Routes = [
  { path: 'login',  component: LoginComponent},
  // uncomment to activate login
   { path: '', component: NavHomeComponent, canActivateChild: [AuthGuard],
     children: [
      { path: '', component: HomeContentComponent },
      { path: 'exports', loadChildren: '@geonature/core/exports/exports.module#ExportsModule'},
      { path: 'occtax', loadChildren: '@geonature/modules/contact/contact.module#ContactModule'},
      //{ path: 'validation',  component: ValidationComponent},
      //{ path: 'validation', loadChildren: '@validation/gnValidation.module#GnValidationModule'},
      //{ path: 'validation', loadChildren: '/home/florian/workspace/Ecrins/gn_module_validation/frontend/app/gnValidation.module#GnValidationModule'},
      { path: '**',  component: PageNotFoundComponent }

     ] },

];

@NgModule({
  imports: [RouterModule.forRoot(appRoutes, {useHash: true })],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
