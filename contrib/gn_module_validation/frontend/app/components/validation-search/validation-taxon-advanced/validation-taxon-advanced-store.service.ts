import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { AppConfig } from '@geonature_config/app.config';
import { DataService } from '../../../services/data.service';
import { FormService } from '../../../services/form.service';
import { DynamicFormService } from '@geonature_common/form/dynamic-form/dynamic-form.service';
import { TreeModel,ITreeState } from 'angular-tree-component';
import { ModuleConfig } from '../../../module.config';

@Injectable()
export class ValidationTaxonAdvancedStoreService {
  public VALIDATION_CONFIG = ModuleConfig;
  public taxonTree: any;
  public treeModel: TreeModel;
  public taxonTreeState: any;
  public taxhubAttributes: any;
  public formBuilded: boolean;
  public taxonomyLR: Array<any>;
  public taxonomyHab: Array<any>;
  public taxonomyGroup2Inpn: Array<any>;

  constructor(
    private _dataService: DataFormService,
    private _validationDataService: DataService,
    private _formService: FormService,
    private _formGen: DynamicFormService
  ) {
    if (this.VALIDATION_CONFIG.DISPLAY_TAXON_TREE) {
      this._validationDataService.getTaxonTree().subscribe(data => {
        this.taxonTree = this.formatTaxonTree(data);
      });
    }

    // get taxhub attributes
    this._dataService.getTaxhubBibAttributes().subscribe(attrs => {
      // display only the taxhub attributes set in the config
      this.taxhubAttributes = attrs
        .filter(attr => {
          return this.VALIDATION_CONFIG.ID_ATTRIBUT_TAXHUB.indexOf(attr.id_attribut) !== -1;
        })
        .map(attr => {
          // format attributes to fit with the GeoNature dynamicFormComponent
          attr['values'] = JSON.parse(attr['liste_valeur_attribut']).values;
          attr['attribut_name'] = 'taxhub_attribut_' + attr['id_attribut'];
          attr['required'] = attr['obligatoire'];
          attr['attribut_label'] = attr['label_attribut'];
          if (attr['type_widget'] == 'multiselect') {
            attr['values'] = attr['values'].map(val => {
              return { value: val };
            });
          }
          this._formGen.addNewControl(attr, this._formService.searchForm);

          return attr;
        });
      this.formBuilded = true;
    });
    // load LR,  habitat and group2inpn
    this._dataService.getTaxonomyLR().subscribe(data => {
      this.taxonomyLR = data;
    });

    this._dataService.getTaxonomyHabitat().subscribe(data => {
      this.taxonomyHab = data;
    });

    const all_groups = [];
    this._dataService.getRegneAndGroup2Inpn().subscribe(data => {
      this.taxonomyGroup2Inpn = data;
      // tslint:disable-next-line:forin
      for (let regne in data) {
        data[regne].forEach(group => {
          if (group.length > 0) {
            all_groups.push({ value: group });
          }
        });
      }
      this.taxonomyGroup2Inpn = all_groups;
    });
  }

  formatTaxonTree(taxonTree) {
    const formattedTree = [];
    let childrensRegne = [];
    let childrensEmbranchement = [];
    let childrensClasse = [];
    let childrensOrdre = [];
    let childrensFamille = [];
    let kd = null;
    let emb = null;
    let cl = null;
    let desc_cl = null;
    let ord = null;
    let fam = null;
    let nouveauRegne = false;
    let nouvelEmbranchement = false;
    let nouvelleClasse = false;
    let nouvelOrdre = false;
    let nouvelleFamille = false;
    let child = {};
    let regne = {};
    let embranchement = {};
    let classe = {};
    let ordre = {};
    let famille = {};

    //on bouble sur les enregistrements du store des taxons issu de la base
    taxonTree.forEach(record => {
      if (kd === null) {
        kd = record.nom_regne;
      } //initialisation
      if (emb === null) {
        emb = record.nom_embranchement;
      } //initialisation
      if (cl === null) {
        cl = record.nom_classe;
      } //initialisation
      if (desc_cl === null) {
        desc_cl = record.desc_classe;
      } //initialisation
      if (ord === null) {
        ord = record.nom_ordre;
      } //initialisation
      if (fam === null) {
        fam = record.nom_famille;
      } //initialisation
      if (kd !== record.nom_regne) {
        nouveauRegne = true;
      } // si on a changé de niveau de règne
      if (emb !== record.nom_embranchement) {
        nouvelEmbranchement = true;
      } // si on a changé de niveau d'embranchement
      if (cl !== record.nom_classe) {
        nouvelleClasse = true;
      } // si on a changé de niveau de classe
      if (ord !== record.nom_ordre) {
        nouvelOrdre = true;
      } // si on a changé de niveau d'ordre
      if (fam !== record.nom_famille) {
        nouvelleFamille = true;
      } // si on a changé de niveau de famille

      //création d'un noeud final avec checkbox
      child = {
        id: record.cd_ref,
        name: record.nom_latin + ' - ' + record.nom_francais,
        classes: ['leaf'],
        leaf: true,
        checked: false
      };
      if (nouvelleFamille) {
        //on crée le groupe
        famille = {
          name: fam,
          checked: false,
          children: childrensFamille
        };
        childrensOrdre.push(famille); //on ajoute ce groupe à l'arbre
        nouvelleFamille = false; //on repasse à false pour les prochains tests
        childrensFamille = []; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
      }
      if (nouvelOrdre) {
        //on crée le groupe
        ordre = {
          name: ord,
          checked: false,
          children: childrensOrdre
        };
        childrensClasse.push(ordre); //on ajoute ce groupe à l'arbre
        nouvelOrdre = false; //on repasse à false pour les prochains tests
        childrensOrdre = []; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
      }
      if (nouvelleClasse) {
        //on crée le groupe
        classe = {
          name: cl + ' - ' + desc_cl,
          checked: false,
          children: childrensClasse
        };
        childrensEmbranchement.push(classe); //on ajoute ce groupe à l'arbre
        nouvelleClasse = false; //on repasse à false pour les prochains tests
        childrensClasse = []; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
      }
      if (nouvelEmbranchement) {
        //on crée le groupe
        embranchement = {
          name: emb,
          checked: false,
          children: childrensEmbranchement
        };
        childrensRegne.push(embranchement); //on ajoute ce groupe à l'arbre
        nouvelEmbranchement = false; //on repasse à false pour les prochains tests
        childrensEmbranchement = []; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
      }
      if (nouveauRegne) {
        //on crée le groupe
        regne = {
          name: kd,
          checked: false,
          children: childrensRegne
        };
        formattedTree.push(regne); //on ajoute ce groupe à l'arbre
        nouveauRegne = false; //on repasse à false pour les prochains tests
        childrensRegne = []; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
      }
      childrensFamille.push(child); //ajout du noeud au groupe
      kd = record.nom_regne; //kd prend la valeur en cours du groupe pour un nouveau test en début de boucle
      emb = record.nom_embranchement; //emb prend la valeur en cours du groupe pour un nouveau test en début de boucle
      cl = record.nom_classe; //cl prend la valeur en cours du groupe pour un nouveau test en début de boucle
      desc_cl = record.desc_classe; //
      ord = record.nom_ordre; //ord prend la valeur en cours du groupe pour un nouveau test en début de boucle
      fam = record.nom_famille; //fam prend la valeur en cours du groupe pour un nouveau test en début de boucle
    }); //fin de la boucle

    //ajout du dernier groupe après la fin de la dernière boucle
    famille = {
      name: fam,
      checked: false,
      children: childrensFamille
    };
    ordre = {
      name: ord,
      checked: false,
      children: childrensOrdre
    };
    classe = {
      name: cl + ' - ' + desc_cl,
      checked: false,
      children: childrensClasse
    };
    embranchement = {
      name: emb,
      checked: false,
      children: childrensEmbranchement
    };
    regne = {
      name: kd,
      checked: false,
      children: childrensRegne
    };
    childrensOrdre.push(famille);
    childrensClasse.push(ordre);
    childrensEmbranchement.push(classe);
    childrensRegne.push(embranchement);
    formattedTree.push(regne);
    return formattedTree;
  }
}
