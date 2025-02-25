import { Component, Input, OnInit } from '@angular/core';
import { ObservedTaxon } from '../synthese-info-obs.component';

interface TaxonInformation {
  label: string;
  field: keyof ObservedTaxon;
}

@Component({
  selector: 'pnx-synthese-taxonomy',
  templateUrl: 'taxonomy.component.html',
  styleUrls: ['taxonomy.component.scss'],
})
export class TaxonomyComponent {
  observedTaxon: ObservedTaxon | null = null;
  isStatusEmpty: boolean = true;
  isAttributesEmpty: boolean = true;
  informationsFiltered: TaxonInformation[] = [];

  @Input()
  set taxon(taxon: ObservedTaxon | null) {
    this.observedTaxon = taxon;
    if (!this.observedTaxon) {
      this.isStatusEmpty = true;
      this.isAttributesEmpty = true;
      this.informationsFiltered = [];
      return;
    }
    this.isStatusEmpty = Object.keys(this.observedTaxon.status).length == 0;
    this.isAttributesEmpty = this.observedTaxon.attributs.length == 0;
    this.informationsFiltered = this.INFORMATIONS.filter(
      (information) => this.observedTaxon[information.field]
    );
  }

  @Input()
  hideLocalAttributesOnEmpty: boolean = false;

  readonly INFORMATIONS: Array<TaxonInformation> = [
    {
      label: 'Groupe taxonomique',
      field: 'classe',
    },
    {
      label: 'Ordre',
      field: 'ordre',
    },
    {
      label: 'Famille',
      field: 'famille',
    },
    {
      label: 'lb nom',
      field: 'lb_nom',
    },
    {
      label: 'cd nom',
      field: 'cd_nom',
    },
    {
      label: 'cd ref',
      field: 'cd_ref',
    },
    {
      label: 'Nom valide',
      field: 'nom_valide',
    },
    {
      label: 'Nom cite',
      field: 'nom_cite',
    },
  ];
}
