import promisify from 'cypress-promise';


describe("Testing metadata", () => {

  const cadreAcq = " Données d'observation de la faune, de la Flore et de la fonge du Parc national des Ecrins"
  const jdd = ' Contact aléatoire tous règnes confondus '

  const newCadreAcq = {
      name:'Mon cadre d\'acquisition',
      description:'description de mon cadre d\'acquisition',
      startDate:"17/03/2022"
  }
  const newJdd = {
      name:'Mon jeu de données',
      shortname: "Mon jdd",
      description: 'description de mon jdd'
    }

  before(() => {
    cy.geonatureLogout();
    cy.geonatureLogin();
    cy.visit("/#/metadata")
  });

  it('should display "cadre d\'acquisition"', async () => {
    const listCadreAcq = await promisify(cy.get("[data-qa='pnx-metadata'] > div > div.card-body > mat-accordion > mat-expansion-panel.mat-expansion-panel.ng-tns-c206-6.ng-star-inserted"))
    const firstCadreAcqIntitule = listCadreAcq[0].firstChild.firstChild.firstChild.children[1].innerText
    
    expect(firstCadreAcqIntitule).to.equal("Données d'observation de la faune, de la Flore et de la fonge du Parc national des Ecrins\n57b7d0f2-4183-4b7b-8f08-6e105d476dc5")
  })

  it('should display the first "cadre d\'acquisition"', () => {
    cy.get('[data-qa="pnx-metadata-acq-framework-0"]').click()
    cy.get('[data-qa="pnx-metadata-acq-framework-name"]').contains(cadreAcq)
    cy.get('[data-qa="pnx-metadata-acq-framework-id"]').contains("1")
    cy.get('[data-qa="pnx-metadata-exit-af"]').click()
  })

  it('should display "jeux de données"', () => {
    cy.get('[data-qa="pnx-metadata-acq-framework-header-0"]').click()
    cy.get('[data-qa="pnx-metadata-jdd-1"]').contains(jdd)
    cy.get('[data-qa="pnx-metadata-jdd-actif-1"]').click()
    cy.get('[data-qa="pnx-metadata-jdd-nb-obs-1"]').contains("5")
		cy.get('[data-qa="pnx-metadata-jdd-delete-1"]').should('be.disabled')
  })

  it('should display the first "jeux de données"', () => {
    cy.get('[data-qa="pnx-metadata-jdd-1"]').click()
    cy.get('[data-qa="pnx-metadata-dataset-name"]').contains(jdd)
    cy.get('[data-qa="pnx-metadata-dataset-id"]').contains('1')
    cy.get('[data-qa="pnx-metadata-dataset-status"]').contains('Non')
    cy.get('[data-qa="pnx-metadata-exit-jdd"]').click()
  })

  it('should display the good "jeux de données"', () => {
    cy.get('[data-qa="pnx-metadata"] > div > div.card-body > div:nth-child(2) > div.form-group.col-sm-7 > input').type('contact')
    cy.get('[data-qa="pnx-metadata-jdd-1"]').contains(jdd)
    cy.get('[data-qa="pnx-metadata-jdd-actif-1"]').click()
  })

  // it('should create a new "cardre d\'acquisition"', () => {
  //   cy.get('[data-qa="pnx-metadata"] > div > div.card-body > div.row.ml-4.mb-4 > button.mat-focus-indicator.uppercase.mr-1.mat-raised-button.mat-button-base.mat-primary.ng-star-inserted').click()
    
  //   cy.get("[data-qa='pnx-af-form'] > div.row > div.col-md-4 > div:nth-child(1) > div.card-body > pnx-metadata-actor > div > form > ng-select > div > div > div.ng-input").click()
  //   cy.get('[data-qa="pnx-metadata-organism-ALL"]').click()
  //   cy.get("[data-qa='pnx-af-form'] > div.ml-1.mt-1 > button.mat-focus-indicator.button-success.mat-raised-button.mat-button-base").should('be.disabled')
    
  //   cy.get("[data-qa='pnx-af-form'] > div.row > div.col-md-8 > div > div > div:nth-child(2) > input").type(newCadreAcq.name)
  //   cy.get("[data-qa='pnx-af-form'] > div.ml-1.mt-1 > button.mat-focus-indicator.button-success.mat-raised-button.mat-button-base").should('be.disabled')

  //   cy.get('[data-qa="pnx-af-form"] > div.row > div.col-md-8 > div > div > div:nth-child(3) > textarea').type(newCadreAcq.description)
  //   cy.get("[data-qa='pnx-af-form'] > div.ml-1.mt-1 > button.mat-focus-indicator.button-success.mat-raised-button.mat-button-base").should('be.disabled')
    
  //   cy.get("[data-qa='pnx-af-form'] > div.row > div.col-md-8 > div > div > pnx-nomenclature:nth-child(8) > ng-select > div > div > div.ng-input").click()
  //   cy.get('[data-qa="Métropole"]').click()
  //   cy.get("[data-qa='pnx-af-form'] > div.ml-1.mt-1 > button.mat-focus-indicator.button-success.mat-raised-button.mat-button-base").should('be.disabled')
    
  //   cy.get("[data-qa='pnx-af-form'] > div.row > div.col-md-8 > div > div > pnx-nomenclature:nth-child(9) > ng-select > div > div > div.ng-input").click()
  //   cy.get('[data-qa="Niveau national"]').click()
  //   cy.get("[data-qa='pnx-af-form'] > div.ml-1.mt-1 > button.mat-focus-indicator.button-success.mat-raised-button.mat-button-base").should('be.disabled')
    
  //   cy.get("[data-qa='pnx-af-form'] > div.row > div.col-md-8 > div > div > pnx-nomenclature:nth-child(11) > ng-select > div > div > div.ng-input").click()
  //   cy.get('[data-qa="L\'acquisition des données est réalisée avec une démarche propre faisant intervenir plusieurs démarches préalablement décrites."]').click()
  //   cy.get("[data-qa='pnx-af-form'] > div.ml-1.mt-1 > button.mat-focus-indicator.button-success.mat-raised-button.mat-button-base").should('be.disabled')
    
  //   cy.get("[data-qa='pnx-af-form'] > div.row > div.col-md-8 > div > div > pnx-nomenclature:nth-child(13) > ng-select > div > div > div.ng-input").click()
  //   cy.get('[data-qa="Mélange de financement public et privé"]').click()
  //   cy.get("[data-qa='pnx-af-form'] > div.ml-1.mt-1 > button.mat-focus-indicator.button-success.mat-raised-button.mat-button-base").should('be.disabled')
    
  //   cy.get('[data-qa="pnx-af-form"] > div.row > div.col-md-8 > div > div > pnx-date:nth-child(16) > div > input').click().type(newCadreAcq.startDate)
  //   cy.get("[data-qa='pnx-af-form'] > div.ml-1.mt-1 > button.mat-focus-indicator.button-success.mat-raised-button.mat-button-base").click()
  // })

//   it('should new "jeux de données" created', () => {
//       cy.get('[data-qa="pnx-metadata-acq-framework-name"]').contains(newCadreAcq.name)
//   })

	it.only('should create a new "jeux de données"', () => {
		cy.get('[data-qa="pnx-metadata"] > div > div.card-body > div.row.ml-4.mb-4 > button:nth-child(2)').click()

		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')

		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-4 > div:nth-child(1) > div.card-body > pnx-metadata-actor > div > form > ng-select > div > div > div.ng-input').click()
		cy.get('[data-qa="pnx-metadata-organism-ALL"]').click()
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')

		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(1) > ng-select').click()
		cy.get('[data-qa="pnx-metadata-jdd-'+newCadreAcq.name+'"]').click()
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')

		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(2) > input').type(newJdd.name)
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')

		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(3) > div > input').type(newJdd.shortname)
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')
		
		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(4) > textarea').type(newJdd.description)
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')
	
		cy.get("[data-qa='pnx-dataset-form'] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(7) > div:nth-child(1) > pnx-nomenclature > ng-select > div > div > div.ng-input").click()
		cy.get('[data-qa="Non renseigné"]').click()
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')
	
		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(7) > div:nth-child(2) > pnx-nomenclature > ng-select > div > div > div.ng-input').click()
		cy.get('[data-qa="Collection : l\'observation concerne une base de données de collection."]').click()
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')
	
		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(8) > pnx-nomenclature > ng-select > div > div > div.ng-input').click()
		cy.get('[data-qa="Cas n’entrant pas clairement dans les autres rubriques. Dans ce cas les métadonnées (champ libres « description » et « protocole » des fiches de métadonnées) devront bien expliquer en quoi consiste le but de l’acquisition des données"]').click()
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')
	
		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(9) > pnx-nomenclature > ng-select > div > div > div.ng-input').click()
		cy.get('[data-qa="Clipperton"]').click()
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')

		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(10) > pnx-nomenclature > ng-select > div > div > div.ng-input').click()
		cy.get('[data-qa="Autre"]').click()
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')
	
		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(11) > div:nth-child(1) > pnx-nomenclature > ng-select > div > div > div.ng-input').click()
		cy.get('[data-qa="Ne sait pas : L\'information indiquant si la Donnée Source est publique ou privée n\'est pas connue."]').click()
		cy.get("[data-qa='pnx-dataset-form'] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base.mat-button-disabled").should('be.disabled')
		
		cy.get('[data-qa="pnx-dataset-form"] > div.row > div.col-md-8 > div > div.card-body > div:nth-child(11) > div:nth-child(2) > pnx-nomenclature > ng-select > div').click()
		cy.get('[data-qa="Jeu de données"]').click()

		cy.get('[data-qa="pnx-dataset-form"] > div.mr-1.mt-1 > button.mat-focus-indicator.button-success.ml-1.mat-raised-button.mat-button-base').click()
	})

	it.only('should new "jeux de données" created', () => {
		cy.get('[data-qa="pnx-metadata-dataset-name"]').contains(newJdd.name)
		cy.get('[data-qa="pnx-datasets-card"] > div:nth-child(1) > div > button').click()
	})

	it('should delete the new "jeux de données"', async () => {
    cy.get('[data-qa="pnx-metadata"] > div > div.card-body > div:nth-child(2) > div.form-group.col-sm-7 > input').clear()
		cy.get('[data-qa="pnx-metadata-acq-framework-header-1"]').click()
		const myCadreAcq = await promisify(cy.get('[data-qa="pnx-metadata-acq-framework-header-1"]'))
    const id = myCadreAcq[0].parentElement.childNodes[1].firstChild.firstChild.childNodes[1].childNodes[0].childNodes[0].innerText
		cy.get('[data-qa="pnx-metadata-jdd-nb-obs-'+id+'"]').contains("0")
		cy.get('[data-qa="pnx-metadata-jdd-delete-'+id+'"]').click()
		cy.get("#mat-dialog-0 > gn-confirmation-dialog > div.mat-dialog-actions > button.mat-focus-indicator.mat-raised-button.mat-button-base.mat-warn.cdk-focused.cdk-program-focused").click()
	})

	it('should display data of the "cadre d\'acquisition"', async () => {
    cy.get('[data-qa="pnx-metadata-acq-framework-header-0"]').click()
		cy.get('[data-qa="pnx-metadata-jdd-display-data-1"]').click()
		const listData = await promisify(cy.get("[data-qa='pnx-synthese'] > div > div.col-sm-12.col-md-5.padding-sm > pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller"))
		const elements = Array.from(listData[0].children);
		elements.forEach(data => {
			expect(data.children[0].children[1].children[4].innerText).contains("Contact aléatoire tous règnes confondus")
		})
	})

})