import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { DataFormService, Profile } from '@geonature_common/form/data-form.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { CommonService } from '@geonature_common/service/common.service';
import {
  computeIndicatorFromDescription,
  Indicator,
  IndicatorDescription,
} from '../indicator/indicator';
import { IndicatorComponent } from '../indicator/indicator.component';
import { TaxonSheetService } from '../taxon-sheet.service';

const INDICATORS: Array<IndicatorDescription> = [
  {
    name: 'observation(s) valide(s)*',
    matIcon: 'search',
    field: 'count_valid_data',
    type: 'number',
  },
  {
    name: 'Première observation*',
    matIcon: 'schedule',
    field: 'first_valid_data',
    type: 'date',
  },
  {
    name: 'Dernière observation*',
    matIcon: 'search',
    field: 'last_valid_data',
    type: 'date',
  },
  {
    name: "Plage d'altitude(s)*",
    matIcon: 'terrain',
    field: ['altitude_min', 'altitude_max'],
    unit: 'm',
    type: 'number',
  },
];

@Component({
  standalone: true,
  selector: 'tab-profile',
  templateUrl: 'tab-profile.component.html',
  styleUrls: ['tab-profile.component.scss'],
  imports: [GN2CommonModule, CommonModule, IndicatorComponent],
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
            this._commonService.regularToaster('warning', 'Aucune donnée de profil pour ce taxon');
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
      computeIndicatorFromDescription(indicatorRaw, profile?.properties)
    );
  }
}
