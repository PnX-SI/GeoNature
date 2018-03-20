import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { TranslateHttpLoader } from "@ngx-translate/http-loader";
import { Http } from "@angular/http";
// Components
import { ContactMapFormComponent } from "./contact-map-form/contact-map-form.component";
import { ReleveComponent } from "./contact-map-form/form/releve/releve.component";
import { CountingComponent } from "./contact-map-form/form/counting/counting.component";
import { OccurrenceComponent } from "./contact-map-form/form/occurrence/occurrence.component";
import { ContactFormComponent } from "./contact-map-form/form/contact-form.component";
import { TaxonsListComponent } from "./contact-map-form/form/taxons-list/taxons-list.component";
import { ContactMapListComponent } from "./contact-map-list/contact-map-list.component";
import { ContactMapInfoComponent } from "./contact-map-info/contact-map-info.component";
// Service
import { ContactFormService } from "./contact-map-form/form/contact-form.service";
import { ContactService } from "./services/contact.service";

const routes: Routes = [
  { path: "", component: ContactMapListComponent },
  { path: "form", component: ContactMapFormComponent },
  { path: "form/:id", component: ContactMapFormComponent, pathMatch: "full" },
  { path: "info/:id", component: ContactMapInfoComponent, pathMatch: "full" }
];

@NgModule({
  imports: [CommonModule, GN2CommonModule, RouterModule.forChild(routes)],
  declarations: [
    ContactMapFormComponent,
    ContactFormComponent,
    ContactMapInfoComponent,
    ReleveComponent,
    CountingComponent,
    OccurrenceComponent,
    TaxonsListComponent,
    ContactMapListComponent
  ],
  providers: [ContactFormService, ContactService],
  bootstrap: [ContactMapFormComponent]
})
export class GeonatureModule {}
