import { NgModule } from  '@angular/core'
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { Routes, RouterModule } from '@angular/router';

// my module routing
const routes: Routes = [
  { path: '', component: myRootComponent },
];

@NgModule({
  declarations: [
     
  ],
  imports: [
    GN2CommonModule,
    RouterModule.forChild(routes),
  ],
  providers: [],
  bootstrap: []
})
export class GeonatureModule { 
}
