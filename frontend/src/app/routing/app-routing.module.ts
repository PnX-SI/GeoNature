import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { HomeContentComponent } from '../components/home-content/home-content.component';
import { PageNotFoundComponent } from '../components/page-not-found/page-not-found.component';
import { AuthGuard, ModuleGuardService } from '@geonature/routing/routes-guards.service';
import { LoginComponent } from '../components/login/login.component';
import { NavHomeComponent } from '../components/nav-home/nav-home.component';


const defaultRoutes: Routes = [
  { path: 'login',  component: LoginComponent},
  
   { path: '', component: NavHomeComponent, canActivateChild: [AuthGuard],
     children: [
      
        {
          path: 'occtax',
          loadChildren: () => import('/home/theo/workspace/GeoNature/contrib/occtax/frontend/app/gnModule.module').then(m => m.GeonatureModule),
          canActivate: [ModuleGuardService],
          data: { module_code: 'OCCTAX' }  },
        
        {
          path: 'occhab',
          loadChildren: () => import('/home/theo/workspace/GeoNature/contrib/gn_module_occhab/frontend/app/gnModule.module').then(m => m.GeonatureModule),
          canActivate: [ModuleGuardService],
          data: { module_code: 'OCCHAB' }  },
          

          {
            path: 'validation',
            loadChildren: () => import('/home/theo/workspace/GeoNature/contrib/gn_module_validation/frontend/app/gnModule.module').then(m => m.GeonatureModule),
            canActivate: [ModuleGuardService],
            data: { module_code: 'VALIDATION' }  },
        
      { path: '', component: HomeContentComponent },
      { path: 'synthese',data: { module_code: 'synthese' }, canActivate: [ModuleGuardService], loadChildren: () => import('@geonature/syntheseModule/synthese.module').then(m => m.SyntheseModule)},
      { path: 'metadata',data: { module_code: 'metadata' }, canActivate: [ModuleGuardService], loadChildren: () => import('@geonature/metadataModule/metadata.module').then(m => m.MetadataModule)},
      {
        path: 'admin',
        loadChildren: () => import('@geonature/adminModule/admin.module').then(m => m.AdminModule),
        canActivate: [ModuleGuardService],
        data: { module_code: 'admin' }
      },
      
      { path: '**',  component: PageNotFoundComponent },
     ] },
];


export const routing = RouterModule.forRoot(defaultRoutes, {useHash: true });