import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';

@Component({
    selector: 'pnx-synthese-search',
    templateUrl: 'synthese-search.component.html',
    styleUrls: ['synthese-search.component.scss']
})

export class SyntheseSearchComponent implements OnInit {
    public searchForm:  FormGroup;
    constructor(
        private _fb: FormBuilder
    ) {}

    ngOnInit() { 
        this.searchForm = this._fb.group({
            taxon: null,
            observer: null,
            id_dataset:null
        });
    }

}
