import { Component, Input, OnInit } from '@angular/core';
import { TaxonSheetService } from '@geonature/syntheseModule/taxon-sheet/taxon-sheet.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { BadgeSymbology } from '@geonature_common/others/badge/badge.component';

interface Status {
  badge: string;
  tooltip: string;
  symbology: BadgeSymbology | null;
}
@Component({
  selector: 'gn-status-badges',
  templateUrl: 'status-badges.component.html',
  styleUrls: ['status-badges.component.scss'],
})
export class StatusBadgesComponent implements OnInit {
  _taxon: Taxon | null;
  _symbology: Array<{
    types: Array<string>;
    values: Record<string, BadgeSymbology>;
  }>;
  status: Array<Status> = [];

  constructor(private _ds: DataFormService) {}

  ngOnInit() {
    this._ds.fetchStatusSymbology().subscribe((symbology) => {
      this._symbology = [];
      if (!symbology || !symbology.symbologies) {
        return;
      }
      this._symbology = symbology.symbologies;

      this.computeStatus();
    });
  }

  _getSymbologyAsBadgeSymbology(type: string, value: string): BadgeSymbology | null {
    if (!this._symbology) {
      return null;
    }
    const symbologieItem = this._symbology.find((item) => item.types.includes(type));
    if (!symbologieItem) {
      return null;
    }
    if (!('color' in symbologieItem.values[value])) {
      return null;
    }
    return {
      color: symbologieItem.values[value].color,
    };
  }

  @Input()
  set taxon(taxon: Taxon | null) {
    this._taxon = taxon;
    this.computeStatus();
  }

  computeStatus() {
    this.status = [];
    if (!this._taxon) {
      return;
    }

    for (const status of Object.values(this._taxon.status)) {
      for (const text of Object.values<any>(status.text)) {
        for (const value of Object.values<any>(text.values)) {
          const badgeValue = ['true', 'false'].includes(value.code_statut)
            ? `${status.cd_type_statut}`
            : `${status.cd_type_statut}: ${value.code_statut}`;

          this.status.push({
            badge: badgeValue,
            tooltip: `${status.cd_type_statut} : ${value.display} - ${text.full_citation}`,
            symbology: this._getSymbologyAsBadgeSymbology(status.cd_type_statut, value.code_statut),
          });
        }
      }
    }
  }
}
