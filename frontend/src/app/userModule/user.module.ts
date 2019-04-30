import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';

const routes: Routes = [/*{ path: '', component: SyntheseComponent }*/];

@NgModule({
  imports: [RouterModule.forChild(routes), GN2CommonModule, CommonModule],
  declarations: [
    
  ],
  entryComponents: [
    
  ],
  providers: [
    
  ]
})
export class UserModule {}
