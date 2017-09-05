import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '../../core/GN2Common/GN2Common.module'
// Components
import { ContactComponent } from './contact.component';
import { ContactFormComponent } from './components/contact-form/contact-form.component';
import { TaxonsListComponent } from './components/taxons-list/taxons-list.component';
//import { FormService } from '../../components/contact-form/contact-form.service'

@NgModule({
  imports: [
    CommonModule,
    GN2CommonModule,
  ],
  declarations: [
    ContactComponent,
    ContactFormComponent,
    TaxonsListComponent,
  ],
  providers : [],
  bootstrap: [ContactComponent]
})
export class ContactModule {
}