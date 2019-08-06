export function formatTaxonTree(taxonTree) {
  const formattedTree = [];
  let childrensRegne = [];
  let childrensEmbranchement = [];
  let childrensClasse = [];
  let childrensOrdre = [];
  //let childrensFamille = [];
  let kd = null;
  let emb = null;
  let cl = null;
  let desc_cl = null;
  let ord = null;
  let fam = null;
  let nouveauRegne = false;
  let nouvelEmbranchement = false;
  let nouvelleClasse = false;
  //let nouvelOrdre = false;
  //let nouvelleFamille = true;
  let leaf_ordre = {};
  let regne = {};
  let embranchement = {};
  let classe = {};
  let ordre = {};
  //let famille = {};

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

    //création d'un noeud final avec checkbox
    leaf_ordre = {
      id: record.cd_ref,
      name: record.nom_latin + ' - ' + record.nom_francais,
      classes: ['leaf'],
      leaf: true,
      checked: false
    };

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

    childrensClasse.push(leaf_ordre); //ajout du noeud au groupe

    kd = record.nom_regne; //kd prend la valeur en cours du groupe pour un nouveau test en début de boucle
    emb = record.nom_embranchement; //emb prend la valeur en cours du groupe pour un nouveau test en début de boucle
    cl = record.nom_classe; //cl prend la valeur en cours du groupe pour un nouveau test en début de boucle
    desc_cl = record.desc_classe; //
    //ord = record.nom_ordre; //ord prend la valeur en cours du groupe pour un nouveau test en début de boucle
    //fam = record.nom_famille; //fam prend la valeur en cours du groupe pour un nouveau test en début de boucle
  }); //fin de la boucle

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
  //childrensClasse.push(ordre);
  childrensEmbranchement.push(classe);
  childrensRegne.push(embranchement);
  formattedTree.push(regne);
  return formattedTree;
}
