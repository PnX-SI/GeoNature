import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { FormBuilder, FormGroup, FormControl } from '@angular/forms';
import { SearchService } from '../search.service';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { FormService } from '@geonature_common/form/form-service';
import { CommonService } from '@geonature_common/service/common.service';


@Component({
    selector: 'pnx-synthese-search',
    templateUrl: 'synthese-search.component.html',
    styleUrls: ['synthese-search.component.scss']
})

export class SyntheseSearchComponent implements OnInit {
    public searchForm:  FormGroup;
    @Output() searchClicked = new EventEmitter();
    constructor(
        private _fb: FormBuilder,
        public searchService: SearchService,
        private _formService: FormService,
        private _dateParser: NgbDateParserFormatter,
        private _commonService: CommonService

    ) {}

    ngOnInit() {
        this.searchForm = this._fb.group({
            cd_nom: null,
            observers: null,
            id_dataset: null,
            id_nomenclature_bio_condition: null,
            date_min: null,
            date_max: null
        });
        this.searchForm.setValidators([this._formService.dateValidator]);
    }

    onSubmitForm() {
        const params = Object.assign({}, this.searchForm.value);
        // delete null parameters
        for(let key in params) {
          if (params[key] === null) {
            delete params[key]
          }
        }
        if (params.cd_nom) {
            params.cd_nom = params.cd_nom.cd_nom;
        }

        if(params.date_min) {
            params.date_min = this._dateParser.format(params.date_min);
        }
        if(params.date_max) {
            params.date_max = this._dateParser.format(params.date_max);

        }

        this.searchClicked.emit(params);
    }

}
