import promisify from 'cypress-promise';


describe("Testing occhab", () => {

  beforeEach(() => {
    cy.geonatureLogin();
  });

  it('should create an habitation', async () => {
    cy.visit("/#/occhab")

    const canvas = "[data-qa='pnx-occhab-form'] > div:nth-child(1) > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom"
    cy.get('#add-btn').click()

    cy.get('#validateButton').should('be.disabled')

    cy.get('[data-qa="pnx-occhab-form"] > div:nth-child(1) > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-left > div.leaflet-draw.leaflet-control > div:nth-child(1) > div > a').click()
    cy.get(canvas).click(250,250)
    cy.get(canvas).click(300,250)
    cy.get(canvas).click(300,300)
    cy.get(canvas).click(250,300)
    cy.get(canvas).click(250,250)
    cy.get('#validateButton').should('be.disabled')
    
    cy.get('[data-qa="gn-common-form-observers-select"]').click()
    cy.get('[data-qa="gn-common-form-observers-select-AGENT test"]').click()
    cy.get('#validateButton').should('be.disabled')
    
    cy.get('[data-qa="pnx-occhab-form-dataset"] > ng-select').click()
    cy.get('[data-qa="Carto d\'habitat X"]').click()
    cy.get('#validateButton').should('be.disabled')
    
    cy.get('[data-qa="pnx-occhab-form-geographic"] > div > select').select("1: Object")
    cy.get('#validateButton').should('be.disabled')

    cy.get('#add-hab-btn').click()
    cy.get('#taxonInput').type('dune')
    cy.get('#ngb-typeahead-3-0').click()
    cy.get('[data-qa="pnx-occhab-form-technique-collect"] > div > select').select('1: Object')
    cy.get('[data-qa="pnx-occhab-form-valid-button"]').click()

    cy.get('#validateButton').click()

    const listHabit = await promisify(cy.get('[data-qa="pnx-occhab-map-list-datatable"] > div > datatable-body > datatable-selection > datatable-scroller'))
    expect(listHabit[0].children[0].children[0].children[1].children[4].innerText).contains('Prés salés du contact haut schorre/dune')
    listHabit[0].children[0].children[0].children[1].children[2].children[0].children[0].click()
  })

})