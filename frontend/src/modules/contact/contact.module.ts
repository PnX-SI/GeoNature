import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '../../core/GN2Common/GN2Common.module';
// Components
import { ContactFormComponent } from './contact-form/contact-form.component';
import { ContactCreateFormComponent } from './contact-form/contact-create-form/contact-create-form.component';
import { TaxonsListComponent } from './contact-form/taxons-list/taxons-list.component';
import { ContactMapListComponent } from './contact-map-list/contact-map-list.component';


@NgModule({
  imports: [
    CommonModule,
    GN2CommonModule,
  ],
  declarations: [
    ContactFormComponent,
    ContactCreateFormComponent,
    TaxonsListComponent,
    ContactMapListComponent,
  ],
  providers : [],
  bootstrap: [ContactFormComponent]
})
export class ContactModule {
}
