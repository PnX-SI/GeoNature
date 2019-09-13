import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { MatTabsModule } from "@angular/material/tabs";
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
//components
import { ValidationComponent } from "./components/validation.component";
import { ValidationSyntheseListComponent } from "./components/validation-synthese-list/validation-synthese-list.component";
import { ValidationDataService } from "./services/data.service";
import { ValidationSyntheseCarteComponent } from "./components/validation-synthese-carte/validation-synthese-carte.component";
import { ValidationPopupComponent } from "./components/validation-popup/validation-popup.component";
import { ValidationDefinitionsComponent } from "./components/validation-definitions/validation-definitions.component";
import { ValidationModalInfoObsComponent } from "./components/validation-modal-info-obs/validation-modal-info-obs.component";
// import { NomenclatureComponent } from "@geonature_common/form/nomenclature/nomenclature.component";
//services
import { DynamicFormService } from "@geonature_common/form/dynamic-form/dynamic-form.service";
import { SyntheseDataService } from "@geonature_common/form/synthese-form/synthese-data.service";
import { SyntheseFormService } from "@geonature_common/form/synthese-form/synthese-form.service";
import { TaxonAdvancedStoreService } from "@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service";

// my module routing
const routes: Routes = [{ path: "", component: ValidationComponent }];

@NgModule({
  declarations: [
    ValidationComponent,
    ValidationSyntheseListComponent,
    ValidationSyntheseCarteComponent,
    ValidationPopupComponent,
    ValidationDefinitionsComponent,
    ValidationModalInfoObsComponent
  ],

  imports: [
    GN2CommonModule,
    RouterModule.forChild(routes),
    CommonModule,
    MatTabsModule,
    NgbModule
  ],
  entryComponents: [ValidationModalInfoObsComponent],

  providers: [
    SyntheseDataService,
    ValidationDataService,
    SyntheseFormService,
    DynamicFormService,
    // NomenclatureComponent,
    TaxonAdvancedStoreService
  ],

  bootstrap: []
})
export class GeonatureModule {}
