import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '../../core/GN2Common/GN2Common.module';
// Components
import { ContactMapFormComponent } from './contact-map-form/contact-map-form.component';
import { ObservationComponent } from './contact-map-form/form/observation/observation.component';
import { CountingComponent } from './contact-map-form/form/counting/counting.component';
import { OccurrenceComponent } from './contact-map-form/form/occurrence/occurrence.component';
import { ContactFormComponent } from './contact-map-form/form/contact-form.component';
import { TaxonsListComponent } from './contact-map-form/form/taxons-list/taxons-list.component';
import { ContactMapListComponent } from './contact-map-list/contact-map-list.component';
import { ContactMapInfoComponent } from './contact-map-info/contact-map-info.component';
// Service
import { ContactFormService } from './contact-map-form/form/contact-form.service';


@NgModule({
  imports: [
    CommonModule,
    GN2CommonModule,
  ],
  declarations: [
    ContactMapFormComponent,
    ContactFormComponent,
    ContactMapInfoComponent,
    ObservationComponent,
    CountingComponent,
    OccurrenceComponent,
    TaxonsListComponent,
    ContactMapListComponent,
  ],
  providers : [ContactFormService],
  bootstrap: [ContactMapFormComponent]
})
export class ContactModule {
}
