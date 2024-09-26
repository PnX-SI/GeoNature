import { CommonModule } from '@angular/common';
import { Component, Input, OnInit } from '@angular/core';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { TaxonSheetService } from '../../taxon-sheet.service';

interface Status {
  badge: string;
  tooltip: string;
  symbologyAsCSS: string;
}

function computeContrastColor(backgroundColor: string) {
  // Convertir la couleur en un format RGB
  const r = parseInt(backgroundColor.slice(1, 3), 16);
  const g = parseInt(backgroundColor.slice(3, 5), 16);
  const b = parseInt(backgroundColor.slice(5, 7), 16);

  // Calculer la luminosité
  const luminance = 0.299 * r + 0.587 * g + 0.114 * b;

  // Retourner une couleur claire ou foncée selon la luminosité
  return luminance < 128 ? '#ffffff' : '#444';
}

function colorToCSS(color: string) {
  return `--bgColor: ${color}; --textColor: ${computeContrastColor(color)};`;
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
    values: Record<
      string,
      {
        symbologyAsCSSStyle: string;
      }
    >;
  }>;
  status: Array<Status> = [];

  constructor(private _tss: TaxonSheetService) {}

  ngOnInit() {
    this._tss.symbology.subscribe((symbology) => {
      this._symbology = [];
      if (!symbology || !symbology.symbologies) {
        return;
      }
      for (const symbologyItem of symbology.symbologies) {
        const values = {};
        for (const key of Object.keys(symbologyItem.values)) {
          values[key] = {
            symbologyAsCSSStyle: colorToCSS(symbologyItem.values[key].color),
          };
        }
        this._symbology.push({
          types: symbologyItem.types,
          values: values,
        });
      }
      this.computeStatus();
    });
    this._tss.fetchStatusSymbology();
  }

  _getSymbologyAsCSSStyle(type: string, value: string): string {
    if (!this._symbology) {
      return '';
    }
    const symbologieItem = this._symbology.find((item) => item.types.includes(type));
    if (!symbologieItem) {
      return '';
    }

    return symbologieItem.values[value]?.symbologyAsCSSStyle ?? '';
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
            symbologyAsCSS: this._getSymbologyAsCSSStyle(status.cd_type_statut, value.code_statut),
          });
        }
      }
    }
  }
}
