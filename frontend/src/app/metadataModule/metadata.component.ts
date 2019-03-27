import { Component, OnInit, ViewChild } from '@angular/core';
import { PageEvent } from '@angular/material';
import { MatPaginator, MatPaginatorIntl } from '@angular/material';
import { CruvedStoreService } from '../services/cruved-store.service';
import { DataFormService } from '@geonature_common/form/data-form.service';

export class MetadataPaginator extends MatPaginatorIntl {
  constructor() {
    super();
    this.nextPageLabel = 'Page suivante';
    this.previousPageLabel = 'Page précédente';
    this.itemsPerPageLabel = 'Éléments par page';
    this.getRangeLabel = (page: number, pageSize: number, length: number) => { if (length == 0 || pageSize == 0) { return `0 sur ${length}`; } length = Math.max(length, 0); const startIndex = page * pageSize; const endIndex = startIndex < length ? Math.min(startIndex + pageSize, length) : startIndex + pageSize; return `${startIndex + 1} - ${endIndex} sur ${length}`; };
  }
}

@Component({
  selector: 'pnx-metadata',
  templateUrl: './metadata.component.html',
  styleUrls: ['./metadata.component.scss'],
  providers: [
    {
      provide: MatPaginatorIntl,
      useClass: MetadataPaginator
    }
  ]
})
export class MetadataComponent implements OnInit {
  
  datasets = [];
  acquisitionFrameworks = [];
  tempAF = [];
  private researchTerm: string = '';

  pageSize: number = 10;
  activePage: number = 0;
  pageSizeOptions: Array<number> = [10, 25, 50, 100];

  constructor(
  	public _cruvedStore: CruvedStoreService,
  	private _dfs: DataFormService
  ) {}

  ngOnInit() {
  	this.getAcquisitionFrameworks();
  }

  //recuperation cadres d'acquisition
  getAcquisitionFrameworks() {
  	this._dfs.getAcquisitionFrameworks().subscribe(data => {
      this.acquisitionFrameworks = data;
      this.tempAF = this.acquisitionFrameworks;
  		this.getDatasets();
    });
  }

  //recuperation des jeux de données
  getDatasets() {
  	this._dfs.getDatasets().subscribe(results => {
  		//attribut les jdds au ca respectif
  		for (var i = 0; i < results['data'].length; i++) {
				let af = this.findAcquisitionFrameworkById(results['data'][i].id_acquisition_framework);
				if (typeof af['datasets'] === 'undefined') {
					af['datasets'] = new Array();
					af['datasetsTemp'] = new Array();
				}
				af['datasets'].push(results['data'][i]);
				af['datasetsTemp'].push(results['data'][i]);
			}
      // cache our list
      this.datasets = results['data'];
    });
  }

  /**
  *	Retourne le cadre d'acquisition à partir de son ID
  **/
  private findAcquisitionFrameworkById(id: number) {
  	return this.acquisitionFrameworks.find(af=> af.id_acquisition_framework == id);
  }


  /**
  *	Filtre les éléments CA et JDD selon la valeur de la barre de recherche
  **/
  updateSearchbar(event) {
  	this.researchTerm = event.target.value.toLowerCase();

  	//recherche des cadres d'acquisition qui matchent
  	this.tempAF = this.acquisitionFrameworks.filter(
  		af=>{
  			//si vide => affiche tout et ferme le panel
  			if (this.researchTerm === '') {
  				//af.datasets.filter(ds=>true);
	  			af.datasetsTemp = af.datasets;
  				return true;
  			} else {
	  			if (af.acquisition_framework_name.toLowerCase().indexOf(this.researchTerm) !== -1) {
	  				//si un cadre matche on affiche tout ses JDD
	  				af.datasetsTemp = af.datasets;
	  				return true;
	  			}
	  			//Sinon on on filtre les JDD qui matchent eventuellement.
	  			af.datasetsTemp = af.datasets.filter(ds=>ds.dataset_name.toLowerCase().indexOf(this.researchTerm) !== -1);
	  			return af.datasetsTemp.length ;
	  		}
  		}
  	)
  }

  isDisplayed(idx: number) {
  	//numero du CA à partir de 1
  	let element = idx + 1;
  	//calcule des tranches active à afficher
  	let idxMin = this.pageSize * this.activePage;
  	let idxMax = this.pageSize * (this.activePage + 1);

  	return (idxMin < element && element <= idxMax);
  }

  changePaginator(event: PageEvent){
  	this.pageSize = event.pageSize;
  	this.activePage = event.pageIndex;
  }

}
