import { NgModule } from "@angular/core";
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { ValidationComponent } from "./components/validation.component";
import { ValidationSyntheseListComponent } from "./components/validation-synthese-list/validation-synthese-list.component";
import { ValidationSyntheseCarteComponent } from "./components/validation-synthese-carte/validation-synthese-carte.component";
import { ValidationPopupComponent } from "./components/validation-popup/validation-popup.component";
import { ValidationDefinitionsComponent } from "./components/validation-definitions/validation-definitions.component";
//import { ValidationSearchComponent } from "./components/validation-search/validation-search.component";
import { ValidationSearchComponent } from "./components/validation-search/validation-search.component";
import { ValidationTaxonAdvancedModalComponent } from "./components/validation-search/validation-taxon-advanced/validation-taxon-advanced.component";
import { TreeModule } from 'angular-tree-component';
import { ValidationModalInfoObsComponent } from './components/validation-modal-info-obs/validation-modal-info-obs.component';
import { ValidationTaxonAdvancedStoreService } from "./components/validation-search/validation-taxon-advanced/validation-taxon-advanced-store.service";
import { DynamicFormService } from '@geonature_common/form/dynamic-form/dynamic-form.service';
import { DataService } from "./services/data.service";
import { FormService } from "./services/form.service";
import { HttpClient } from '@angular/common/http';
import { MatTabsModule } from '@angular/material/tabs';
import { NomenclatureComponent } from '@geonature_common/form/nomenclature/nomenclature.component';

// my module routing
const routes: Routes = [
  { path: '', component: ValidationComponent }
];

@NgModule({
  declarations: [
    ValidationComponent,
    ValidationSyntheseListComponent,
    ValidationSyntheseCarteComponent,
    ValidationPopupComponent,
    ValidationDefinitionsComponent,
    ValidationSearchComponent,
    ValidationTaxonAdvancedModalComponent,
    ValidationModalInfoObsComponent
  ],

  imports: [
    GN2CommonModule, 
    RouterModule.forChild(routes), 
    CommonModule, 
    TreeModule,
    MatTabsModule
  ],

  entryComponents: [
    ValidationTaxonAdvancedModalComponent,
    ValidationModalInfoObsComponent
  ],

  providers: [
    DataService,
    FormService,
    ValidationTaxonAdvancedStoreService,
    DynamicFormService,
    NomenclatureComponent
  ],

  bootstrap: []
})

export class GeonatureModule {}
