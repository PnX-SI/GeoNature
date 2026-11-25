import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { DataFormService, Profile } from '@geonature_common/form/data-form.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { CommonService } from '@geonature_common/service/common.service';
import {
  computeIndicatorFromStats,
  Indicator,
  IndicatorDescription,
} from '@geonature_common/others/indicator/indicator';
import { TaxonSheetService } from '../taxon-sheet.service';

const INDICATORS: Array<IndicatorDescription> = [
  {
    name: 'Synthese.Sheets.Indicators.ValidObservations',
    matIcon: 'search',
    field: 'count_valid_data',
    type: 'number',
  },
  {
    name: 'Synthese.Sheets.Indicators.FirstObservation',
    matIcon: 'schedule',
    field: 'first_valid_data',
    type: 'date',
  },
  {
    name: 'Synthese.Sheets.Indicators.LastObservation',
    matIcon: 'search',
    field: 'last_valid_data',
    type: 'date',
  },
  {
    name: 'Synthese.Sheets.Indicators.ValidAltitudeRange',
    matIcon: 'terrain',
    field: ['altitude_min', 'altitude_max'],
    unit: 'm',
    type: 'number',
  },
];

@Component({
  standalone: true,
  templateUrl: 'tab-profile.component.html',
  styleUrls: ['tab-profile.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class TabProfileComponent implements OnInit {
  indicators: Array<Indicator>;
  _profile: Profile | null;

  constructor(
    private _ds: DataFormService,
    private _commonService: CommonService,
    private _tss: TaxonSheetService
  ) {
    this.profile = null;
  }

  ngOnInit(): void {
    this._tss.taxon.subscribe((taxon: Taxon | null) => {
      if (!taxon) {
        this.profile = null;
        return;
      }
      this._ds.getProfile(taxon.cd_ref).subscribe(
        (profile) => {
          this.profile = profile;
        },
        (errors) => {
          this.profile = null;
          if (errors.status == 404) {
            this._commonService.translateToaster(
              'warning',
              'Synthese.FicheTaxon.Messages.MessageNoProfil'
            );
          }
        }
      );
    });
  }
  get profile(): Profile | null {
    return this._profile;
  }

  set profile(profile: Profile | null) {
    this._profile = profile;
    this.indicators = INDICATORS.map((indicatorRaw: IndicatorDescription) =>
      computeIndicatorFromStats(indicatorRaw, profile?.properties)
    );
  }
}
