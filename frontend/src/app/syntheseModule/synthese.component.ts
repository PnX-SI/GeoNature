import { Component, OnInit } from '@angular/core';
import { ModuleLayoutComponent } from './components/moduleLayout/module-layout.component';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
import { SyntheseCarteComponent } from './carte/synthese-carte.component';
import { SyntheseContentComponent } from './content/synthese-content.component';
import { SyntheseInfoObsComponent } from '../shared/syntheseSharedModule/synthese-info-obs/synthese-info-obs.component';
import { SyntheseApiProxyService } from './services/synthese-api-proxy.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ActivatedRoute, Router, RouterOutlet } from '@angular/router';
@Component({
  standalone: true,
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html',
  imports: [
    GN2CommonModule,
    ModuleLayoutComponent,
    SyntheseCarteComponent,
    SyntheseContentComponent,
    RouterOutlet,
  ],
  providers: [SyntheseApiProxyService, TaxonAdvancedStoreService],
})
export class SyntheseComponent implements OnInit {
  constructor(
    private _apiProxyService: SyntheseApiProxyService,
    private _ngModal: NgbModal,
    private _router: Router,
    private _route: ActivatedRoute
  ) {}

  ngOnInit() {
    this._route.queryParamMap.subscribe((params) => {
      const idSynthese = this._route.snapshot.paramMap.get('id_synthese');
      if (idSynthese) {
        this.openInfoModal(idSynthese);
      }
    });

    this._apiProxyService.fetchObservationsList();
    this._apiProxyService.fetchMapAreas();
  }

  onSearchEvent(event) {
    this._apiProxyService.filters = event;
    this._apiProxyService.fetchObservationsList();
    this._apiProxyService.fetchMapAreas();
  }

  openInfoModal(idSynthese) {
    const modalRef = this._ngModal.open(SyntheseInfoObsComponent, {
      size: 'lg',
      windowClass: 'large-modal',
    });
    modalRef.componentInstance.idSynthese = idSynthese;
    modalRef.componentInstance.header = true;
    modalRef.componentInstance.useFrom = 'synthese';

    let tabRoute = this._route.snapshot.paramMap.get('tab');
    if (tabRoute != null) {
      modalRef.componentInstance.selectedTab = tabRoute;
    }

    modalRef.result
      .then((result) => {})
      .catch((_) => {
        this._router.navigate([modalRef.componentInstance.useFrom]);
      });
  }
}
