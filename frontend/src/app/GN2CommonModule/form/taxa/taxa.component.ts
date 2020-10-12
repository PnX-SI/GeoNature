import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-taxa',
  templateUrl: 'taxa.component.html'
})
export class TaxaComponent implements OnInit {
  public taxa: any;
  public cachedTaxa: any;
  // Taxa higher than this rank will be display.
  @Input() rank: string = 'GN';
  @Input() label: string;
  @Input() searchBar = false;
  @Input() parentFormControl: FormControl;
  @Input() bindAllItem: false;
  @Input() debounceTime: number;

  constructor(
    private dataService: DataFormService,
    private commonService: CommonService
  ) {}

  ngOnInit() {
    this.cachedTaxa = [];
    this.taxa = [];
  }

  refreshTaxaList(taxon_name) {
    // Refresh taxa API call only when taxon_name >= 2 characters
    if (taxon_name && taxon_name.length >= 2) {
      this.dataService.getHigherTaxa(this.rank, taxon_name).subscribe(
        data => {
          this.taxa = data;
        },
        err => {
          if (err.status === 404) {
            this.taxa = [{ displayName: 'No data to display' }];
          } else {
            this.taxa = [];
            this.commonService.translateToaster('error', 'ErrorMessage');
          }
        }
      );
    // Reset taxa when delete search or select a taxon
    } else if (!taxon_name) {
      this.taxa = this.cachedTaxa;
    }
  }
}
