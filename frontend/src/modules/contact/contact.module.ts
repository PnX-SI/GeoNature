import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SharedModule } from '../../core/components/shared.module'
// Components

import { ContactComponent } from './contact.component';
import { CfFormComponent } from './components/form/cf-form.component';
import { NomenclatureComponent } from '../../core/components/nomenclature/nomenclature.component';
import { ObserversComponent } from '../../core/components/observers/observers.component';
import { CountingComponent } from './components/counting/counting.component';
import { TaxonomyComponent } from '../../core/components/taxonomy/taxonomy.component';
import { TaxonsListComponent } from './components/taxons-list/taxons-list.component';
import { MapComponent } from '../../core/components/map/map.component';

// Service
import { FormService } from '../../core/services/form.service';

@NgModule({
  imports: [
    CommonModule,
    SharedModule
  ],
  declarations: [
    ContactComponent,
    CfFormComponent,
    CountingComponent,
    TaxonsListComponent,
  ],
  providers : [FormService],
  bootstrap: [ContactComponent]
})
export class ContactModule {
}