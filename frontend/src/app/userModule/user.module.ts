import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
//Components
import { UserComponent } from './user.component'

const routes: Routes = [{ path: '', component: UserComponent }];

@NgModule({
  imports: [RouterModule.forChild(routes), GN2CommonModule, CommonModule],
  declarations: [
    UserComponent
  ],
  providers: [
    
  ]
})
export class UserModule {}
