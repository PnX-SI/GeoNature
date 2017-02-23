/**
 * @class application.cf.editFicheMortalite
 * Singleton to build the editFiche viewport
 *
 * @singleton
 */
 
 Ext.namespace("application.cf");

application.cf.editFicheMortalite = function() {
    // private variables 

    /**
     * Property: map
     * {OpenLayers.Map}
     */
    map = null;

    /**
     * Property: toolbar
     * {mapfish.widgets.ToolBar}
     */
    var toolbar = null;

    /**
     * Property: toolbarInitializedOnce
     * {Boolean} toolbar has already been initialized
     */
    var toolbarInitializedOnce = false;

    /**
     * Property: vectorLayer
     * {OpenLayers.Layer.Vector}
     */
    vectorLayer = null;

    /**
     * Property: dragPanControl
     */
    var dragPanControl = null;

    /**
     * Property: dragPointControl
     */
    var dragPointControl = null;

    /**
     * Property: store
     * {Ext.data.Store} The ap store (should contain only one record)
     */
    var store = null;

    /**
     * Property: protocol
     * {mapfish.Protocol.MapFish}
     */
    var protocol = null

    /**
     * Property: eventProtocol
     * {mapfish.Protocol.TriggerEventDecorator}
     */
    var eventProtocol = null;

    /**
     * Property: filterProtocol
     * {mapfish.Protocol.MergeFilterDecorator}
     */
    var filterProtocol = null;

    /**
     * Property: format
     * {<OpenLayers.Format.WKT>}
     */
    var format = new OpenLayers.Format.WKT();

    /**
     * APIProperty: id_cf
     * The id of fiche to update (if applies), null in case of a creating a new fiche
     */
    var id_cf = null;
    
    /**
     * APIProperty: old_cd_nom
     * The old cd_nom of the taxon to update
     */
    var old_taxon = null;

    /**
     * Property: layerTreeTip
     * {Ext.Tip} The layerTreeTip created with the factory
     */
    var layerTreeTip = null;

    /**
     * Property: firstGeometryLoad
     * {Boolean} is the geometry has been load once only
     */
    var firstGeometryLoad = true;
    
    /**
     * Property: myProxyTaxons
     * {Ext.data.HttpProxy} Url pour charger une liste de taxon fonction de l'unité ???
     */
     
    var myProxyReleves = null;
    
    /**
     * Property: myProxyReleves
     * {Ext.data.HttpProxy} Url pour charger une liste des releves de la fiche ???
     */
     
    var myProxyTaxons = null;
    /**
     * Property: maProjection
     * {Openlayers.Projection} définie ici sinon temps de retard lors de la création du point gps ???
     */
    var maProjection = null; 
    
    /**
     * Property: blankRecord
     * {Ext.data.Record} record vide pour la grid-taxons
     */
    var blankRecord = null;
    
    /**
     * Property: errorMsg
     * {string} message to display if taxon form is invalid or not complete
     */
    var errorMsg = '';
    
    // private functions

    /**
     * Method: initViewport
     */
    var initViewport = function() {
        return new Ext.Viewport({
            layout: 'border'
            ,defaults: {
                border: false
            }
            ,items: [
                getViewportCenterItem()
                ,getViewportEastItem()
                ,getViewportSouthItem()
            ]
            ,listeners: {
                show: initToolbarItems
                ,beforedestroy:function(){window.location.href = host_uri+'/'+app_uri;}
                ,afterlayout: function(){
                    map.baseLayer.redraw();
                }
            }
        });
    };
    /**
     * Method: getViewportSouthItem
     */
    var getViewportSouthItem = function() {
        return {
            region:"south"
            ,layout:'fit'
            ,height:45
            ,bbar: new Ext.Toolbar({           
                items: ['&copy; <a href="https://github.com/PnEcrins/GeoNature/" target="_blank">GeoNature</a>, développé par le <a href="http://www.ecrins-parcnational.fr" target="_blank">Parc national des Ecrins</a>', '->',
                application.cf.user.nom+' ('+application.cf.user.status+')',
                {
                    text: 'Déconnexion'
                    ,iconCls: 'logout'
                    ,handler: function() {
                        window.location.href = 'deconnexion' 
                    }
                },{
                    text: 'Accueil'
                    ,iconCls: 'home_mini'
                    ,handler: function() {
                        window.location.href = '/'+app_uri 
                    }
                }]
            })
        }
    };
    /**
     * Method: getViewportEastItem
     */
    var getViewportEastItem = function() {
        return {
            region: 'east'
            ,width: 600
            ,split: true
            ,autoScroll: true
            ,defaults: {
                border: false
            }
            ,items: [{
                id: 'edit-fiche-form'
                ,xtype: 'form'
                ,bodyStyle: 'padding: 5px'
                ,disabled: true
                ,defaults: {
                    xtype: 'numberfield'
                    ,labelWidth: 90
                    ,width: 180
                    ,anchor:'-15'
                }
                ,monitorValid:true
                ,items: [getFormItems(),getFormTaxons()]
                //pour version Extjs 3.4
                ,buttons:[{
                    text: 'Annuler'
                    ,xtype: 'button'
                    ,handler: function() {
                        Ext.Msg.confirm('Attention'
                            ,'Cette action va réinitialiser totalement le formulaire.<br>Si vous avez des données non enregistrées elles seront perdues.<br>Souhaitez poursuivre ?'
                            ,function(btn) {
                                if (btn == 'yes') {
                                    resetViewport();
                                    Ext.ux.Toast.msg('Information !', 'Aucune données n\'a été enregistrée, le formulaire a été réinitialisé.');
                                }
                                else{Ext.ux.Toast.msg('Action annulée', '');}
                            }
                            ,this // scope
                        );   
                    }
                    ,scope: this
                },{
                    text: 'Enregistrer'
                    ,xtype: 'button'
                    ,id: 'ficheSaveButton'
                    ,iconCls: 'action-save'
                    ,handler:function(){submitForm();}
                }]
            }]
        }
    };

    /**
     * Method: getViewportCenterItem
     */
    var getViewportCenterItem = function() {
        createMap();
        toolbar = new mapfish.widgets.toolbar.Toolbar({
            map: map,
            configurable: false
        });

        return {
            region: 'center'
            ,id: 'edit-fiche-mapcomponent'
            ,xtype: 'mapcomponent'
            ,map: map
            ,tbar: toolbar
        };
    };

    /**
     * Method: getFormItems
     * Creates the form items
     */
    var getFormItems = function() { 
        var comboObservateurs = new Ext.ux.form.SuperBoxSelect({
            id:'combo-fiche-observateurs'
            ,xtype:'superboxselect'
            ,fieldLabel: 'Observateur(s) ' 
            ,name: 'lesobservateurs'
            ,store: application.cf.storeObservateursCfAdd
            ,displayField: 'auteur'
            ,valueField: 'id_role'
            ,allowBlank: false
            ,resizable: true
            ,forceSelection : true
            ,selectOnFocus:true
            ,resizable: true
            ,mode: 'local'
            ,value: application.cf.user.id_utilisateur
            ,listeners:{
                afterrender :function(combo){
                    combo.setValue(application.cf.user.id_utilisateur);
                    Ext.getCmp('edit-fiche-form').getForm().findField('ids_observateurs').setValue(combo.getValue());
                }
                ,change:function(combo,newValue){
                    Ext.getCmp('edit-fiche-form').getForm().findField('ids_observateurs').setValue(newValue);
                    Ext.getCmp('edit-fiche-form').getForm().findField('ids_observateurs').setValue(newValue);
                }
                ,render: function(c) {
                    Ext.QuickTips.register({
                        target: c.getEl(),
                        text: 'Le ou les auteurs de l\'observation.'
                    });
                }
            }
        });
        var todayButton = new Ext.Button({
            id:'bt-today'
            ,text: 'aujourd\'hui'
            ,handler: function() {
                var d = new Date();
                Ext.getCmp('datefield-fiche-date').setValue(d);
            }
            ,scope: this
        });
        var yesterdayButton = new Ext.Button({
            id:'bt-yesterday'
            ,text: 'hier'
            ,handler: function() {
                var d = new Date();
                d.setDate(d.getDate() - 1);
                Ext.getCmp('datefield-fiche-date').setValue(d);
            }
            ,scope: this
        });
            
        return [{
            id:'hidden-idfiche'
            ,xtype:'hidden'
            ,name: 'id_cf'   
        },{
            xtype:'hidden'
            ,name: 'monaction'
        },{
            xtype:'hidden'
            ,name: 'id_organisme'
        },{
            xtype: 'hidden'
            ,name: 'geometry' 
        },{
            xtype:'hidden'
            ,name: 'ids_observateurs'
        },{
        // Fieldset 
        xtype:'fieldset'
        ,id:'fieldset-1-fiche'
        ,columnWidth: 1
        ,title: 'Renseignements concernant le pointage'
        ,collapsible: true
        ,autoHeight:true
        ,anchor:'98%'
        ,items :[comboObservateurs
            ,{
                xtype: 'compositefield'
                ,labelWidth: 80
                ,items: [
                {
                    id:'datefield-fiche-date'
                    ,fieldLabel: 'Date '
                    ,name: 'dateobs'
                    ,xtype:'datefield'
                    ,maxValue: new Date()
                    ,format: 'd/m/Y'
                    ,altFormats:'Y-m-d'
                    ,allowBlank: false
                    ,blankText:'La date de l\'observation est obligatoire'
                    // ,value: new Date()
                    ,listeners: {
                        render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl(),
                                text: 'Date de réalisation de l\'observation. Elle ne peut donc être postérieure à la date de saisie.'
                            });
                        }
                    }
                }
                ,todayButton
                ,yesterdayButton
                ,{
                    xtype: 'displayfield',
                    value: '  Altitude :'
                },{
                    id: 'fieldfiche-altitude'
                    ,xtype:'numberfield'
                    ,allowDecimals :false
                    ,allowNegative: false
                    // ,fieldLabel: 'Altitude '
                    ,name: 'altitude_saisie'
                    ,anchor: '40%'
                    ,listeners: {
                        render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl()
                                ,text: 'L\'altitude est calculée à partir d\'un service de l\'API Geoportail de l\'IGN. Vous pouvez la corriger si vous le souhaitez.'
                            });
                        }
                    }
                }]
            },{
                id:'fieldlabel-commune'
                ,xtype: 'displayfield'
                ,value: 'Commune : inconnue'
            }
            ]
        } //fin du groupe 1  
        ] //fin du return
    };
    /**
     * Method: getFormTaxons
     *
     * Dans ce formulaire, les données saisies à droite sont enregistrées dans le store
     * de la grille de gauche en temps réel (sur keyup ou sur select pour les combo).
     * Une fonction invoquée sur chaque modification des champs obligatoires vérifie
     * si l'ensemble du formulaire est valid ou non.
     * si oui on active le bouton enregister, sinon l'enregistrement est impossible.
     */
    var getFormTaxons = function(){
        var relevesStoreFields = [
                {name: 'id_releve_cf', type: 'integer'}
                ,{name: 'id_nom', type: 'integer'}
                ,{name: 'nom_francais', type: 'string',sortType: Ext.data.SortTypes.asAccentuatedString}
                ,{name: 'nom_latin', type: 'string'}
                ,{name: 'nom_taxon_saisi', type: 'string',sortType: Ext.data.SortTypes.asAccentuatedString}
                ,{name: 'sexeage', type: 'string'}
                ,{name: 'sexeageinfo', type: 'string'}
                ,{name: 'am', type: 'integer'}
                ,{name: 'af', type: 'integer'}
                ,{name: 'ai', type: 'integer'}
                ,{name: 'na', type: 'integer'}
                ,{name: 'jeune', type: 'integer'}
                ,{name: 'yearling', type: 'integer'}
                ,{name: 'sai', type: 'integer'}
                ,{name: 'commentaire', type: 'string'}
                ,{name: 'cd_ref_origine', type: 'integer'}
                ,{name: 'denombrement', type: 'integer'}
                ,{name: 'id_classe', type: 'integer'}
                ,{name: 'prelevement', type: 'boolean'}
                ,{name: 'determinateur', type: 'string'}
            ];
            
        myProxyReleves = new Ext.data.HttpProxy({
            id:'store-releve-proxy'
            ,url: 'cf/listreleves'
            ,method: 'GET'
        });
        var relevesStore = new Ext.data.JsonStore({
            url: myProxyReleves
            ,sortInfo: {
                field: 'nom_francais'
                ,direction: 'ASC'
            }
            ,fields: relevesStoreFields
            ,listeners: {
                load: function(store, records) {
                    Ext.getCmp('grid-taxons').getSelectionModel().selectRow(0);
                    var sexeage;
                    if(Ext.getCmp('radiogroup-sexeage').getValue()){
                        sexeage = Ext.getCmp('radiogroup-sexeage').getValue().initialConfig.boxLabel;
                    }
                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeageinfo',sexeage);
                    // Ext.getCmp('combo-fiche-taxon').fireEvent('change');
                }
            }
        });

        //record vide pour le bouton ajouter un taxon
        blankRecord =  Ext.data.Record.create(relevesStoreFields);

        var colModel = new Ext.grid.ColumnModel([
            {header: "Id", width: 55,  sortable: true, dataIndex: 'id_nom',hidden:true}
            ,{id:'taxonfr',header: "Taxons déjà saisis", width: 160, sortable: true, locked:false, dataIndex: 'nom_francais',hidden:true}
            ,{header: "Sexe et âge", width: 160, sortable: true, locked:false, dataIndex: 'sexeage',hidden:true}
            ,{header: "Mâle", width: 35, sortable: true, dataIndex: 'am',hidden:true}
            ,{header: "Femelle", width: 35, sortable: true, dataIndex: 'af',hidden:true}
            ,{header: "Indéterminé", width: 35, sortable: true, dataIndex: 'ai',hidden:true}
            ,{header: "Non Adulte", width: 35, sortable: true, dataIndex: 'na',hidden:true}
            ,{header: "Sexe & Age Indéterminé", width: 35, sortable: true, dataIndex: 'sai',hidden:true}
            ,{header: "Jeune", width: 35, sortable: true, dataIndex: 'jeune',hidden:true}
            ,{header: "Yearling", width: 35, sortable: true, dataIndex: 'yearling',hidden:true}
            ,{header: "Commentaire", width: 135, sortable: true, dataIndex: 'commentaire',hidden:true}
            ,{header: "Déterminateur", width: 135, sortable: true, dataIndex: 'determinateur',hidden:true}
            ,{header: "id_classe", width: 135, sortable: true, dataIndex: 'id_classe',hidden:true}
            ,{id:'taxonsaisi',header: "Taxons saisis", width: 160, sortable: true, dataIndex: 'nom_taxon_saisi',hidden:true}
            ,{id:'sexeageinfo',header: "Sexe et âge de l'individu", width: 160, sortable: true, dataIndex: 'sexeageinfo'}
            ,{header: "cd_ref", width: 135, sortable: true, dataIndex: 'cd_ref_origine',hidden:true}
            ,{header: "Prélèvement", width: 35, sortable: true, dataIndex: 'prelevement',hidden:true}
            ,{
                xtype : 'actioncolumn'
                ,sortable : false
                ,hideable : false
                ,menuDisabled : true
                ,width:20
                ,items : [{
                    tooltip : 'Supprimer cet individu du pointage'
                    ,getClass : function(v, meta, record, rowIndex, colIdx, store) {
                        return 'action-remove';
                    }
                    ,scope : this
                    ,handler : function(grid, rowIndex, colIndex) {
                        var record = grid.getStore().getAt(rowIndex);
                        if(!record.data.id_nom){
                            grid.getStore().remove(record);
                            if(Ext.getCmp('grid-taxons').getStore().getCount()==0){
                                this.addNewIndividu();
                                Ext.ux.Toast.msg('Information !', 'Vous avez supprimé tous les individus de ce pointage.');
                            }
                            else{
                                Ext.getCmp('grid-taxons').getSelectionModel().selectRow(0);
                                Ext.ux.Toast.msg('Annulation !', 'La saisie d\'un nouvel individu de taxon a été annulée.');
                            }
                        }
                        else{
                            Ext.Msg.confirm('Attention !'
                                ,'Etes-vous certain de vouloir supprimer l\'individu de "'+record.data.nom_francais+'" ?'
                                ,function(btn) {
                                    if (btn == 'yes') {
                                        grid.getStore().remove(record);
                                        if(Ext.getCmp('grid-taxons').getStore().getCount()==0){
                                            this.addNewIndividu();
                                            Ext.ux.Toast.msg('Suppression !', 'L\'individu de "'+record.data.nom_francais+'" a été supprimé de ce pointage. Vous avez supprimé tous les individus de ce pointage.');
                                        }
                                        else{
                                            Ext.getCmp('grid-taxons').getSelectionModel().selectRow(0);
                                            Ext.ux.Toast.msg('Suppression !', 'L\'individu de "'+record.data.nom_francais+'" a été supprimé de ce pointage.');
                                        }
                                    }
                                }
                                ,this // scope
                            );
                        }
                        Ext.getCmp('combo-fiche-critere').setWidth(200);//debug sinon le combo apparait avec une largeur ridicule
                        Ext.getCmp('combo-fiche-critere').syncSize();//debug sinon le combo apparait avec une largeur ridicule
                    }
                }]
            }
        ]);

        myProxyTaxons = new Ext.data.HttpProxy({
            id:'store-taxon-proxy'
            ,url: 'bibs/taxonscf'
            ,method: 'GET'
        });
        var comboTaxonsFiltre = function(){
            Ext.getCmp('combo-fiche-taxon').getStore().filterBy(function(record,id){
                var id_classe = record.data.id_classe;
                if(comboTaxonsFiltreClasse(id_classe)){return true;}
                if(comboTaxonsFiltreClasse(id_classe)){return true;}
                if(comboTaxonsFiltreClasse(id_classe)){return true;}
                return false;
            });
        };
        var comboTaxonsFiltreClasse = function(classe){
            var amphibiens = Ext.getCmp('cb-amphibiens-cf').getValue();
            var mammiferes = Ext.getCmp('cb-mammiferes-cf').getValue();
            var oiseaux = Ext.getCmp('cb-oiseaux-cf').getValue();
            var poissons = Ext.getCmp('cb-poissons-cf').getValue();
            var reptiles = Ext.getCmp('cb-reptiles-cf').getValue();
            if((!amphibiens&&!mammiferes&&!oiseaux&&!poissons&&!reptiles)==true){return true;}
            if(oiseaux && classe==id_classe_oiseaux){return true;}
            if(mammiferes && classe==id_classe_mammiferes){return true;}
            if(amphibiens && classe==id_classe_amphibiens){return true;}
            if(reptiles && classe==id_classe_reptiles){return true;}
            if(poissons && classe==id_classe_poissons){return true;}
            return false;
        };

        /*** SOLUTION ATOL ***/
        var comboTaxonsTemplate = function(langue) {
            var dataIndex = (langue == 'latin'?'nom_latin':'nom_francais');
            var comboFicheTaxon = Ext.getCmp('combo-fiche-taxon');
            comboFicheTaxon.getStore().sort(dataIndex);
            var monTpl = new Ext.XTemplate(
                '<tpl for=".">'+
                '   <div class="x-combo-list-item">'+
                '       {'+dataIndex+'}'+
                '   </div>'+
                '</tpl>');
            if(Ext.isDefined(comboFicheTaxon.view)){
                comboFicheTaxon.view.tpl = monTpl;
                comboFicheTaxon.view.refresh();
            }
        };  
        var isValidForm = function(){
            var isValid = true;
            Ext.getCmp('grid-taxons').getStore().each(function(r){
                if(r.data.id_nom==0 || r.data.id_nom==null){isValid = false;return false;}
                if(r.data.sexeageinfo=='Saisie en cours'){isValid = false;return false;}
            });
            return isValid;
        }; 
        var isValidTaxon = function(r){
            var isValid = true;
            errorMsg = '';
            if(r.data.id_nom==0 || r.data.id_nom==null){
                isValid = false;
                errorMsg='Veuillez choisir un taxon';
            }
            if(!Ext.getCmp('radiogroup-sexeage').isValid()){
                isValid = false;
                errorMsg='Veuillez choisir une classe d\'âge pour cet individu';
            }
            var commentValue = Ext.getCmp('ta-fiche-commentaire').getValue();
            if(Ext.getCmp('cb-prelevement').getValue() && (commentValue == null || commentValue == '')){
                isValid = false;
                errorMsg='Un commentaire est obligatoire en cas de prélèvement';
            }
            return isValid;
        };
        var manageValidationTaxon = function(isValid){
            if(isValid){
                Ext.getCmp('grid-taxons').enable();
                Ext.getCmp('bt-validtaxon').enable();
                Ext.getCmp('bt-validtaxon').setIconClass('validate');
                Ext.getCmp('bt-validtaxon').setText('Valider');
            }
            else{
                if(!Ext.getCmp('grid-taxons').getSelectionModel().hasNext() && Ext.getCmp('grid-taxons').getSelectionModel().getSelected().data.id_nom==null){
                    Ext.getCmp('grid-taxons').enable();
                }
                else{Ext.getCmp('grid-taxons').disable();}
                Ext.getCmp('bt-validtaxon').disable();
                Ext.getCmp('bt-validtaxon').setIconClass('unvalidate');
                Ext.getCmp('bt-validtaxon').setText('Terminer la saisie pour valider ');
                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeageinfo','Saisie en cours');
            }
            Ext.getCmp('error-message').setText(errorMsg);
            manageValidationForm(isValidForm())
        };
        var manageValidationForm = function(isValid){
            if(isValid){
                Ext.getCmp('ficheSaveButton').enable();
                Ext.getCmp('bt-addtaxon').enable();
            }
            else{
                Ext.getCmp('ficheSaveButton').disable();
                Ext.getCmp('bt-addtaxon').disable();
            }
        };
        var returnTaxonSaisi = function(){
            var r = null;
            if(Ext.getCmp('combo-fiche-taxon').findRecord('id_nom',Ext.getCmp('combo-fiche-taxon').getValue())){
                r = Ext.getCmp('combo-fiche-taxon').findRecord('id_nom',Ext.getCmp('combo-fiche-taxon').getValue());
            }
            if(Ext.getCmp('radiogroup-langue-cf').getValue().inputValue=='fr'){
                if(r){return r.data.nom_francais;}
                else{return 'en cours';}
            }
            if(Ext.getCmp('radiogroup-langue-cf').getValue().inputValue=='latin'){
                if(r){return r.data.nom_latin;}
                else{return 'en cours';}
            }
        };
        var manageDenombrementFields = function(rec,reset){
            var n = rec.data.denombrement;
            if(n==5){
                Ext.getCmp('radio-jeune').hideItem();
                Ext.getCmp('radio-yearling').hideItem();
                Ext.getCmp('radio-na').showItem();
            }
            if(n==6){
                Ext.getCmp('radio-jeune').showItem();
                Ext.getCmp('radio-yearling').showItem();
                Ext.getCmp('radio-na').hideItem();
            }
            if(reset){
                Ext.getCmp('radio-jeune').setValue(0);
                Ext.getCmp('radio-yearling').setValue(0);
                Ext.getCmp('radio-na').setValue(0);
            }
        }
        this.addNewIndividu = function(){
            Ext.getCmp('edit-fiche-form').getForm().findField('monactiontaxon').setValue('add');
            relevesStore.add(new blankRecord({
                //attention l'ordre des champs est important
                id_releve_cf:null
                ,id_nom:null
                ,nom_francais:''
                ,nom_latin:''
                ,nom_taxon_saisi: ''
                ,sexeage:''
                ,sexeageinfo:'Saisie en cours'
                ,am:0
                ,af:0
                ,ai:0
                ,na:0
                ,jeune:0
                ,yearling:0
                ,sai:0
                ,commentaire:''
                ,cd_ref_origine:null
                ,denombrement:5
                ,id_classe:null
                ,prelevement:false
                ,determinateur:''
            }));
            Ext.getCmp('fieldset-sexeage').collapse();
            Ext.getCmp('fieldset-prelevement').collapse();
            Ext.getCmp('fieldset-commentaire').collapse();
            Ext.getCmp('fieldset-determinateur').collapse();
            Ext.getCmp('grid-taxons').getSelectionModel().selectLastRow(false);
            manageValidationTaxon(false); 
        };
        var resetSexeAgeValue = function(){
            Ext.getCmp('edit-fiche-form').getForm().findField('am').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('am',0);
            Ext.getCmp('radio-am').setValue(false);
            Ext.getCmp('edit-fiche-form').getForm().findField('af').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('af',0);
            Ext.getCmp('radio-af').setValue(false);
            Ext.getCmp('edit-fiche-form').getForm().findField('ai').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('ai',0);
            Ext.getCmp('radio-ai').setValue(false);
            Ext.getCmp('edit-fiche-form').getForm().findField('na').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('na',0);
            Ext.getCmp('radio-na').setValue(false);
            Ext.getCmp('edit-fiche-form').getForm().findField('jeune').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('jeune',0);
            Ext.getCmp('radio-jeune').setValue(false);
            Ext.getCmp('edit-fiche-form').getForm().findField('yearling').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('yearling',0);
            Ext.getCmp('radio-yearling').setValue(false);
            Ext.getCmp('edit-fiche-form').getForm().findField('sai').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sai',0);
            Ext.getCmp('radio-sai').setValue(false);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeageinfo','Saisie en cours');
        }
        var resetSexeAgeGridValue = function(){
            Ext.getCmp('edit-fiche-form').getForm().findField('am').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('am',0);
            Ext.getCmp('edit-fiche-form').getForm().findField('af').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('af',0);
            Ext.getCmp('edit-fiche-form').getForm().findField('ai').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('ai',0);
            Ext.getCmp('edit-fiche-form').getForm().findField('na').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('na',0);
            Ext.getCmp('edit-fiche-form').getForm().findField('jeune').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('jeune',0);
            Ext.getCmp('edit-fiche-form').getForm().findField('yearling').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('yearling',0);
            Ext.getCmp('edit-fiche-form').getForm().findField('sai').setValue(0);
            Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sai',0);
        }    
        if(application.cf.user.statuscode >= 2){
            var validTaxonButton = new Ext.Button({
                id:'bt-validtaxon'
                ,iconCls: 'unvalidate'
                ,text: 'Terminer la saisie pour valider'
                ,disabled: true
                ,handler: function() {
                var sexeage = '';
                    if(Ext.getCmp('radiogroup-sexeage').getValue()){
                        sexeage = Ext.getCmp('radiogroup-sexeage').getValue().initialConfig.boxLabel;
                    }
                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeageinfo',sexeage);
                    manageValidationForm(isValidForm());
                }
                ,scope: this
            });
        }
        if(application.cf.user.statuscode >= 2){
            var addTaxonButton = new Ext.Button({
                id:'bt-addtaxon'
                ,iconCls: 'add'
                ,text: 'Ajouter un individu sur ce pointage'
                ,disabled: true
                ,handler: function() {
                    oldTaxon = Ext.getCmp('grid-taxons').getSelectionModel().getSelected().get('id_nom');
                    var monStore = Ext.getCmp('combo-fiche-taxon').getStore();
                    var regId = new RegExp ("^"+oldTaxon+"$",'gi');
                    var rec = monStore.getAt(monStore.find('id_nom',regId));
                    this.addNewIndividu();
                    Ext.getCmp('combo-fiche-taxon').setValue(oldTaxon);
                    Ext.getCmp('combo-fiche-taxon').fireEvent('select',Ext.getCmp('combo-fiche-taxon'),rec);
                    Ext.getCmp('radio-am').focus();
                }
                ,scope: this
            });
        }
        
        storeTaxonsCf = new Ext.data.JsonStore({
            url: myProxyTaxons
            ,fields: [
                'id_nom'
                ,'cd_ref'
                ,'nom_latin'
                ,{name:'nom_francais',sortType: Ext.data.SortTypes.asAccentuatedString}
                ,'id_classe'
                ,'denombrement'
                ,'message'
            ]
            ,sortInfo: {
                field: 'nom_francais'
                ,direction: 'ASC'
            }
            ,autoLoad:true
            ,listeners: {
                load: function(store, records) {
                    if(Ext.getCmp('grid-taxons').getSelectionModel().getSelected()){
                        Ext.getCmp('combo-fiche-taxon').setValue(Ext.getCmp('grid-taxons').getSelectionModel().getSelected().data.id_nom);
                    }
                    comboTaxonsFiltre();
                }
            }
        });
        /*
         *    création du formulaire taxon
         */
        var gridForm = new Ext.Panel({
            id: 'taxons-form'
            ,frame: true
            ,labelAlign: 'left'
            ,title: 'Liste des individus trouvés morts'
            ,bodyStyle:'padding:5px'
            ,width: 600
            ,layout: 'column'    // Specifies that the items will now be arranged in columns
            ,items: [{
                columnWidth: 0.6
                ,xtype: 'panel'
                // ,layout: 'form'
                ,labelWidth: 80
                // ,title:'Détails de l\'observation'
                ,defaults: {
                    width: 305
                    ,border:false
                    ,allowDecimals :false
                    ,allowNegative: false 
                }    
                ,defaultType: 'numberfield'
                ,autoHeight: true
                ,bodyStyle: Ext.isIE ? 'padding:0 0 5px 5px;' : 'padding:5px 5px;'
                ,border: false
                ,style: {
                    "margin-left": "5px", // when you add custom margin in IE 6...
                    "margin-right": Ext.isIE6 ? (Ext.isStrict ? "-10px" : "-13px") : "0"  // you have to adjust for it somewhere else
                }
                ,items: [
                {
                    xtype:'fieldset'
                    ,id:'fieldset-taxons'
                    ,columnWidth: 1
                    ,title: 'Choix du taxon observé'
                    ,collapsible: true
                    ,autoHeight:true
                    ,anchor:'100%'
                    ,items :[
                        {
                            id:'radiogroup-langue-cf'
                            ,xtype: 'radiogroup'
                            ,fieldLabel: 'Langue'
                            ,defaultType: 'radio'
                            ,cls:'graytext'
                            ,itemCls:'graytext'
                            ,items: [{
                                    boxLabel: 'français'
                                    ,name: 'langue'
                                    ,itemCls:'graytext'
                                    ,inputValue: 'fr'                                 
                                    ,checked: true
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                comboTaxonsTemplate('fr');
                                                Ext.getCmp('combo-fiche-taxon').displayField = 'nom_francais';
                                                Ext.getCmp('combo-fiche-taxon').setValue(Ext.getCmp('combo-fiche-taxon').getValue());//pas trouvé mieux pour rafraichier en live le taxon déjà affiché dans le combo
                                            }
                                        }
                                    }
                                },{
                                    boxLabel: 'latin'
                                    ,name: 'langue'
                                    ,itemCls:'graytext'
                                    ,inputValue: 'latin' 
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                comboTaxonsTemplate('latin');
                                                Ext.getCmp('combo-fiche-taxon').displayField = 'nom_latin';
                                                Ext.getCmp('combo-fiche-taxon').setValue(Ext.getCmp('combo-fiche-taxon').getValue());//pas trouvé mieux pour rafraichier en live le taxon déjà affiché dans le combo
                                            }
                                        }
                                    }
                                }
                            ]
                        },{
                            id:'checkboxgroup-classe-cf'
                            ,xtype: 'checkboxgroup'
                            ,fieldLabel: 'Groupe taxonomique'
                            ,cls:'graytext'
                            ,itemCls:'graytext'
                            ,columns: 2
                            ,items:[{
                                    id:'cb-mammiferes-cf'
                                    ,boxLabel: 'Mammifères'
                                    ,name: 'cb-mammiferes'
                                    ,itemCls:'graytext'
                                    ,checked: false                                    
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                Ext.getCmp('cb-oiseaux-cf').setValue(false);
                                                Ext.getCmp('cb-reptiles-cf').setValue(false);
                                                Ext.getCmp('cb-amphibiens-cf').setValue(false);
                                                Ext.getCmp('cb-poissons-cf').setValue(false);
                                            }
                                            if(Ext.getCmp('combo-fiche-taxon')){
                                                Ext.getCmp('combo-fiche-taxon').clearValue();
                                            }
                                            comboTaxonsFiltre();
                                        }
                                        ,render: function(c) {
                                            Ext.QuickTips.register({
                                                target: c.getEl(),
                                                text: 'Affiche les mammifères dans la liste si la case est cochée.'
                                            });
                                        }
                                    }                                
                                },{
                                    id:'cb-oiseaux-cf'
                                    ,boxLabel: 'Oiseaux'
                                    ,name: 'cb-oiseaux'
                                    ,itemCls:'graytext'
                                    ,checked: false                                    
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                Ext.getCmp('cb-mammiferes-cf').setValue(false);
                                                Ext.getCmp('cb-reptiles-cf').setValue(false);
                                                Ext.getCmp('cb-amphibiens-cf').setValue(false);
                                                Ext.getCmp('cb-poissons-cf').setValue(false);
                                            }
                                            if(Ext.getCmp('combo-fiche-taxon')){
                                                Ext.getCmp('combo-fiche-taxon').clearValue();
                                            }
                                            comboTaxonsFiltre();
                                        }
                                        ,render: function(c) {
                                            Ext.QuickTips.register({
                                                target: c.getEl(),
                                                text: 'Affiche les oiseaux dans la liste si la case est cochée.'
                                            });
                                        }
                                    }                                
                                },{
                                    id:'cb-reptiles-cf'
                                    ,boxLabel: 'Reptiles'
                                    ,name: 'cb-reptiles'
                                    ,itemCls:'graytext'
                                    ,checked: false                                    
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                Ext.getCmp('cb-mammiferes-cf').setValue(false);
                                                Ext.getCmp('cb-oiseaux-cf').setValue(false);
                                                Ext.getCmp('cb-amphibiens-cf').setValue(false);
                                                Ext.getCmp('cb-poissons-cf').setValue(false);
                                            }
                                            if(Ext.getCmp('combo-fiche-taxon')){
                                                Ext.getCmp('combo-fiche-taxon').clearValue();
                                            }
                                            comboTaxonsFiltre();
                                        }
                                        ,render: function(c) {
                                            Ext.QuickTips.register({
                                                target: c.getEl(),
                                                text: 'Affiche les reptiles dans la liste si la case est cochée.'
                                            });
                                        }
                                    }                                
                                },{
                                    id:'cb-amphibiens-cf'
                                    ,boxLabel: 'Amphibiens'
                                    ,name: 'cb-amphibiens'
                                    ,itemCls:'graytext'                                    
                                    ,checked: false
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                Ext.getCmp('cb-mammiferes-cf').setValue(false);
                                                Ext.getCmp('cb-oiseaux-cf').setValue(false);
                                                Ext.getCmp('cb-reptiles-cf').setValue(false);
                                                Ext.getCmp('cb-poissons-cf').setValue(false);
                                            }
                                            if(Ext.getCmp('combo-fiche-taxon')){
                                                Ext.getCmp('combo-fiche-taxon').clearValue();
                                            }
                                            comboTaxonsFiltre();
                                        }
                                        ,render: function(c) {
                                            Ext.QuickTips.register({
                                                target: c.getEl(),
                                                text: 'Affiche les amphibiens dans la liste si la case est cochée.'
                                            });
                                        }
                                    }
                                },{
                                    id:'cb-poissons-cf'
                                    ,boxLabel: 'Poissons'
                                    ,name: 'cb-poissons'
                                    ,itemCls:'graytext'
                                    ,checked: false                                    
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                Ext.getCmp('cb-mammiferes-cf').setValue(false);
                                                Ext.getCmp('cb-oiseaux-cf').setValue(false);
                                                Ext.getCmp('cb-reptiles-cf').setValue(false);
                                                Ext.getCmp('cb-amphibiens-cf').setValue(false);
                                            }
                                            if(Ext.getCmp('combo-fiche-taxon')){
                                                Ext.getCmp('combo-fiche-taxon').clearValue();
                                            }
                                            comboTaxonsFiltre();
                                        }
                                        ,render: function(c) {
                                            Ext.QuickTips.register({
                                                target: c.getEl(),
                                                text: 'Affiche uniquement les poissons dans la liste si la case est cochée.'
                                            });
                                        }
                                    }                                
                                }
                            ]
                        },{
                            xtype: 'line'
                        },{
                            id:'combo-fiche-taxon'
                            ,xtype:'twintriggercombo'
                            ,tpl: '<tpl for="."><div class="x-combo-list-item"> {nom_francais}</div></tpl>'
                            ,fieldLabel: 'Taxon '
                            ,name: 'id_nom'
                            ,hiddenName:"id_nom"
                            ,store: storeTaxonsCf
                            ,valueField: "id_nom"
                            ,displayField: "nom_francais"
                            ,allowBlank:false
                            ,typeAhead: true
                            ,typeAheadDelay:750
                            ,forceSelection: true
                            ,selectOnFocus: true
                            ,editable: true
                            ,resizable:true
                            ,listWidth: 300
                            ,triggerAction: 'all'
                            ,trigger3Class: 'x-form-zoomto-trigger x-hidden'
                            ,mode: 'local'
                            ,listeners: {
                                select: function(combo, record) { 
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('nom_francais',record.data.nom_francais);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('nom_latin',record.data.nom_latin);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('id_nom',combo.getValue());
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('id_classe',record.data.id_classe);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('denombrement',record.data.denombrement);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('cd_ref_origine',record.data.cd_ref);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('nom_taxon_saisi',returnTaxonSaisi());
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeageinfo','Saisie en cours');
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeage','');
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('prelevement',false);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('commentaire',null);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('determinateur',null);
                                    resetSexeAgeValue();
                                    Ext.getCmp('cb-prelevement').setValue(false);
                                    Ext.getCmp('ta-fiche-commentaire').validate();
                                    Ext.getCmp('ta-fiche-commentaire').setValue('');
                                    Ext.getCmp('ta-fiche-determinateur').setValue('');
                                    manageValidationTaxon(isValidTaxon(record));
                                    manageDenombrementFields(record,true);
                                    Ext.getCmp('fieldset-sexeage').expand();
                                }
                                ,change: function(combo, record) {
                                    if(record.data){
                                        manageValidationTaxon(isValidTaxon(record));
                                        manageDenombrementFields(record,false);
                                    }
                                }
                                ,afterrender: function(combo, record) {
                                    comboTaxonsFiltre();
                                    combo.keyNav.tab = function() { // Override TAB handling function
                                        this.onViewClick(false); // Select the currently highlighted row
                                    };
                                }
                                ,clear: function(combo, record) {
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('nom_francais',null);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('nom_latin',null);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('id_nom',null);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('id_classe',null);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('denombrement',5);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('cd_ref_origine',null);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('nom_taxon_saisi',null);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeageinfo','Saisie en cours');
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeage','');
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('prelevement',false);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('commentaire',null);
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('determinateur',null);
                                    resetSexeAgeValue();
                                    Ext.getCmp('cb-prelevement').setValue(false);
                                    Ext.getCmp('ta-fiche-commentaire').validate();
                                    Ext.getCmp('ta-fiche-commentaire').setValue('');
                                    Ext.getCmp('ta-fiche-determinateur').setValue('');
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('commentaire',null);
                                    Ext.getCmp('fieldset-sexeage').collapse();
                                    Ext.getCmp('fieldset-prelevement').collapse();
                                    Ext.getCmp('fieldset-commentaire').collapse();
                                    Ext.getCmp('fieldset-determinateur').collapse();
                                    manageValidationTaxon(isValidTaxon(Ext.getCmp('grid-taxons').getSelectionModel().getSelected()));
                                }
                            }
                        }
                    ]
                },{
                    xtype:'fieldset'
                    ,id:'fieldset-sexeage'
                    ,columnWidth: 1
                    ,title: 'Sexe et âge de l\'individu'
                    ,collapsible: true
                    ,collapsed: true
                    ,autoHeight:true
                    ,anchor:'100%'
                    ,items: [
                        {
                            id:'radiogroup-sexeage'
                            ,xtype: 'radiogroup'
                            ,fieldLabel: 'Sexe et âge'
                            ,columns: 2
                            ,defaultType: 'radio'
                            ,allowBlank:false
                            ,blankText:'Vous devez obligatoirement décrire la catégorie sexe et âge de cet individu.'
                            ,items: [
                                {
                                    id:'radio-am'
                                    ,boxLabel: 'Ad mâle'
                                    ,name: 'sexeage'
                                    ,inputValue: 'am'                                 
                                    ,checked: false
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                resetSexeAgeGridValue();
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeage','am');
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('am',1);
                                                Ext.getCmp('edit-fiche-form').getForm().findField('am').setValue(1);
                                            }  
                                        }
                                    }
                                },{
                                    id:'radio-af'
                                    ,boxLabel: 'Ad femelle'
                                    ,name: 'sexeage'
                                    ,inputValue: 'af'
                                    ,checked: false                                    
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                resetSexeAgeGridValue();
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeage','af');
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('af',1);
                                                Ext.getCmp('edit-fiche-form').getForm().findField('af').setValue(1);
                                            }  
                                        }
                                    }
                                },{
                                    id:'radio-ai'
                                    ,boxLabel: 'Ad indéterminé'
                                    ,name: 'sexeage'
                                    ,inputValue: 'ai'
                                    ,checked: false 
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                resetSexeAgeGridValue();
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeage','ai');
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('ai',1);
                                                Ext.getCmp('edit-fiche-form').getForm().findField('ai').setValue(1);
                                            }  
                                        }
                                    }
                                },{
                                    id:'radio-na'
                                    ,boxLabel: 'Non adulte'
                                    ,name: 'sexeage'
                                    ,inputValue: 'na'
                                    ,checked: false 
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                resetSexeAgeGridValue();
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeage','na');
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('na',1);
                                                Ext.getCmp('edit-fiche-form').getForm().findField('na').setValue(1);
                                            }  
                                        }
                                    }
                                },{
                                    id:'radio-jeune'

                                    ,boxLabel: 'Jeune'
                                    ,name: 'sexeage'
                                    ,inputValue: 'jeune'
                                    ,checked: false 
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                resetSexeAgeGridValue();
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeage','jeune');
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('jeune',1);
                                                Ext.getCmp('edit-fiche-form').getForm().findField('jeune').setValue(1);
                                            }  
                                        }
                                    }
                                },{
                                    id:'radio-yearling'

                                    ,boxLabel: 'Yearling'
                                    ,name: 'sexeage'
                                    ,inputValue: 'yearling'
                                    ,checked: false
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                resetSexeAgeGridValue();
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeage','yearling');
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('yearling',1);
                                                Ext.getCmp('edit-fiche-form').getForm().findField('yearling').setValue(1);
                                            }  
                                        }
                                    }
                                },{
                                    id:'radio-sai'
                                    ,boxLabel: 'Sexe et âge indéterminé'
                                    ,name: 'sexeage'
                                    ,inputValue: 'sai'
                                    ,checked: false
                                    ,listeners: {
                                        check: function(checkbox,checked) {
                                            if(checked){
                                                resetSexeAgeGridValue();
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sexeage','sai');
                                                Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('sai',1);
                                                Ext.getCmp('edit-fiche-form').getForm().findField('sai').setValue(1);
                                            }  
                                        }
                                    }
                                }
                            ]
                            ,listeners: {
                                change: function(radiogroup,checked) {
                                    manageValidationTaxon(isValidTaxon(Ext.getCmp('grid-taxons').getSelectionModel().getSelected()));
                                    if(checked){Ext.getCmp('fieldset-prelevement').expand();}
                                    else{Ext.getCmp('fieldset-prelevement').collapse();}
                                }
                            }
                        },{
                            xtype:'hidden'
                            ,name: 'am'
                            ,value:0
                        },{
                            xtype:'hidden'
                            ,name: 'af'
                            ,value:0
                        },{
                            xtype:'hidden'
                            ,name: 'ai'
                            ,value:0
                        },{
                            xtype:'hidden'
                            ,name: 'na'
                            ,value:0
                        },{
                            xtype:'hidden'
                            ,name: 'jeune'
                            ,value:0
                        },{
                            xtype:'hidden'
                            ,name: 'yearling'
                            ,value:0
                        },{
                            xtype:'hidden'
                            ,name: 'sai'
                            ,value:0
                        }
                    ]
                },{
                    xtype:'fieldset'
                    ,id:'fieldset-prelevement'
                    ,columnWidth: 1
                    ,title: 'Prélèvemement du cadavre'
                    ,collapsible: true
                    ,collapsed: true
                    ,autoHeight:true
                    ,anchor:'100%'
                    ,items :[{
                        id:'cb-prelevement'
                        ,xtype:'checkbox'
                        ,fieldLabel: 'Prélèvement'
                        // ,boxLabel: 'Prelevement'
                        ,name: 'prelevement'
                        ,inputValue: true
                        ,checked: false                                   
                        ,listeners: {
                            check: function(checkbox,checked) {
                                if(checked){
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('prelevement',true);
                                    var commentValue = Ext.getCmp('ta-fiche-commentaire').getValue();
                                    if(commentValue == null || commentValue == ''){
                                        Ext.getCmp('ta-fiche-commentaire').markInvalid('En cas de prélévement, un commentaire est obligatoire.');
                                    }
                                }
                                else{
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('prelevement',false);
                                    Ext.getCmp('ta-fiche-commentaire').validate();
                                }
                                Ext.getCmp('fieldset-commentaire').expand();
                                manageValidationTaxon(isValidTaxon(Ext.getCmp('grid-taxons').getSelectionModel().getSelected()));
                            }
                            ,render: function(c) {
                                Ext.QuickTips.register({
                                    target: c.getEl(),
                                    text: 'Cochez si vous avez prélevé l\'individu ou une partie de l\'individu.'
                                });
                            }
                        }                                
                    }]
                },{
                    xtype:'fieldset'
                    ,id:'fieldset-commentaire'
                    ,columnWidth: 1
                    ,title: 'Commentaire concernant l\'individu mort'
                    ,collapsible: true
                    ,collapsed: true
                    ,autoHeight:true
                    ,anchor:'100%'
                    ,items :[{
                            id:'ta-fiche-commentaire'
                            ,xtype: 'textarea'
                            ,fieldLabel: 'Commentaire '
                            ,name: 'commentaire'
                            ,grow:true
                            ,autoHeight: true
                            ,height:'auto'
                            ,anchor:'100%'
                            ,enableKeyEvents:true
                            ,listeners: {
                                render: function(c) {
                                    Ext.QuickTips.register({
                                        target: c.getEl(),
                                        text: 'Indiquer ici un éventuel commentaire concernant cet individu mort. Le commentaire est obligatoire en cas de prélèvement.'
                                    });
                                }
                                ,keyup: function(field) {
                                    Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('commentaire',field.getValue());
                                    manageValidationTaxon(isValidTaxon(Ext.getCmp('grid-taxons').getSelectionModel().getSelected()));
                                }
                            }
                        }
                    ]
                },{
                    xtype:'fieldset'
                    ,id:'fieldset-determinateur'
                    ,columnWidth: 1
                    ,title: 'Déterminateur du taxon (facultatif)'
                    ,collapsible: true
                    ,collapsed: true
                    ,autoHeight:true
                    ,anchor:'100%'
                    ,items :[{
                            id:'ta-fiche-determinateur'
                            ,xtype: 'textarea'
                            ,fieldLabel: 'Déterminateur '
                            ,name: 'determinateur'
                            ,grow:true
                            ,autoHeight: true
                            ,height:'auto'
                            ,anchor:'100%'
                            ,enableKeyEvents:true
                            ,listeners: {
                                render: function(c) {
                                    Ext.QuickTips.register({
                                        target: c.getEl(),
                                        text: 'Indiquer ici le déterminateur ce taxon.'
                                    });
                                }
                                ,keyup: function(field) {Ext.getCmp('grid-taxons').getSelectionModel().getSelected().set('determinateur',field.getValue());}
                            }
                        }
                    ]
                }
                ,validTaxonButton
                ,{xtype: 'label',id: 'error-message',cls: 'errormsg',text:''}
                ,addTaxonButton 
                ,{
                    xtype:'hidden'
                    ,name: 'monactiontaxon'
                    ,value:'update'
                },{
                    xtype:'hidden'
                    ,name: 'cd_ref_origine'
                },{
                    xtype:'hidden'
                    ,name: 'nom_taxon_saisi'
                }
                ]
            },{
                columnWidth: 0.4
                ,layout: 'fit'
                ,items:[{
                    xtype: 'grid'
                    ,id:'grid-taxons'
                    ,store: relevesStore
                    ,cm: colModel
                    ,stripeRows: true
                    ,sm: new Ext.grid.RowSelectionModel({
                        singleSelect: true
                        ,listeners: {
                            rowselect: function(sm, row, rec) {
                                manageDenombrementFields(rec,false);
                                Ext.getCmp('edit-fiche-form').getForm().loadRecord(rec);
                                if(rec.data.sexeageinfo=='Saisie en cours'){
                                    if(Ext.getCmp('combo-fiche-taxon').getValue()==null){
                                        Ext.getCmp('fieldset-sexeage').collapse();
                                        Ext.getCmp('fieldset-prelevement').collapse();
                                        Ext.getCmp('fieldset-commentaire').collapse();
                                        Ext.getCmp('fieldset-determinateur').collapse();
                                    }
                                    else{Ext.getCmp('fieldset-sexeage').expand();}
                                }
                                else{
                                    Ext.getCmp('fieldset-sexeage').expand();
                                    if(Ext.getCmp('ta-fiche-commentaire').getValue()==''){Ext.getCmp('fieldset-commentaire').collapse();}
                                    else{Ext.getCmp('fieldset-commentaire').expand();}
                                    if(Ext.getCmp('ta-fiche-determinateur').getValue()==''){Ext.getCmp('fieldset-determinateur').collapse();}
                                    else{Ext.getCmp('fieldset-determinateur').expand();}
                                }
                            }
                            ,selectionchange: function(sm) {
                                if(Ext.getCmp('edit-fiche-form').getForm().findField('monactiontaxon').getValue()=='add'){
                                    Ext.getCmp('edit-fiche-form').getForm().findField('monactiontaxon').setValue('update');
                                }
                                if(sm.getSelected()){
                                    manageValidationTaxon(isValidTaxon(sm.getSelected()));
                                }
                            } 
                        }
                    })
                    ,autoExpandColumn: 'sexeageinfo'
                    ,height: 350
                    ,border: true
                    ,listeners: {
                        viewready: function(g) {
                            g.getSelectionModel().selectRow(0);
                        } // Allow rows to be rendered.
                    }
                }]
            }//fin du collum2 
            ]//fin du item
            ,listeners: {
                afterlayout: function(g) {
                    Ext.getCmp('grid-taxons').getSelectionModel().selectRow(0);
                }
            }
        });//fin du gridForm
        return [gridForm];
    };//Fin du getFormTaxons
    
    /**
     * Method: createLayer
     * Creates the vector layer
     *
     * Return
     * <OpenLayers.Layer.Vector>
     */
    var createLayer = function() {
        var styleMap = new OpenLayers.StyleMap({
            'default': {
                fillColor: "red"
                ,strokeColor: "#ff6666"
                ,cursor: "pointer"
                ,fillOpacity: 0.7
                ,strokeOpacity: 1
                ,strokeWidth: 2
                ,pointRadius: 7
            }
            ,select : {
                fillColor: "blue"
                ,strokeColor: "blue"
                ,cursor: "pointer"
                ,fillOpacity: 0.5
                ,strokeOpacity: 1
                ,strokeWidth: 3
                ,pointRadius: 8
            }
        });
        vectorLayer = new OpenLayers.Layer.Vector("editFiche vector layer"
            ,{
                protocol: eventProtocol
                ,strategies: [
                    new mapfish.Strategy.ProtocolListener()
                ]
                ,styleMap: styleMap
                ,format: OpenLayers.Format.GeoJSON
            }
        );
        vectorLayer.events.on({
            featureadded: function(obj) {
                var feature = obj.feature;
                if(map.getZoom()<15){
                    vectorLayer.removeFeatures(feature);
                    zoomin.activate();// on active le bouton pour zoomer
                    Ext.ux.Toast.msg('Echelle de saisie inadaptée', 'Vous ne pouvez pas pointer à cette échelle. <br />Merci de zoomer jusqu\'à la carte au 1/25 000ème.');
                    return false; //la fonction s'arrête là
                }
                if(vectorLayer.features[1]){
                    vectorLayer.removeFeatures(vectorLayer.features[0]);//s'il y a déjà une géométrie, on la supprime pour ne garder que celle qui vient d'être ajoutée
                }
                updateGeometryField(feature);
                Ext.getCmp('edit-fiche-form').enable();
                Ext.getCmp('edit-fiche-form').ownerCt.ownerCt.doLayout();
                Ext.getCmp('edit-fiche-form').getForm().findField('ids_observateurs').setValue(Ext.getCmp('combo-fiche-observateurs').getValue());
                application.cf.editFicheMortalite.findZ(feature);
            }
            ,featuremodified: function(obj) {
                updateGeometryField(obj.feature);
            }
            ,featureremoved: function(obj) {
                updateGeometryField(null);
                Ext.getCmp('edit-fiche-form').disable();
            }
        });
    };

    /**
     * Method: createMap
     * Creates the map
     *
     * Return
     * <OpenLayers.Map>
     */
    var createMap = function() {
        map = application.cf.createMap();
        map.getLayersByName('overlay')[0].mergeNewParams({
          id_cf:id_cf
        });
        createLayer();
        map.addLayers([vectorLayer]);
        map.zoomToMaxExtent();
        maProjection = map.getProjectionObject();
    };

    /**
     * Method: initToolbarItems
     * Creates the map toolbar
     */
    var initToolbarItems = function() {
        if (!toolbarInitializedOnce) {
            toolbar.addControl(
                new OpenLayers.Control.ZoomToMaxExtent({
                    map: map,
                    title: 'Revenir à l\'échelle maximale'
                }), {
                    iconCls: 'zoomfull',
                    toggleGroup: this.id
                }
            );

            application.cf.utils.addSeparator(toolbar);
            
            var history = new OpenLayers.Control.NavigationHistory();
            map.addControl(history);
            toolbar.addControl(history.previous, {
                iconCls: 'previous'
                ,toggleGroup: 'navigation'
                ,tooltip: 'Etendue précédente'
                ,handler: function() {
                    // application.synthese.search.changeGridCss();
                    syntheseListGrid.getView().refresh();
                }
            });
            
            toolbar.addControl(
                zoomin = new OpenLayers.Control.ZoomBox({
                    title: 'Zoomer'
                }), {
                    iconCls: 'zoomin',
                    toggleGroup: this.id
                }
            );

            toolbar.addControl(
                new OpenLayers.Control.ZoomBox({
                    out: true,
                    title: 'Dézoomer'
                }), {
                    iconCls: 'zoomout',
                    toggleGroup: this.id
                }
            );

            toolbar.addControl(
                dragPanControl = new OpenLayers.Control.DragPan({
                    isDefault: true,
                    title: 'Déplacer la carte'
                }), {
                    iconCls: 'pan',
                    toggleGroup: this.id
                }
            );

            application.cf.utils.addSeparator(toolbar);

            toolbar.addControl(
                drawPointControl = new OpenLayers.Control.DrawFeature(vectorLayer, OpenLayers.Handler.Point, {
                    title: 'Localiser l\'observation (supprime la localisation existante s\'il y en a une)'
                }), {
                    iconCls: 'drawpoint'
                    ,toggleGroup: this.id
                    ,disabled: true
                }
            );
            
            toolbar.add({
                text: 'GPS'
                ,id: 'edit-fiche-gps'
                ,tooltip: 'Positionner l\'observation sur la carte à partir de coordonnées GPS en UTM'
                ,handler: function() {
                    vectorLayer.removeFeatures(vectorLayer.features[0]);
                    application.cf.editFicheMortalite.initGpsWindow();
                }
            });

            layerTreeTip = application.cf.createLayerWindow(map);
            layerTreeTip.render(Ext.getCmp('edit-fiche-mapcomponent').body);
            layerTreeTip.show();
            layerTreeTip.getEl().alignTo(
                Ext.getCmp('edit-fiche-mapcomponent').body,
                "tl-tl",
                [5, 5]
            );
            layerTreeTip.hide();

            application.cf.utils.addSeparator(toolbar);

            toolbar.add({
                iconCls: 'legend'
                ,enableToggle: true
                ,tooltip: 'Gérer les couches affichées'
                ,handler: function(button) {
                    showLayerTreeTip(button.pressed);
                }
            });

            toolbar.activate();
            toolbarInitializedOnce = true;
        }
    };

    /**
     * Method: activateControls
     * Allows to activate / enable / deactivate / disable the draw and modify feature controls
     *
     * Parameters:
     * activateDrawControls - {Boolean} true to activate / enable the draw controls
     */
    var activateControls = function(activateDrawControls) {
        Ext.each([drawPointControl]
            ,function(control) {
                toolbar.getButtonForControl(control).setDisabled(!activateDrawControls);
                if (!activateDrawControls) {
                    control.deactivate();
                }
            }
        );
    };

    /**
     * Method: deactivateAllEditingControls
     */
    var deactivateAllEditingControls = function() {
        toolbar.getButtonForControl(drawPointControl).setDisabled(true);
        drawPointControl.deactivate();
    };

    /**
     * Method: updateGeometryField
     * Updates the geometry field (hidden) in the form
     *
     * Parameters:
     * geometry - {null|<OpenLayers.Geometry>} Geometry
     */
    var updateGeometryField = function(geometry) {
        if (geometry == null) {
            wkt = '';
        }
        else {
            var wkt = format.write(geometry);
        }
        Ext.getCmp('edit-fiche-form').getForm().findField('geometry').setValue(wkt);
        firstGeometryLoad = false;
    };
    
    /**
     * Method: createProtocol
     * Create the search protocol.
     */
    var createProtocol = function() {
        protocol = new mapfish.Protocol.MapFish({});
        eventProtocol = new mapfish.Protocol.TriggerEventDecorator({
            protocol: protocol
            ,eventListeners: {
                crudtriggered: function() {
                }
                ,crudfinished: function(response) {
                    var feature = response.features[0];
                    //chargement des valeurs du formulaire
                    Ext.getCmp('edit-fiche-form').getForm().loadRecord(feature);
                    Ext.getCmp('fieldlabel-commune').setValue('Commune: '+feature.data.commune);
                    //on centre en limitant le zoom à 15
                    var centerGeom = feature.geometry.getBounds().getCenterLonLat();
                    map.setCenter(centerGeom,15);
                    Ext.getCmp('edit-fiche-form').enable();
                }
            }
        });
    };

    /**
     * Method: createStore
     * Create the search result store.
     */
    var createStore = function() {
        store = new Ext.data.Store({
            reader: new mapfish.widgets.data.FeatureReader({}, [
                'id_cf'
                ,'ids_observateurs'
                ,{name:'dateobs', type: 'date', dateFormat:'d/m/Y'}
                ,'commune'
                ,'altitude'
            ])
            ,listeners: {
                load: function(store, records) {
                    Ext.getCmp('edit-fiche-form').getForm().loadRecord(records[0]);
                }
            }
        });
    };

    /**
     * Method: resetViewport
     * Reset the different items status (on close) for next usage
     */
    var resetViewport = function() {
        id_cf = null;
        // map.zoomToMaxExtent();
        vectorLayer.removeFeatures(vectorLayer.features);
        Ext.getCmp('edit-fiche-form').getForm().reset();
        Ext.getCmp('edit-fiche-form').getForm().findField('monaction').setValue('add');
        Ext.getCmp('edit-fiche-form').getForm().findField('id_organisme').setValue(application.cf.user.id_organisme);
        Ext.getCmp('grid-taxons').getStore().removeAll();
        this.addNewIndividu();
        dragPanControl.activate();
        activateControls(true);
        updateGeometryField(null);
        Ext.getCmp('edit-fiche-form').disable();
    };
    
     /**
     * Method: constructStringTaxons
     * Construct a multidimentional Array with all taxon informations
     */
     var constructStringTaxons = function(){     
        var arrayGlobal = []
        Ext.getCmp('grid-taxons').getStore().each(function(rec){
            var attrib = [];
            var reg = new RegExp("(,)", "g");
            var val = null;
            for (key in rec.data) {
                if(typeof rec.data[key]==="string"){
                    val = rec.data[key].replace(reg,'<!>');//gestion des virgules dans les commentaires
                } 
                else{val = rec.data[key];}
                attrib.push(val);
            }
            arrayGlobal.push(attrib);
        });     
        var taxons = arrayGlobal.join("|")
        return taxons;
    };
    
    /**
     * Method: constructStringKeys
     * Construct a multidimentional Array with all taxon informations
     */
    var constructStringKeys = function(){
        var arrayKeys =  Ext.getCmp('grid-taxons').getStore().fields.keys;     
        var keys = arrayKeys.join("|")
        return keys;
    };

    /**
     * Method: submitForm
     * Submits the form
     */
    var submitForm = function() {
        Ext.getCmp('ficheSaveButton').setText('Enregistrement en cours...');
        var params = {};
        if (id_cf) {
            params.id_cf = id_cf;
        }
        params.sting_taxons = constructStringTaxons();
        Ext.getCmp('edit-fiche-form').getForm().submit({
            url: 'cf/savemortalite'
            ,params: params
            ,success: function(form,action) {
                Ext.getCmp('ficheSaveButton').setText('Enregistrer');
                Ext.getCmp('edit-fiche-form').getForm().findField('id_cf').setValue(action.result.id_cf);
                id_cf = action.result.id_cf;
                Ext.getCmp('edit-fiche-form').getForm().findField('monaction').setValue('update');
                myProxyReleves.url = 'cf/listreleves/'+id_cf;
                Ext.getCmp('grid-taxons').getStore().reload();
                application.cf.editFicheMortalite.initSaveWindow(id_cf);
            }
            ,failure: function(form, action) {
                Ext.getCmp('ficheSaveButton').setText('Enregistrer');
                var msg;
                switch (action.failureType) {
                      case Ext.form.Action.CLIENT_INVALID:
                          msg = "Les informations saisies sont invalides ou incomplètes. Vérifiez le formulaire (voir champs en rouge).";
                          break;
                      case Ext.form.Action.CONNECT_FAILURE:
                          msg = "Erreur lors de l'enregistrement";
                          break;
                      case Ext.form.Action.SERVER_INVALID:
                          msg = "Erreur lors de l'enregistrement : vérifiez les données saisies !";
                          break;
                }
                Ext.Msg.show({
                  title: 'Erreur'
                  ,msg: msg
                  ,buttons: Ext.Msg.OK
                  ,icon: Ext.MessageBox.ERROR
                });
            }
        });
    };

    /**
     * Method: showLayerTreeTip
     * Shows or hide the layer tree tip
     */
    var showLayerTreeTip = function(show) {
        layerTreeTip.setVisible(show);
    };
    
    var initSaveWindow = function(id_fiche) {     
        return new Ext.Window({
            id:'window-save'
            ,title:'POINTAGE N° <span style="color:red;fontWeight:bold;">'+id_fiche+'</span>. Et maintenant chef, on fait quoi chef ?'
            ,layout:'border'
            ,height:175
            ,width: 600
            ,closable:false
            ,autoScroll:true
            ,modal: true
            ,plain: true
            ,split: true
            ,buttons: [{
                text: 'Créer un nouveau pointage'
                ,iconCls:'add'
                ,handler: function(){
                    resetViewport();
                    Ext.getCmp('window-save').destroy();
                    Ext.ux.Toast.msg('Et voilà !', 'C\'est reparti ! Pensez à commencer par le pointage sur la carte');
                }
            },{
                text: 'Modifier/compléter ce pointage'
                ,iconCls:'annuler'
                ,handler: function(){
                    Ext.ux.Toast.msg('Ok !', 'Vous pouvez compléter ou modifier ce pointage');
                    Ext.getCmp('window-save').destroy();
                }
            },{
                text:'Accéder à la synthèse'
                ,iconCls:'search'
                ,handler: function(){
                    window.location.href = 'synthese';
                }
            },{
                text:'Quitter'
                ,iconCls:'action-recenter'
                ,handler: function(){
                    Ext.getCmp('window-save').destroy();
                    window.location.href = 'http://'+host_uri+'/'+app_uri;
                }
            }]
            ,items: [{
                id:'panel-window-save'
                ,xtype: 'panel'
                ,region: 'center'
                ,frame:true
                ,border:false
                ,split: false
                ,autoScroll:false
                ,bodyStyle:'padding:5px 5px 0'
                ,width: 350
                ,html: 'Votre pointage a bien été enregistré sous le N° <span style="color:red;fontWeight:bold;">'+id_fiche+'</span>. </br>A l\'avenir, pour le consulter ou éventuellement le modifier, vous devrez utiliser l\'application synthèse.</br></br>Vous pouvez maintenant utiliser l\'un des boutons ci-dessous pour modifier ou compléter ce pointage n°'+id_fiche+', réaliser un autre pointage, accéder à l\'application de synthèse ou quitter.'
            }]
            ,listeners: {
                hide:function(){this.destroy();}
            } 
        });
    };
//---------------------------------- fin de fenêtre choix après sauvegarde ----------------------------------
    // public space
    return {
        viewport: null
        ,init: function() {
            createProtocol();
            createStore();
            this.viewport = initViewport();
        }
        
        /**
         * Method: loadAp
         * Loads a record from the aps list store
         */
        ,loadFiche: function(fiche,action,cd) {
            this.init();
            this.viewport.show();
                activateControls(true);
                updateGeometryField(null);
                Ext.getCmp('edit-fiche-form').getForm().findField('monaction').setValue('add');
                Ext.getCmp('edit-fiche-form').getForm().findField('id_organisme').setValue(application.cf.user.id_organisme);
                Ext.getCmp('edit-fiche-form').getForm().findField('monactiontaxon').setValue('add');
                Ext.getCmp('grid-taxons').getStore().removeAll();
                Ext.getCmp('grid-taxons').getStore().add(new blankRecord({
                    //attention l'ordre des champs est important
                    id_releve_cf:null
                    ,id_nom:null
                    ,nom_francais:''
                    ,nom_latin:''
                    ,nom_taxon_saisi:null
                    ,sexeage:''
                    ,sexeageinfo:'Saisie en cours'
                    ,am:0
                    ,af:0
                    ,ai:0
                    ,na:0
                    ,jeune:0
                    ,yearling:0
                    ,sai:0
                    ,commentaire:''
                    ,cd_ref_origine:null
                    ,denombrement:5
                    ,id_classe:null
                    ,prelevement:false
                }));
                Ext.getCmp('grid-taxons').getSelectionModel().selectRow(0);
                Ext.ux.Toast.msg('Information !', 'Commencez par pointer l\'observation sur la carte, puis saisissez les informations à droite');
        }

        ,initGpsWindow: function() {
            this.GpsWindow = Ext.ux.GpsLocation.initGpsWindow(vectorLayer);
            this.GpsWindow.show();
        }
        ,initSaveWindow: function(id_fiche) {
            this.saveWindow = initSaveWindow(id_fiche);
            this.saveWindow.show();
        }
        
        //remplir l'altitude du champ altitude dans le formulaire selon le pointage
        ,findZ : function(feature) {
            //on recherche l'altitude avec l'API IGN
            var geometryCentroid = feature.geometry.getCentroid();
            var latLonGeom = geometryCentroid.transform(new OpenLayers.Projection("EPSG:3857"), new OpenLayers.Projection("EPSG:4326"));
            var script = document.createElement('script');
            script.src = String.format('//wxs.ign.fr/{0}/alti/rest/elevation.xml?lon={1}&lat={2}&output=json&zonly=true&callback=application.cf.editFicheMortalite.handleIGNResponse', ign_api_key, latLonGeom.x, latLonGeom.y);
            document.head.appendChild(script);
        }
        ,handleIGNResponse : function(data) {
            var parser = new DOMParser();
            var xmlDoc = parser.parseFromString(data.xml, "text/xml");
            var s = xmlDoc.getElementsByTagName('z');
            if (s.length === 0 || Ext.isEmpty(s[0]) || Ext.isEmpty(s[0].innerHTML)) {
                Ext.Msg.alert('Attention', "Un problème à été rencontré lors de l'appel au service de l'IGN.");
                return;
            }
            Ext.ux.Toast.msg('Information !', 'Cette altitude est fournie par un service de l\'IGN.');
            application.cf.editFicheMortalite.setAltitude(Math.round(s[0].innerHTML));
        }
        ,setAltitude : function(alti) {
            Ext.getCmp('fieldfiche-altitude').setValue(alti);
        }
        
        ,changeLabel: function(fieldId, newLabel){
              var label = Ext.DomQuery.select(String.format('label[for="{0}"]', fieldId));
              if (label){
                label[0].childNodes[0].nodeValue = newLabel;
              }
        }
    }
}();
