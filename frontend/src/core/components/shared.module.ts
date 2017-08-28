import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MaterialModule, MdIconModule, MdNativeDateModule } from '@angular/material';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpModule, Http } from '@angular/http';

// Components
import { NomenclatureComponent } from './nomenclature/nomenclature.component';
import { ObserversComponent } from './observers/observers.component';
import { TaxonomyComponent } from './taxonomy/taxonomy.component';
import { MapComponent } from './map/map.component';
import { TranslateModule, TranslateLoader} from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';

// Service
export function HttpLoaderFactory(http: Http) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

@NgModule({
  imports: [
    CommonModule,
    MaterialModule,
    MdIconModule,
    MdNativeDateModule,
    FormsModule,
    ReactiveFormsModule,
    TranslateModule.forRoot({
      loader: {
          provide: TranslateLoader,
          useFactory: HttpLoaderFactory,
          deps: [Http]
      }
  }),

  ],
  declarations: [
    NomenclatureComponent,
    ObserversComponent,
    TaxonomyComponent,
    MapComponent
  ],
  providers : [],
  exports: [    
    NomenclatureComponent,
    ObserversComponent,
    TaxonomyComponent,
    MapComponent,
    FormsModule,
    ReactiveFormsModule,
    MaterialModule,
    MdIconModule,
    MdNativeDateModule,
    TranslateModule

  ]
})
export class SharedModule {
}