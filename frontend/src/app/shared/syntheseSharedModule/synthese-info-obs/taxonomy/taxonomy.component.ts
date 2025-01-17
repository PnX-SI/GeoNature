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
  @Input()
  taxon: ObservedTaxon | null = null;

  @Input()
  hideLocalAttributesOnEmpty: boolean = false;

  constructor() {}

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
      label: 'cd nom',
      field: 'cd_nom',
    },
    {
      label: 'lb nom',
      field: 'lb_nom',
    },
    {
      label: 'cd ref',
      field: 'cd_ref',
    },
    {
      label: 'Nom cite',
      field: 'nom_cite',
    },
  ];

  get informationsFiltered() {
    return this.INFORMATIONS.filter((information) => this.taxon[information.field]);
  }
}
