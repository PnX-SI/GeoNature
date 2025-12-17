// Angular's modules
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatTabsModule } from '@angular/material/tabs';
import { MatStepperModule } from '@angular/material/stepper';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatBadgeModule } from '@angular/material/badge';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatDialogModule } from '@angular/material/dialog';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatListModule } from '@angular/material/list';
import { MatInputModule } from '@angular/material/input';
import { MatMenuModule } from '@angular/material/menu';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatIconRegistry } from '@angular/material/icon';
import { MatSelectModule } from '@angular/material/select';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

// Required modules
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { NgSelectModule } from '@ng-select/ng-select';

import { TreeModule } from '@circlon/angular-tree-component';

// Components
import { AcquisitionFrameworksComponent } from '@geonature_common/form/acquisition-frameworks/acquisition-frameworks.component';
import { AdvancedSectionComponent } from '@geonature_common/form/advanced-section/advanced-section.component';
import { AreasComponent } from '@geonature_common/form/areas/areas.component';
import { AreasIntersectedComponent } from './form/areas-intersected/areas-intersected-modal.component';
import { AutoCompleteComponent } from '@geonature_common/form/autocomplete/autocomplete.component';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { BadgeComponent } from '@geonature_common/others/badge/badge.component';
import { BreadcrumbsComponent } from '@geonature_common/others/breadcrumbs/breadcrumbs.component';
import { DatalistComponent } from '@geonature_common/form/datalist/datalist.component';
import { DatasetsComponent } from './form/datasets/datasets.component';
import { DateComponent } from './form/date/date.component';
import { DumbSelectComponent } from '@geonature_common/form/dumb-select/dumb-select.component';
import { DynamicFormComponent } from './form/dynamic-form/dynamic-form.component';
import { DynamicFormService } from '@geonature_common/form/dynamic-form-generator/dynamic-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { GenericFormGeneratorComponent } from '@geonature_common/form/dynamic-form-generator/dynamic-form-generator.component';
import { GeojsonComponent } from './map/geojson/geojson.component';
import { GeometryFormComponent } from '@geonature_common/form/geometry-form/geometry-form.component';
import { GPSComponent } from './map/gps/gps.component';
import { IndicatorComponent } from '@geonature_common/others/indicator/indicator.component';
import { LeafletDrawComponent } from './map/leaflet-draw/leaflet-draw.component';
import { LeafletFileLayerComponent } from './map/filelayer/filelayer.component';
import { MapComponent } from './map/map.component';
import { MapDataComponent } from './map-list/map-data/map-data.component';
import { MapListComponent } from './map-list/map-list.component';
import { MapListGenericFiltersComponent } from './map-list/generic-filters/generic-filters.component';
import { MapOverLaysComponent } from './map/overlays/overlays.component';
import { MarkerComponent } from './map/marker/marker.component';
import { MediaComponent } from '@geonature_common/form/media/media.component';
import { MediaCard } from '@geonature_common/form/media/media-card.component';
import { MediaDiaporamaDialog } from '@geonature_common/form/media/media-diaporama-dialog.component';
import { MediaItem } from '@geonature_common/form/media/media-item.component';
import { MediasComponent } from '@geonature_common/form/media/medias.component';
import { MediasTestComponent } from '@geonature_common/form/media/medias-test.component';
import { ModalDownloadComponent } from '@geonature_common/others/modal-download/modal-download.component';
import { MultiSelectComponent } from './form/multiselect/multiselect.component';
import { MunicipalitiesComponent } from '@geonature_common/form/municipalities/municipalities.component';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { NomenclatureComponent } from './form/nomenclature/nomenclature.component';
import { ObserversComponent } from './form/observers/observers.component';
import { ObserversTextComponent } from '@geonature_common/form/observers-text/observers-text.component';
import { PeriodComponent } from '@geonature_common/form/date/period.component';
import { PlacesComponent } from './map/places/places.component';
import { PlacesListComponent } from './map/placesList/placesList.component';
import { StatusBadgesComponent } from '@geonature_common/others/status-badges/status-badges.component';
import { SyntheseSearchComponent } from '@geonature_common/form/synthese-form/synthese-form.component';
import { TaxaComponent } from '@geonature_common/form/taxa/taxa.component';
import { TaxonAdvancedModalComponent } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-component';
import { TaxonomyComponent } from './form/taxonomy/taxonomy.component';
import { TogglableFormControlComponent } from '@geonature_common/form/togglable-form-control/togglable-form-control.component';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { UUIDComponent } from '@geonature_common/form/uuid/uuid.component';

// Layouts
import { IndicatorsLayoutComponent } from './layouts/indicators-layout/indicators-layout.component';
import { LoadableLayoutComponent } from './layouts/loadable-layout/loadable-layout.component';
import { PageLayoutComponent } from './layouts/page-layout/page-layout.component';
import { SheetLayoutComponent } from './layouts/sheet-layout/sheet-layout.component';
import { TabsLayoutComponent } from './layouts/tabs-layout/tabs-layout.component';

// Directives
import { DisableControlDirective } from './form/disable-control.directive';
import { DisplayMouseOverDirective } from './directive/display-mouse-over.directive';

// Pipes
import { ReadablePropertiePipe } from './pipe/readable-propertie.pipe';
import { SafeHtmlPipe } from './pipe/sanitizer.pipe';
import { SafeStripHtmlPipe } from './pipe/strip-html.pipe';
import { StripHtmlPipe } from './pipe/strip-html.pipe';

// Services
import { CommonService } from './service/common.service';
import { DataFormService } from './form/data-form.service';
import { FormService } from './form/form.service';
import { MapListService } from './map-list/map-list.service';
import { MapService } from './map/map.service';
import { MediaService } from '@geonature_common/service/media.service';
import { NgbDatePeriodParserFormatter } from '@geonature_common/form/date/ngb-date-custom-parser-formatter';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { TaxonTreeComponent } from './form/taxon-tree/taxon-tree.component';
import { IndividualsComponent } from './form/individuals/individuals.component';
import { IndividualsService } from './form/individuals/individuals.service';
import { IndividualsCreateComponent } from './form/individuals/create/individuals-create.component';

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    MatAutocompleteModule,
    MatBadgeModule,
    MatButtonModule,
    MatCardModule,
    MatChipsModule,
    MatDialogModule,
    MatExpansionModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatListModule,
    MatMenuModule,
    MatPaginatorModule,
    MatProgressBarModule,
    MatProgressSpinnerModule,
    MatSelectModule,
    MatSidenavModule,
    MatSlideToggleModule,
    MatStepperModule,
    MatTabsModule,
    MatToolbarModule,
    MatTooltipModule,
    NgbModule,
    NgxDatatableModule,
    ReactiveFormsModule,
    NgxDatatableModule,
    NgSelectModule,
    RouterModule,
    TranslateModule,
    TreeModule,
  ],
  declarations: [
    AcquisitionFrameworksComponent,
    AdvancedSectionComponent,
    AreasComponent,
    NomenclatureComponent,
    ObserversComponent,
    BadgeComponent,
    IndicatorComponent,
    IndicatorsLayoutComponent,
    LoadableLayoutComponent,
    PageLayoutComponent,
    BreadcrumbsComponent,
    DateComponent,
    TaxonomyComponent,
    AreasIntersectedComponent,
    AutoCompleteComponent,
    ConfirmationDialog,
    DatalistComponent,
    DatasetsComponent,
    DateComponent,
    DisableControlDirective,
    DisplayMouseOverDirective,
    DumbSelectComponent,
    DynamicFormComponent,
    GenericFormComponent,
    GenericFormGeneratorComponent,
    GeojsonComponent,
    GeometryFormComponent,
    GPSComponent,
    LeafletDrawComponent,
    LeafletFileLayerComponent,
    MapComponent,
    MapDataComponent,
    MapListComponent,
    MapListGenericFiltersComponent,
    MapOverLaysComponent,
    MarkerComponent,
    MediaComponent,
    MediaCard,
    MediaDiaporamaDialog,
    MediaItem,
    MediasComponent,
    MediasTestComponent,
    ModalDownloadComponent,
    MultiSelectComponent,
    MunicipalitiesComponent,
    NomenclatureComponent,
    ObserversComponent,
    ObserversTextComponent,
    PeriodComponent,
    PlacesComponent,
    PlacesListComponent,
    ReadablePropertiePipe,
    SafeHtmlPipe,
    SheetLayoutComponent,
    SyntheseSearchComponent,
    SafeStripHtmlPipe,
    StatusBadgesComponent,
    StripHtmlPipe,
    TabsLayoutComponent,
    TaxaComponent,
    TaxonAdvancedModalComponent,
    TaxonomyComponent,
    TaxonTreeComponent,
    TogglableFormControlComponent,
    UUIDComponent,
    IndividualsComponent,
    IndividualsCreateComponent,
  ],
  providers: [
    CommonService,
    DataFormService,
    DynamicFormService,
    FormService,
    MapListService,
    MapService,
    MatIconRegistry,
    MediaService,
    NgbDatePeriodParserFormatter,
    SyntheseDataService,
    TranslateService,
    IndividualsService,
  ],
  exports: [
    AcquisitionFrameworksComponent,
    AdvancedSectionComponent,
    AreasComponent,
    MunicipalitiesComponent,
    BadgeComponent,
    IndicatorComponent,
    IndicatorsLayoutComponent,
    LoadableLayoutComponent,
    PageLayoutComponent,
    BreadcrumbsComponent,
    DynamicFormComponent,
    NomenclatureComponent,
    ObserversComponent,
    DateComponent,
    TaxonomyComponent,
    AreasIntersectedComponent,
    AutoCompleteComponent,
    ConfirmationDialog,
    DatalistComponent,
    DatasetsComponent,
    DateComponent,
    DisableControlDirective,
    DisplayMouseOverDirective,
    DumbSelectComponent,
    FormsModule,
    GenericFormComponent,
    GenericFormGeneratorComponent,
    GeojsonComponent,
    GeometryFormComponent,
    GPSComponent,
    LeafletDrawComponent,
    LeafletFileLayerComponent,
    MapComponent,
    MapDataComponent,
    MapListComponent,
    MapListGenericFiltersComponent,
    MapOverLaysComponent,
    MarkerComponent,
    MatAutocompleteModule,
    MatBadgeModule,
    MatButtonModule,
    MatCardModule,
    MatChipsModule,
    MatDialogModule,
    MatExpansionModule,
    MatFormFieldModule,
    MatIconModule,
    MatInputModule,
    MatListModule,
    MatMenuModule,
    MatPaginatorModule,
    NgSelectModule,
    MatProgressBarModule,
    MatProgressSpinnerModule,
    MatSelectModule,
    MatSidenavModule,
    MatSlideToggleModule,
    MatStepperModule,
    MatTabsModule,
    MatToolbarModule,
    MatTooltipModule,
    MediaCard,
    MediaDiaporamaDialog,
    MediaItem,
    MediasComponent,
    ModalDownloadComponent,
    MultiSelectComponent,
    MunicipalitiesComponent,
    NgbModule,
    NgxDatatableModule,
    NomenclatureComponent,
    ObserversComponent,
    ObserversTextComponent,
    PeriodComponent,
    AutoCompleteComponent,
    SafeStripHtmlPipe,
    StripHtmlPipe,
    SyntheseSearchComponent,
    DumbSelectComponent,
    GeometryFormComponent,
    ConfirmationDialog,
    MediasComponent,
    DatalistComponent,
    PlacesComponent,
    PlacesListComponent,
    ReactiveFormsModule,
    ReadablePropertiePipe,
    SafeHtmlPipe,
    SheetLayoutComponent,
    StatusBadgesComponent,
    TabsLayoutComponent,
    TaxaComponent,
    TaxonAdvancedModalComponent,
    TaxonomyComponent,
    TaxonTreeComponent,
    TogglableFormControlComponent,
    TranslateModule,
    UUIDComponent,
    IndividualsComponent,
  ],
})
export class GN2CommonModule {
  constructor(public matIconRegistry: MatIconRegistry) {
    matIconRegistry.registerFontClassAlias('fontawesome', 'fa');
  }
}
