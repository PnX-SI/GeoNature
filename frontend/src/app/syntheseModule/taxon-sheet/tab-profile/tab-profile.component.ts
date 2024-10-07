import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { ConfigService } from '@geonature/services/config.service';
import { DataFormService, Profile } from '@geonature_common/form/data-form.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { CommonService } from '@geonature_common/service/common.service';
import { computeIndicatorFromConfig, Indicator, IndicatorRaw } from '../indicator/indicator';
import { IndicatorComponent } from '../indicator/indicator.component';
import { TaxonSheetService } from '../taxon-sheet.service';

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
    private _config: ConfigService,
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
            this._commonService.regularToaster('warning', 'Aucune donnée pour ce taxon');
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

    if (
      this._config &&
      this._config['SYNTHESE'] &&
      this._config['SYNTHESE']['SPECIES_SHEET'] &&
      this._config['SYNTHESE']['SPECIES_SHEET']['PROFILE']
    ) {
      this.indicators = this._config['SYNTHESE']['SPECIES_SHEET']['PROFILE']['LIST_INDICATORS'].map(
        (indicatorConfig: IndicatorRaw) =>
          computeIndicatorFromConfig(indicatorConfig, profile?.properties)
      );
    } else {
      this.indicators = [];
    }
  }
}
