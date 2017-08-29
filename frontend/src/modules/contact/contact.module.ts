import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GN2CommonModule } from '../../core/GN2Common/GN2Common.module'
// Components
import { ContactComponent } from './contact.component';
import { ContactFormComponent } from './components/contact-form/contact-form.component';
import { CountingComponent } from './components/counting/counting.component';
import { TaxonsListComponent } from './components/taxons-list/taxons-list.component';
import { ContactFormService } from './components/contact-form/contact-form.service'

@NgModule({
  imports: [
    CommonModule,
    GN2CommonModule
  ],
  declarations: [
    ContactComponent,
    ContactFormComponent,
    CountingComponent,
    TaxonsListComponent,
  ],
  providers : [ContactFormService],
  bootstrap: [ContactComponent]
})
export class ContactModule {
}