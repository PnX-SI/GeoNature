'use strict';


customElements.define('compodoc-menu', class extends HTMLElement {
    constructor() {
        super();
        this.isNormalMode = this.getAttribute('mode') === 'normal';
    }

    connectedCallback() {
        this.render(this.isNormalMode);
    }

    render(isNormalMode) {
        let tp = lithtml.html(`
        <nav>
            <ul class="list">
                <li class="title">
                    <a href="index.html" data-type="index-link">geonature documentation</a>
                </li>

                <li class="divider"></li>
                ${ isNormalMode ? `<div id="book-search-input" role="search"><input type="text" placeholder="Type to search"></div>` : '' }
                <li class="chapter">
                    <a data-type="chapter-link" href="index.html"><span class="icon ion-ios-home"></span>Getting started</a>
                    <ul class="links">
                        <li class="link">
                            <a href="index.html" data-type="chapter-link">
                                <span class="icon ion-ios-keypad"></span>Overview
                            </a>
                        </li>
                                <li class="link">
                                    <a href="dependencies.html" data-type="chapter-link">
                                        <span class="icon ion-ios-list"></span>Dependencies
                                    </a>
                                </li>
                    </ul>
                </li>
                    <li class="chapter modules">
                        <a data-type="chapter-link" href="modules.html">
                            <div class="menu-toggler linked" data-toggle="collapse" ${ isNormalMode ?
                                'data-target="#modules-links"' : 'data-target="#xs-modules-links"' }>
                                <span class="icon ion-ios-archive"></span>
                                <span class="link-name">Modules</span>
                                <span class="icon ion-ios-arrow-down"></span>
                            </div>
                        </a>
                        <ul class="links collapse " ${ isNormalMode ? 'id="modules-links"' : 'id="xs-modules-links"' }>
                            <li class="link">
                                <a href="modules/AdminModule.html" data-type="entity-link">AdminModule</a>
                                    <li class="chapter inner">
                                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                            'data-target="#components-links-module-AdminModule-006003a7bf951c3184921853fef64372"' : 'data-target="#xs-components-links-module-AdminModule-006003a7bf951c3184921853fef64372"' }>
                                            <span class="icon ion-md-cog"></span>
                                            <span>Components</span>
                                            <span class="icon ion-ios-arrow-down"></span>
                                        </div>
                                        <ul class="links collapse" ${ isNormalMode ? 'id="components-links-module-AdminModule-006003a7bf951c3184921853fef64372"' :
                                            'id="xs-components-links-module-AdminModule-006003a7bf951c3184921853fef64372"' }>
                                            <li class="link">
                                                <a href="components/AdminComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">AdminComponent</a>
                                            </li>
                                        </ul>
                                    </li>
                            </li>
                            <li class="link">
                                <a href="modules/AppModule.html" data-type="entity-link">AppModule</a>
                                    <li class="chapter inner">
                                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                            'data-target="#components-links-module-AppModule-585f6b223be783781c92ab6b3edf7bed"' : 'data-target="#xs-components-links-module-AppModule-585f6b223be783781c92ab6b3edf7bed"' }>
                                            <span class="icon ion-md-cog"></span>
                                            <span>Components</span>
                                            <span class="icon ion-ios-arrow-down"></span>
                                        </div>
                                        <ul class="links collapse" ${ isNormalMode ? 'id="components-links-module-AppModule-585f6b223be783781c92ab6b3edf7bed"' :
                                            'id="xs-components-links-module-AppModule-585f6b223be783781c92ab6b3edf7bed"' }>
                                            <li class="link">
                                                <a href="components/AppComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">AppComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/FooterComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">FooterComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/HomeContentComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">HomeContentComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/IntroductionComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">IntroductionComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/LoginComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">LoginComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/NavHomeComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">NavHomeComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/NewPasswordComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">NewPasswordComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/PageNotFoundComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">PageNotFoundComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/SidenavItemsComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">SidenavItemsComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/SignUpComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">SignUpComponent</a>
                                            </li>
                                        </ul>
                                    </li>
                                <li class="chapter inner">
                                    <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                        'data-target="#injectables-links-module-AppModule-585f6b223be783781c92ab6b3edf7bed"' : 'data-target="#xs-injectables-links-module-AppModule-585f6b223be783781c92ab6b3edf7bed"' }>
                                        <span class="icon ion-md-arrow-round-down"></span>
                                        <span>Injectables</span>
                                        <span class="icon ion-ios-arrow-down"></span>
                                    </div>
                                    <ul class="links collapse" ${ isNormalMode ? 'id="injectables-links-module-AppModule-585f6b223be783781c92ab6b3edf7bed"' :
                                        'id="xs-injectables-links-module-AppModule-585f6b223be783781c92ab6b3edf7bed"' }>
                                        <li class="link">
                                            <a href="injectables/AuthService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>AuthService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/CruvedStoreService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>CruvedStoreService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/GlobalSubService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>GlobalSubService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/ModuleService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>ModuleService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/SideNavService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>SideNavService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/UserDataService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>UserDataService</a>
                                        </li>
                                    </ul>
                                </li>
                            </li>
                            <li class="link">
                                <a href="modules/GN2CommonModule.html" data-type="entity-link">GN2CommonModule</a>
                                    <li class="chapter inner">
                                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                            'data-target="#components-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' : 'data-target="#xs-components-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' }>
                                            <span class="icon ion-md-cog"></span>
                                            <span>Components</span>
                                            <span class="icon ion-ios-arrow-down"></span>
                                        </div>
                                        <ul class="links collapse" ${ isNormalMode ? 'id="components-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' :
                                            'id="xs-components-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' }>
                                            <li class="link">
                                                <a href="components/AcquisitionFrameworksComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">AcquisitionFrameworksComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/AreasComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">AreasComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/AreasIntersectedComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">AreasIntersectedComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/AutoCompleteComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">AutoCompleteComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/BreadcrumbsComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">BreadcrumbsComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/DatalistComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">DatalistComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/DatasetsComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">DatasetsComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/DateComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">DateComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/DisplayMediasComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">DisplayMediasComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/DumbSelectComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">DumbSelectComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/DynamicFormComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">DynamicFormComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/GPSComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">GPSComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/GenericFormComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">GenericFormComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/GenericFormGeneratorComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">GenericFormGeneratorComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/GeojsonComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">GeojsonComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/GeometryFormComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">GeometryFormComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/LeafletDrawComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">LeafletDrawComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/LeafletFileLayerComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">LeafletFileLayerComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MapComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MapComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MapDataComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MapDataComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MapListComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MapListComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MapListGenericFiltersComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MapListGenericFiltersComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MapOverLaysComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MapOverLaysComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MarkerComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MarkerComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MediaComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MediaComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MediasComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MediasComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MediasTestComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MediasTestComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/ModalDownloadComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">ModalDownloadComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MultiSelectComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MultiSelectComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MunicipalitiesComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MunicipalitiesComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/NomenclatureComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">NomenclatureComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/ObserversComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">ObserversComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/ObserversTextComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">ObserversTextComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/PeriodComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">PeriodComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/PlacesComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">PlacesComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/PlacesListComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">PlacesListComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/SyntheseSearchComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">SyntheseSearchComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/TaxaComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">TaxaComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/TaxonAdvancedModalComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">TaxonAdvancedModalComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/TaxonomyComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">TaxonomyComponent</a>
                                            </li>
                                        </ul>
                                    </li>
                                <li class="chapter inner">
                                    <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                        'data-target="#directives-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' : 'data-target="#xs-directives-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' }>
                                        <span class="icon ion-md-code-working"></span>
                                        <span>Directives</span>
                                        <span class="icon ion-ios-arrow-down"></span>
                                    </div>
                                    <ul class="links collapse" ${ isNormalMode ? 'id="directives-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' :
                                        'id="xs-directives-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' }>
                                        <li class="link">
                                            <a href="directives/DisableControlDirective.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules">DisableControlDirective</a>
                                        </li>
                                        <li class="link">
                                            <a href="directives/DisplayMouseOverDirective.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules">DisplayMouseOverDirective</a>
                                        </li>
                                    </ul>
                                </li>
                                <li class="chapter inner">
                                    <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                        'data-target="#injectables-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' : 'data-target="#xs-injectables-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' }>
                                        <span class="icon ion-md-arrow-round-down"></span>
                                        <span>Injectables</span>
                                        <span class="icon ion-ios-arrow-down"></span>
                                    </div>
                                    <ul class="links collapse" ${ isNormalMode ? 'id="injectables-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' :
                                        'id="xs-injectables-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' }>
                                        <li class="link">
                                            <a href="injectables/CommonService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>CommonService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/CruvedStoreService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>CruvedStoreService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/DataFormService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>DataFormService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/DynamicFormService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>DynamicFormService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/FormService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>FormService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/MapListService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>MapListService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/MapService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>MapService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/MediaService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>MediaService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/NgbDatePeriodParserFormatter.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>NgbDatePeriodParserFormatter</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/SyntheseDataService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>SyntheseDataService</a>
                                        </li>
                                    </ul>
                                </li>
                                    <li class="chapter inner">
                                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                            'data-target="#pipes-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' : 'data-target="#xs-pipes-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' }>
                                            <span class="icon ion-md-add"></span>
                                            <span>Pipes</span>
                                            <span class="icon ion-ios-arrow-down"></span>
                                        </div>
                                        <ul class="links collapse" ${ isNormalMode ? 'id="pipes-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' :
                                            'id="xs-pipes-links-module-GN2CommonModule-e5e6e4871a14c95d44ec6ba35d292c03"' }>
                                            <li class="link">
                                                <a href="pipes/ReadablePropertiePipe.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">ReadablePropertiePipe</a>
                                            </li>
                                            <li class="link">
                                                <a href="pipes/SafeHtmlPipe.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">SafeHtmlPipe</a>
                                            </li>
                                            <li class="link">
                                                <a href="pipes/SafeStripHtmlPipe.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">SafeStripHtmlPipe</a>
                                            </li>
                                            <li class="link">
                                                <a href="pipes/StripHtmlPipe.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">StripHtmlPipe</a>
                                            </li>
                                        </ul>
                                    </li>
                            </li>
                            <li class="link">
                                <a href="modules/GNPanelModule.html" data-type="entity-link">GNPanelModule</a>
                                    <li class="chapter inner">
                                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                            'data-target="#components-links-module-GNPanelModule-a0420cfd66f38a255a2db8b0a4ba42f2"' : 'data-target="#xs-components-links-module-GNPanelModule-a0420cfd66f38a255a2db8b0a4ba42f2"' }>
                                            <span class="icon ion-md-cog"></span>
                                            <span>Components</span>
                                            <span class="icon ion-ios-arrow-down"></span>
                                        </div>
                                        <ul class="links collapse" ${ isNormalMode ? 'id="components-links-module-GNPanelModule-a0420cfd66f38a255a2db8b0a4ba42f2"' :
                                            'id="xs-components-links-module-GNPanelModule-a0420cfd66f38a255a2db8b0a4ba42f2"' }>
                                            <li class="link">
                                                <a href="components/GNPanelComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">GNPanelComponent</a>
                                            </li>
                                        </ul>
                                    </li>
                            </li>
                            <li class="link">
                                <a href="modules/MetadataModule.html" data-type="entity-link">MetadataModule</a>
                                    <li class="chapter inner">
                                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                            'data-target="#components-links-module-MetadataModule-3bbe30e5328a6f4b952583fc9fb7d9ec"' : 'data-target="#xs-components-links-module-MetadataModule-3bbe30e5328a6f4b952583fc9fb7d9ec"' }>
                                            <span class="icon ion-md-cog"></span>
                                            <span>Components</span>
                                            <span class="icon ion-ios-arrow-down"></span>
                                        </div>
                                        <ul class="links collapse" ${ isNormalMode ? 'id="components-links-module-MetadataModule-3bbe30e5328a6f4b952583fc9fb7d9ec"' :
                                            'id="xs-components-links-module-MetadataModule-3bbe30e5328a6f4b952583fc9fb7d9ec"' }>
                                            <li class="link">
                                                <a href="components/ActorComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">ActorComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/AfCardComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">AfCardComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/AfFormComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">AfFormComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/DatasetCardComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">DatasetCardComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/DatasetFormComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">DatasetFormComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/MetadataComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">MetadataComponent</a>
                                            </li>
                                        </ul>
                                    </li>
                            </li>
                            <li class="link">
                                <a href="modules/SharedSyntheseModule.html" data-type="entity-link">SharedSyntheseModule</a>
                                    <li class="chapter inner">
                                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                            'data-target="#components-links-module-SharedSyntheseModule-5f6435820f69e056a78c1077d6a85f67"' : 'data-target="#xs-components-links-module-SharedSyntheseModule-5f6435820f69e056a78c1077d6a85f67"' }>
                                            <span class="icon ion-md-cog"></span>
                                            <span>Components</span>
                                            <span class="icon ion-ios-arrow-down"></span>
                                        </div>
                                        <ul class="links collapse" ${ isNormalMode ? 'id="components-links-module-SharedSyntheseModule-5f6435820f69e056a78c1077d6a85f67"' :
                                            'id="xs-components-links-module-SharedSyntheseModule-5f6435820f69e056a78c1077d6a85f67"' }>
                                            <li class="link">
                                                <a href="components/SyntheseInfoObsComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">SyntheseInfoObsComponent</a>
                                            </li>
                                        </ul>
                                    </li>
                            </li>
                            <li class="link">
                                <a href="modules/SyntheseModule.html" data-type="entity-link">SyntheseModule</a>
                                    <li class="chapter inner">
                                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                            'data-target="#components-links-module-SyntheseModule-529a5756fd5d18f7d88128e17237207c"' : 'data-target="#xs-components-links-module-SyntheseModule-529a5756fd5d18f7d88128e17237207c"' }>
                                            <span class="icon ion-md-cog"></span>
                                            <span>Components</span>
                                            <span class="icon ion-ios-arrow-down"></span>
                                        </div>
                                        <ul class="links collapse" ${ isNormalMode ? 'id="components-links-module-SyntheseModule-529a5756fd5d18f7d88128e17237207c"' :
                                            'id="xs-components-links-module-SyntheseModule-529a5756fd5d18f7d88128e17237207c"' }>
                                            <li class="link">
                                                <a href="components/SyntheseCarteComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">SyntheseCarteComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/SyntheseComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">SyntheseComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/SyntheseListComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">SyntheseListComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/SyntheseModalDownloadComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">SyntheseModalDownloadComponent</a>
                                            </li>
                                        </ul>
                                    </li>
                                <li class="chapter inner">
                                    <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                        'data-target="#injectables-links-module-SyntheseModule-529a5756fd5d18f7d88128e17237207c"' : 'data-target="#xs-injectables-links-module-SyntheseModule-529a5756fd5d18f7d88128e17237207c"' }>
                                        <span class="icon ion-md-arrow-round-down"></span>
                                        <span>Injectables</span>
                                        <span class="icon ion-ios-arrow-down"></span>
                                    </div>
                                    <ul class="links collapse" ${ isNormalMode ? 'id="injectables-links-module-SyntheseModule-529a5756fd5d18f7d88128e17237207c"' :
                                        'id="xs-injectables-links-module-SyntheseModule-529a5756fd5d18f7d88128e17237207c"' }>
                                        <li class="link">
                                            <a href="injectables/DynamicFormService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>DynamicFormService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/MapService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>MapService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/SyntheseFormService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>SyntheseFormService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/SyntheseStoreService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>SyntheseStoreService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/TaxonAdvancedStoreService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>TaxonAdvancedStoreService</a>
                                        </li>
                                    </ul>
                                </li>
                            </li>
                            <li class="link">
                                <a href="modules/UserModule.html" data-type="entity-link">UserModule</a>
                                    <li class="chapter inner">
                                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                            'data-target="#components-links-module-UserModule-376f95dc411f79e556456de39d4759a1"' : 'data-target="#xs-components-links-module-UserModule-376f95dc411f79e556456de39d4759a1"' }>
                                            <span class="icon ion-md-cog"></span>
                                            <span>Components</span>
                                            <span class="icon ion-ios-arrow-down"></span>
                                        </div>
                                        <ul class="links collapse" ${ isNormalMode ? 'id="components-links-module-UserModule-376f95dc411f79e556456de39d4759a1"' :
                                            'id="xs-components-links-module-UserModule-376f95dc411f79e556456de39d4759a1"' }>
                                            <li class="link">
                                                <a href="components/PasswordComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">PasswordComponent</a>
                                            </li>
                                            <li class="link">
                                                <a href="components/UserComponent.html"
                                                    data-type="entity-link" data-context="sub-entity" data-context-id="modules">UserComponent</a>
                                            </li>
                                        </ul>
                                    </li>
                                <li class="chapter inner">
                                    <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ?
                                        'data-target="#injectables-links-module-UserModule-376f95dc411f79e556456de39d4759a1"' : 'data-target="#xs-injectables-links-module-UserModule-376f95dc411f79e556456de39d4759a1"' }>
                                        <span class="icon ion-md-arrow-round-down"></span>
                                        <span>Injectables</span>
                                        <span class="icon ion-ios-arrow-down"></span>
                                    </div>
                                    <ul class="links collapse" ${ isNormalMode ? 'id="injectables-links-module-UserModule-376f95dc411f79e556456de39d4759a1"' :
                                        'id="xs-injectables-links-module-UserModule-376f95dc411f79e556456de39d4759a1"' }>
                                        <li class="link">
                                            <a href="injectables/RoleFormService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>RoleFormService</a>
                                        </li>
                                        <li class="link">
                                            <a href="injectables/UserDataService.html"
                                                data-type="entity-link" data-context="sub-entity" data-context-id="modules" }>UserDataService</a>
                                        </li>
                                    </ul>
                                </li>
                            </li>
                </ul>
                </li>
                    <li class="chapter">
                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ? 'data-target="#components-links"' :
                            'data-target="#xs-components-links"' }>
                            <span class="icon ion-md-cog"></span>
                            <span>Components</span>
                            <span class="icon ion-ios-arrow-down"></span>
                        </div>
                        <ul class="links collapse " ${ isNormalMode ? 'id="components-links"' : 'id="xs-components-links"' }>
                            <li class="link">
                                <a href="components/AcquisitionFrameworksComponent.html" data-type="entity-link">AcquisitionFrameworksComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/AfListComponent.html" data-type="entity-link">AfListComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/AreasComponent.html" data-type="entity-link">AreasComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/AutoCompleteComponent.html" data-type="entity-link">AutoCompleteComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/BreadcrumbsComponent.html" data-type="entity-link">BreadcrumbsComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/ConfirmationDialog.html" data-type="entity-link">ConfirmationDialog</a>
                            </li>
                            <li class="link">
                                <a href="components/DatalistComponent.html" data-type="entity-link">DatalistComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/DatasetListComponent.html" data-type="entity-link">DatasetListComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/DisplayMediasComponent.html" data-type="entity-link">DisplayMediasComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/DumbSelectComponent.html" data-type="entity-link">DumbSelectComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/GenericFormComponent.html" data-type="entity-link">GenericFormComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/GenericFormGeneratorComponent.html" data-type="entity-link">GenericFormGeneratorComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/GeometryFormComponent.html" data-type="entity-link">GeometryFormComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/MediaComponent.html" data-type="entity-link">MediaComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/MediaDialog.html" data-type="entity-link">MediaDialog</a>
                            </li>
                            <li class="link">
                                <a href="components/MediasComponent.html" data-type="entity-link">MediasComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/MediasTestComponent.html" data-type="entity-link">MediasTestComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/ModalDownloadComponent.html" data-type="entity-link">ModalDownloadComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/MunicipalitiesComponent.html" data-type="entity-link">MunicipalitiesComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/ObserversTextComponent.html" data-type="entity-link">ObserversTextComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/PeriodComponent.html" data-type="entity-link">PeriodComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/SyntheseSearchComponent.html" data-type="entity-link">SyntheseSearchComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/TaxaComponent.html" data-type="entity-link">TaxaComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/TaxonAdvancedModalComponent.html" data-type="entity-link">TaxonAdvancedModalComponent</a>
                            </li>
                            <li class="link">
                                <a href="components/TaxonTreeComponent.html" data-type="entity-link">TaxonTreeComponent</a>
                            </li>
                        </ul>
                    </li>
                    <li class="chapter">
                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ? 'data-target="#classes-links"' :
                            'data-target="#xs-classes-links"' }>
                            <span class="icon ion-ios-paper"></span>
                            <span>Classes</span>
                            <span class="icon ion-ios-arrow-down"></span>
                        </div>
                        <ul class="links collapse " ${ isNormalMode ? 'id="classes-links"' : 'id="xs-classes-links"' }>
                            <li class="link">
                                <a href="classes/GeonaturePage.html" data-type="entity-link">GeonaturePage</a>
                            </li>
                            <li class="link">
                                <a href="classes/Media.html" data-type="entity-link">Media</a>
                            </li>
                            <li class="link">
                                <a href="classes/MetadataPaginator.html" data-type="entity-link">MetadataPaginator</a>
                            </li>
                            <li class="link">
                                <a href="classes/Page.html" data-type="entity-link">Page</a>
                            </li>
                        </ul>
                    </li>
                        <li class="chapter">
                            <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ? 'data-target="#injectables-links"' :
                                'data-target="#xs-injectables-links"' }>
                                <span class="icon ion-md-arrow-round-down"></span>
                                <span>Injectables</span>
                                <span class="icon ion-ios-arrow-down"></span>
                            </div>
                            <ul class="links collapse " ${ isNormalMode ? 'id="injectables-links"' : 'id="xs-injectables-links"' }>
                                <li class="link">
                                    <a href="injectables/DynamicFormService.html" data-type="entity-link">DynamicFormService</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/MediaService.html" data-type="entity-link">MediaService</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/MetadataFormService.html" data-type="entity-link">MetadataFormService</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/MetadataSearchFormService.html" data-type="entity-link">MetadataSearchFormService</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/NgbDateFRParserFormatter.html" data-type="entity-link">NgbDateFRParserFormatter</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/NgbDatePeriodParserFormatter.html" data-type="entity-link">NgbDatePeriodParserFormatter</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/RoleFormService.html" data-type="entity-link">RoleFormService</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/SyntheseDataService.html" data-type="entity-link">SyntheseDataService</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/SyntheseFormService.html" data-type="entity-link">SyntheseFormService</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/SyntheseFormService-1.html" data-type="entity-link">SyntheseFormService</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/SyntheseStoreService.html" data-type="entity-link">SyntheseStoreService</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/SyntheseStoreService-1.html" data-type="entity-link">SyntheseStoreService</a>
                                </li>
                                <li class="link">
                                    <a href="injectables/TaxonAdvancedStoreService.html" data-type="entity-link">TaxonAdvancedStoreService</a>
                                </li>
                            </ul>
                        </li>
                    <li class="chapter">
                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ? 'data-target="#interceptors-links"' :
                            'data-target="#xs-interceptors-links"' }>
                            <span class="icon ion-ios-swap"></span>
                            <span>Interceptors</span>
                            <span class="icon ion-ios-arrow-down"></span>
                        </div>
                        <ul class="links collapse " ${ isNormalMode ? 'id="interceptors-links"' : 'id="xs-interceptors-links"' }>
                            <li class="link">
                                <a href="interceptors/MyCustomInterceptor.html" data-type="entity-link">MyCustomInterceptor</a>
                            </li>
                        </ul>
                    </li>
                    <li class="chapter">
                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ? 'data-target="#guards-links"' :
                            'data-target="#xs-guards-links"' }>
                            <span class="icon ion-ios-lock"></span>
                            <span>Guards</span>
                            <span class="icon ion-ios-arrow-down"></span>
                        </div>
                        <ul class="links collapse " ${ isNormalMode ? 'id="guards-links"' : 'id="xs-guards-links"' }>
                            <li class="link">
                                <a href="guards/AuthGuard.html" data-type="entity-link">AuthGuard</a>
                            </li>
                            <li class="link">
                                <a href="guards/ModuleGuardService.html" data-type="entity-link">ModuleGuardService</a>
                            </li>
                            <li class="link">
                                <a href="guards/SignUpGuard.html" data-type="entity-link">SignUpGuard</a>
                            </li>
                            <li class="link">
                                <a href="guards/UserManagementGuard.html" data-type="entity-link">UserManagementGuard</a>
                            </li>
                        </ul>
                    </li>
                    <li class="chapter">
                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ? 'data-target="#interfaces-links"' :
                            'data-target="#xs-interfaces-links"' }>
                            <span class="icon ion-md-information-circle-outline"></span>
                            <span>Interfaces</span>
                            <span class="icon ion-ios-arrow-down"></span>
                        </div>
                        <ul class="links collapse " ${ isNormalMode ? ' id="interfaces-links"' : 'id="xs-interfaces-links"' }>
                            <li class="link">
                                <a href="interfaces/ColumnActions.html" data-type="entity-link">ColumnActions</a>
                            </li>
                            <li class="link">
                                <a href="interfaces/DateStruc.html" data-type="entity-link">DateStruc</a>
                            </li>
                            <li class="link">
                                <a href="interfaces/IBreadCrumb.html" data-type="entity-link">IBreadCrumb</a>
                            </li>
                            <li class="link">
                                <a href="interfaces/IBuildBreadCrumb.html" data-type="entity-link">IBuildBreadCrumb</a>
                            </li>
                            <li class="link">
                                <a href="interfaces/MediaDialogData.html" data-type="entity-link">MediaDialogData</a>
                            </li>
                            <li class="link">
                                <a href="interfaces/MediaDialogData-1.html" data-type="entity-link">MediaDialogData</a>
                            </li>
                            <li class="link">
                                <a href="interfaces/ParamsDict.html" data-type="entity-link">ParamsDict</a>
                            </li>
                            <li class="link">
                                <a href="interfaces/Role.html" data-type="entity-link">Role</a>
                            </li>
                            <li class="link">
                                <a href="interfaces/Taxon.html" data-type="entity-link">Taxon</a>
                            </li>
                            <li class="link">
                                <a href="interfaces/User.html" data-type="entity-link">User</a>
                            </li>
                        </ul>
                    </li>
                    <li class="chapter">
                        <div class="simple menu-toggler" data-toggle="collapse" ${ isNormalMode ? 'data-target="#miscellaneous-links"'
                            : 'data-target="#xs-miscellaneous-links"' }>
                            <span class="icon ion-ios-cube"></span>
                            <span>Miscellaneous</span>
                            <span class="icon ion-ios-arrow-down"></span>
                        </div>
                        <ul class="links collapse " ${ isNormalMode ? 'id="miscellaneous-links"' : 'id="xs-miscellaneous-links"' }>
                            <li class="link">
                                <a href="miscellaneous/enumerations.html" data-type="entity-link">Enums</a>
                            </li>
                            <li class="link">
                                <a href="miscellaneous/functions.html" data-type="entity-link">Functions</a>
                            </li>
                            <li class="link">
                                <a href="miscellaneous/variables.html" data-type="entity-link">Variables</a>
                            </li>
                        </ul>
                    </li>
                    <li class="chapter">
                        <a data-type="chapter-link" href="coverage.html"><span class="icon ion-ios-stats"></span>Documentation coverage</a>
                    </li>
                    <li class="divider"></li>
                    <li class="copyright">
                        Documentation generated using <a href="https://compodoc.app/" target="_blank">
                            <img data-src="images/compodoc-vectorise.png" class="img-responsive" data-type="compodoc-logo">
                        </a>
                    </li>
            </ul>
        </nav>
        `);
        this.innerHTML = tp.strings;
    }
});