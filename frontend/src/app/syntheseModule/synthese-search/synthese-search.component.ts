import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { SearchService } from '../search.service';

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
        public searchService: SearchService
    ) {}

    ngOnInit() {
        this.searchForm = this._fb.group({
            cd_nom: null,
            observers: null,
            id_dataset: null,
            id_nomenclature_bio_condition: null
        });
    }

    onSubmitForm() {
        const params = Object.assign({}, this.searchForm.value);
        if (params.cd_nom) {
            params.cd_nom = params.cd_nom.cd_nom;
        }
        this.searchClicked.emit(params);
    }

}
