import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { AdminComponent } from './admin.component';
import { Routes, RouterModule } from '@angular/router';
import { DatasetListComponent } from './meta/datasets/dataset-list.component';
import { DatasetFormComponent } from './meta/datasets/dataset-form.component';
import { AfListComponent } from './meta/af/af-list.component';
import { AfFormComponent } from './meta/af/af-form.component';
import { NomenclatureComponent } from './nomenclatures/nomenclature.component';
import { ActorComponent } from './meta/actors/actors.component';
import { AdminStoreService } from './services/admin-store.service';

const routes: Routes = [
  { path: '', component: AdminComponent },
  { path: 'dataset', component: DatasetFormComponent },
  { path: 'datasets', component: DatasetListComponent },
  { path: 'dataset/:id', component: DatasetFormComponent },
  { path: 'afs', component: AfListComponent },
  { path: 'af', component: AfFormComponent },
  { path: 'af/:id', component: AfFormComponent },
  { path: 'nomenclatures', component: NomenclatureComponent }
];

@NgModule({
  imports: [CommonModule, GN2CommonModule, RouterModule.forChild(routes)],
  exports: [],
  declarations: [
    AdminComponent,
    DatasetListComponent,
    DatasetFormComponent,
    AfListComponent,
    AfFormComponent,
    NomenclatureComponent,
    ActorComponent
  ],
  providers: [AdminStoreService]
})
export class AdminModule {}
