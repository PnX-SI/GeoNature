import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { SyntheseComponent } from './synthese.component';
import { SyntheseListComponent } from './synthese-results/synthese-list/synthese-list.component';
import { SyntheseCarteComponent } from './synthese-results/synthese-carte/synthese-carte.component';
import { SyntheseSearchComponent } from './synthese-search/synthese-search.component';
import { DataService } from './services/data.service';
import { FormService } from './services/form.service';

const routes: Routes = [{ path: '', component: SyntheseComponent }];

@NgModule({
  imports: [RouterModule.forChild(routes), GN2CommonModule, CommonModule],
  declarations: [
    SyntheseComponent,
    SyntheseListComponent,
    SyntheseCarteComponent,
    SyntheseSearchComponent
  ],
  providers: [DataService, FormService]
})
export class SyntheseModule {}
