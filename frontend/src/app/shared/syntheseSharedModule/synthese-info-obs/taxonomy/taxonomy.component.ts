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
      label: 'Synthese.InfoObs.Taxonomy.TaxonomicGroup',
      field: 'classe',
    },
    {
      label: 'Synthese.InfoObs.Taxonomy.Order',
      field: 'ordre',
    },
    {
      label: 'Synthese.InfoObs.Taxonomy.Family',
      field: 'famille',
    },
    {
      label: 'Synthese.InfoObs.Taxonomy.LbNom',
      field: 'lb_nom',
    },
    {
      label: 'Synthese.InfoObs.Taxonomy.CdNom',
      field: 'cd_nom',
    },
    {
      label: 'Synthese.InfoObs.Taxonomy.CdRef',
      field: 'cd_ref',
    },
    {
      label: 'Synthese.InfoObs.Taxonomy.ValidName',
      field: 'nom_valide',
    },
    {
      label: 'Synthese.InfoObs.Taxonomy.CitedName',
      field: 'nom_cite',
    },
    {
      label: 'Synthese.InfoObs.Taxonomy.Rank',
      field: 'nom_rang',
    },
  ];
}
