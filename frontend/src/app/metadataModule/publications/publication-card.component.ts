import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';

import { CommonService } from '@geonature_common/service/common.service';
import { ConfigService } from '@geonature/services/config.service';
import { PublicationsListService } from '../services/publication.service';
import { Publication } from './publication.model';
import { PublicationFormModalComponent } from './publication-form-modal.component';
import { Nomenclature } from '@geonature_common/interfaces';

@Component({
  selector: 'pnx-publication-card',
  templateUrl: './publication-card.component.html',
  styleUrls: ['./publication-card.component.scss'],
})
export class PublicationCardComponent implements OnInit {
  public id_publication: number;
  public publication: Publication | null = null;
  public isLoading = true;

  constructor(
    private _route: ActivatedRoute,
    private _router: Router,
    private _modal: NgbModal,
    private _commonService: CommonService,
    public config: ConfigService,
    public publicationsListService: PublicationsListService
  ) {}
  public publicationTypes: Nomenclature[] = [];

  ngOnInit(): void {
    this.publicationsListService.getPublicationTypes().subscribe((types) => {
      this.publicationTypes = [
        { id_nomenclature: null, label_fr: 'Aucun', label_default: 'Aucun' } as any,
        ...types,
      ];
    });
    this._route.params.subscribe((params) => {
      this.id_publication = +params['id'];

      if (!this.id_publication) {
        this._router.navigate(['/metadata/publication']);
        return;
      }

      this.loadPublication();
    });
  }

  loadPublication(): void {
    this.isLoading = true;

    this.publicationsListService.getPublication(this.id_publication).subscribe(
      (publication) => {
        this.publication = publication;
        this.isLoading = false;
      },
      (err) => {
        this.isLoading = false;

        if (err?.status === 404) {
          this._commonService.translateToaster(
            'error',
            'MetaData.PublicationsList.Errors.NotFound'
          );
        }

        this._router.navigate(['/metadata/publication']);
      }
    );
  }

  log(data): void {
    console.log(data);
  }

  onEditPublication(): void {
    if (!this.publication) {
      return;
    }

    const modalRef = this._modal.open(PublicationFormModalComponent, {
      size: 'lg',
      backdrop: 'static',
      keyboard: false,
    });

    modalRef.componentInstance.publication = this.publication;

    modalRef.result.then((result) => {
      if (result) {
        this.loadPublication();
      }
    });
  }

  getPublicationTypeLabel(idNomenclature: number): string {
    const type = this.publicationTypes.find((t) => t.id_nomenclature === idNomenclature);

    return type?.label_default ?? String(idNomenclature);
  }
}
