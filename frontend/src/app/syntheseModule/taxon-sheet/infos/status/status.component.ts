import { CommonModule } from '@angular/common';
import { Component, Input, OnInit } from '@angular/core';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { TaxonSheetService } from '../../taxon-sheet.service';
import { BadgeSymbology } from '@geonature_common/others/badge/badge.component';

interface Status {
  badge: string;
  tooltip: string;
  symbology: BadgeSymbology | null;
}
@Component({
  standalone: true,
  selector: 'status',
  templateUrl: 'status.component.html',
  styleUrls: ['status.component.scss'],
  imports: [CommonModule, GN2CommonModule],
})
export class StatusComponent implements OnInit {
  _taxon: Taxon | null;
  _symbology: Array<{
    types: Array<string>;
    values: Record<string, BadgeSymbology>;
  }>;
  status: Array<Status> = [];

  constructor(private _tss: TaxonSheetService) {}

  ngOnInit() {
    this._tss.symbology.subscribe((symbology) => {
      this._symbology = [];
      if (!symbology || !symbology.symbologies) {
        return;
      }
      this._symbology = symbology.symbologies;

      this.computeStatus();
    });
    this._tss.fetchStatusSymbology();
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
