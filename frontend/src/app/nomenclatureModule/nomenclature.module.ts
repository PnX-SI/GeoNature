import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NomenclatureComponent } from './nomenclature.component';
import { Routes, RouterModule } from '@angular/router';

const routes: Routes = [{ path: '', component: NomenclatureComponent }];

@NgModule({
  imports: [CommonModule, RouterModule.forChild(routes)],
  exports: [],
  declarations: [NomenclatureComponent],
  providers: []
})
export class NomenclatureModule {}
