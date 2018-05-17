/**
 * @class application.synthese.search
 * Singleton to build the search panel (tab)
 *
 * @singleton
 */

application.synthese.search = function() {
    // private variables

    /**
     * Property: map
     * {OpenLayers.Map}
     */
    var map = null;
     
     /**
     * Property: vectorLayer
     * {OpenLayers.Layer.Vector}
     */
    vectorLayer = null;
    
    /**
     * Property: protocol
     * {mapfish.Protocol.MapFish}
     */
    var protocol = null;

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
     * Property: store
     * {Ext.data.Store} The search result store.
     */
    var store = null;

    /**
     * Property: syntheseListGrid
     * {Ext.grid.GriPanel}
     */
    var syntheseListGrid = null;

    /**
     * Property: mediator
     * {mapfish.widgets.data.SearchStoreMediator} The search result mediator.
     */
    var mediator = null;

    /**
     * Property: mapSearcher
     * {mapfish.Searcher.Map}
     */
    var mapSearcher = null;
    
    /**
    * Property: formatWKT
    */
    var formatWKT = new OpenLayers.Format.WKT();
    
    /**
     * Property: formSearcher
     * {mapfish.Searcher.Form}
     */
    var formSearcher = null;

    /**
     * Property: overlayLayersStore
     * {Ext.data.Store} The store to manage overlay WMS layers
     */
    var overlayLayersStore = null;

    /**
     * Property: layerTreeTip
     * {Ext.Tip} The layerTreeTip created with the factory
     */
    var layerTreeTip = null;

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
     * Property: selectcontrol
     * {openlayers.control} 
     */
    var selectcontrol = null; 
    
    var mapBoundsSearch = false;
	var nbFeatures = null;
	var nbResult = null;
    var cetteAnnee = new Date().getFullYear();
    var tplZpDescriptionCols = [];

    
    // private functions
    
     /**
     * Method: createProtocol
     * Create the search protocol.
     */
    var createProtocol = function() {
        protocol = new mapfish.Protocol.MapFish({'url': 'synthese/get'});
        filterProtocol = new mapfish.Protocol.MergeFilterDecorator({
            protocol: protocol
        });
        eventProtocol = new mapfish.Protocol.TriggerEventDecorator({
            protocol: filterProtocol
            ,eventListeners: {
                crudtriggered: function() {
                    if(syntheseListGrid){syntheseListGrid.loadMask.show();}
                }
                ,crudfinished: function(response) {
                    if(response.features!=null){
                        nbFeatures = null;
                        nbResult = null;
                        //cas ou il n'y a pas de réponse
                        if (response.features.length == 0) {
                            store.removeAll();
                            if(syntheseListGrid){syntheseListGrid.loadMask.hide();}
                            Ext.getCmp('result_count').setText("Aucune donnée ne correspond à la recherche.");
                            Ext.getCmp('result_count').addClass('redbold');
                            Ext.getCmp('result_count').removeClass('bluebold');
                        }
                        else{
                            //cas où il y a trop de réponse, la requête retourne la feature contenant une géometry null voir lib/sfRessourcesActions
                            if (response.features[0].geometry == null ) {
                                nbFeatures = 'trop';
                                nbResult = response.features[0].data.nb;
                            }
                        }
                    }
                }
                ,clear: function() {}
            }
        });
    };

    /**
     * Method: createStore
     * Create the search result store.
     */
    var createStore = function() {
        store = new Ext.data.Store({
            storeId:'store-observation-search'
            ,reader: new mapfish.widgets.data.FeatureReader({}, [
                {name: 'id_synthese'}
                ,{name: 'id_source'}
                ,{name: 'id_fiche_source'}
                ,{name: 'code_fiche_source'}
                ,{name: 'id_organisme'}
                ,{name: 'id_protocole'}
                ,{name: 'id_programme'}
                ,{name: 'nom_programme'}
                ,{name: 'insee'}
                ,{name:'dateobs', type: 'date', xtype: 'datecolumn', dateFormat:'Y-m-d'}
                ,{name: 'observateurs'}
                ,{name: 'altitude'}
                ,{name: 'remarques'}
                ,{name: 'cd_nom'}
                ,{name: 'cd_ref'}
                ,{name: 'taxon_latin'}
                ,{name: 'taxon_francais'}
                ,{name: 'patrimonial',type:'boolean'}
                ,{name: 'no_patrimonial',defaultValue: false}
                ,{name: 'nom_critere_synthese'}
                ,{name: 'effectif_total'}
                ,{name: 'no_protection', defaultValue: false}
                ,{name: 'nomcommune'}
                ,{name: 'edit_ok',type:'boolean'}
                ,{name: 'onscreen',type: 'string',defaultValue:'yes'}
                ,{name: 'diffusable',type: 'string'}
            ])
            ,sortInfo: {
                field: 'id_synthese'
                ,direction: 'DESC'
            }
            ,listeners: {
                load: function(store, records) {
                    //on test si on est sur la recherche par défaut de la première page
                    if(Ext.getCmp('hidden-start').getValue()=='no'){
                        var count = store.getTotalCount();
                        //on test s'il y a trop de features ou pas
                        if (nbFeatures =='trop'){
                            store.removeAll();
                            syntheseListGrid.loadMask.hide();
                            Ext.getCmp('result_count').setText(nbResult+" réponses précisez votre recherche.");
                            Ext.getCmp('result_count').addClass('redbold');
                            Ext.getCmp('result_count').removeClass('bluebold');
                            if(nbResult<=65535){
                                Ext.Msg.confirm('Attention !'
                                    ,'Il y a  '+nbResult+' observations. C\'est trop pour les afficher sans difficulté dans votre navigateur. !<br />Souhaitez vous exporter ces observations vers excel ?<br />Attention, seules les observations de votre structure seront exportées et selon le volume de données, cette opération peut-être longue.'
                                    ,function(btn) {
                                        if (btn == 'yes') {
                                            application.synthese.search.exportXlsObs();
                                        }
                                    }
                                );
                            }
                            else{
                                Ext.Msg.show({
                                  title: 'Attention'
                                  ,msg: 'Il y a trop de réponses pour les afficher ou les exporter vers Excel. Vous devez préciser votre recherche.'
                                  ,buttons: Ext.Msg.OK
                                  ,icon: Ext.MessageBox.WARNING
                                });
                            }                            
                        }
                        else{
                            Ext.getCmp('result_count').setText(count + " observation(s)");
                            Ext.getCmp('result_count').addClass('bluebold');
                            Ext.getCmp('result_count').removeClass('redbold');
                        }
                    }
                    else{
                        Ext.getCmp('hidden-start').setValue('no');
                        Ext.getCmp('result_count').addClass('bluebold');
                    }
                    Ext.getCmp('synthese_list_grid').getSelectionModel().selectFirstRow();
                }
            }
        });
    };

    /**
     * Method: createMediator
     * Create the search mediator.
     */
    var createMediator = function() {
        mediator = new mapfish.widgets.data.SearchStoreMediator({
            store: store
            ,protocol: eventProtocol
            ,append: false
        });
    };
    
    
    /**
     * Method: createTemplates
     * Créer les templates
     */
    var createTemplates = function() {     
        tplZpDescriptionCols =[
            new Ext.XTemplate(
                '<p><b><tpl if="taxon_francais">{taxon_francais} - </tpl><i>{taxon_latin}</i></b><tpl if="effectif_total"> - {effectif_total} individu(s)</tpl> le {dateobs:date("d/m/Y")}</p>'
                ,'<tpl if="observateurs"><p><b>Observation de </b> {observateurs} à {altitude} m ({nom_critere_synthese})</p></tpl> '
                ,'<tpl if="nomcommune"><p>Sur la commune de {nomcommune}</p></tpl> '
                ,'<tpl if="code_fiche_source"><p>Code fiche : {code_fiche_source}</p></tpl> '
                ,'<tpl if="remarques"><p><b>Remarques : </b>{remarques}</p></tpl>' 
                ,'<tpl if="diffusable"><p><b>Diffusable : </b>{diffusable}</p></tpl>' 
            )
            ,new Ext.XTemplate(
                '<p style="color:grey;"><b>'
                    ,'<a href="http://inpn.mnhn.fr/isb/espece/cd_nom/{cd_nom}" target="blank">'
                        ,'<tpl if="taxon_francais">{taxon_francais} - </tpl>'
                        ,'<i>{nom_valide}</i>'
                    ,'</a>'
                ,'</b></p>'
                ,'<tpl if="famille"><p style="color:grey;"><b>Groupe taxonomique :</b> {classe} - <b>Ordre :</b> {ordre} - <b>Famille :</b> {famille}</p></tpl>'
                ,'<tpl if="protection_stricte==true"><p style="color:grey;"><b>L\'espèce dispose d\'un statut de protection</b></tpl>'
                ,'<tpl if="patrimonial==false"><p style="color:grey;">L\'espèce n\'est pas patrimoniale pour '+struc_abregee+'</tpl>'
                ,'<tpl if="patrimonial==true"><p style="color:grey;"><b>L\'espèce est patrimoniale pour '+struc_abregee+'</b></tpl>'
                ,'</p>'
            )
            ,new Ext.XTemplate(
                '<p style="color:grey;"><b>Réglementation</b> : </p>'
                    ,'<tpl for="protections">'
                        ,'<tpl if="url==\'pas de version à jour\'">'
                            ,'<p style="color:grey;">{texte}</p>'
                        ,'</tpl>'
                        ,'<tpl if="url!=\'pas de version à jour\'">'
                            ,'<p><a href="{url}" target="_blank">{texte}</a></p>'
                        ,'</tpl>'
                    ,'</tpl>'
                
            )
        ];
    };

    var findInfosTaxon = function(cd_nom) {
        var store = application.synthese.storeTaxonsSyntheseLatin; 
        var regId = new RegExp ("^"+cd_nom+"$",'gi');
        var rec = store.getAt(store.find('cd_nom',regId));
        return rec;
    };
    var loadTaxonDetails = function(fiche) {
        var i;
        var rec = findInfosTaxon(fiche.data.cd_nom);
        if(Ext.isDefined(rec)==true){
	        fiche.data.nom_valide = rec.data.nom_valide;
	        fiche.data.famille = rec.data.famille;
	        fiche.data.ordre = rec.data.ordre;
	        fiche.data.classe = rec.data.classe;
	        fiche.data.protections = rec.data.protections;
	        fiche.data.protection_stricte = rec.data.protection_stricte;
	        
	        for (i = 0; i <= 2; i++) {
	            var el = Ext.getCmp('description-col' + i);
	            var tpl = tplZpDescriptionCols[i];
	            el.body.update(tpl.apply(fiche.data));
	        }
	        Ext.getCmp('south-synthese-panel').doLayout();
	        Ext.getCmp('south-synthese-panel').expand();
        }
        else{
            application.synthese.storeTaxonsSyntheseLatin.on('load',function(){
                loadTaxonDetails(fiche);
            }
            ,this
            ,{single:true});
        }
    };

    var initPanel = function() {
        return  {
            title: 'Synthèse des observations'
            ,layout: 'border'
            ,iconCls: 'tetras'
            ,defaults: {
                border: false
            }
            ,items: [
                getViewportSouthItem()
                ,getViewportEastItem()
                ,getViewportWestItem()
                ,getViewportCenterItem()
            ]
            ,listeners: {
                afterlayout: function() {
                    layerTreeTip = application.synthese.createLayerWindow(map);
                    layerTreeTip.render(Ext.getCmp('search-tab-mapcomponent').body);
                    layerTreeTip.show();
                    layerTreeTip.getEl().alignTo(
                        Ext.getCmp('search-tab-mapcomponent').body,
                        "tl-tl",
                        [5, 5]
                    );
                    layerTreeTip.hide();
                    initToolbarItems();
                    map.baseLayer.redraw();   // hack to ensure that the baseLayer is completely drawn
                    map.div.style.visibility = 'visible';
                }
                ,activate: function(panel) {
                    panel.doLayout();
                    application.synthese.search.triggerSearch();
                    //action suivant les actions sur la carte
                    map.events.on({
                        move: function(e) { 
                            Ext.getCmp('hidden-zoom').setValue(map.zoom);
                            syntheseListGrid.getView().refresh();                            
                        }
                    });
                }
                ,scope: this
            }
        };
    };
    var getViewportSouthItem = function() {
        return {
            id:'south-synthese-panel'
            ,title:'Détails concernant l\'observation'
            ,region:"south"
            ,height:110
            ,split:true
            ,bodyStyle:"background-color:#efefef"
            ,layout: 'column'
            ,autoScroll: true
            ,collapsed:true
            ,collapsible:true
            ,defaults: {
                border: false
            }
            ,items: [{
                columnWidth: 0.4
                ,id: 'description-col0'
                ,bodyStyle:"background-color:#efefef"
            },{
                columnWidth: 0.3
                ,id: 'description-col1'
                ,bodyStyle:"background-color:#efefef"
            },{
                columnWidth: 0.3
                ,id: 'description-col2'
                ,bodyStyle:"background-color:#efefef"
            }]
        };
    };
    /**
     * Method: getViewportWestItem
     */
    var getViewportWestItem = function() {
        var isWhereParam = function(){
            var paramCommune = Ext.getCmp('combo-communes').getValue();
            var paramSecteur = Ext.getCmp('combo-secteurs').getValue();
            var paramReserve = Ext.getCmp('combo-reserves').getValue();
            var paramN2000= Ext.getCmp('combo-n2000').getValue();
            if(paramCommune=="" && paramSecteur=="" && paramReserve=="" && paramN2000=="" && application.synthese.searchVectorLayer.features.length==0){return false;}
            return true;
        };
        var mabarre = [{
                id:'btn-rechercher'
                ,text: "Rechercher"
                ,iconCls: 'search'
                ,handler: function() {
                    //rechercher dans la zone dessinée ou dans l'emprise de la carte
                    Ext.getCmp('hidden-start').setValue('no');
                    if(Ext.getCmp('periodedebut').getValue()=="Période debut"){Ext.getCmp('periodedebut').setValue("");}
                    if(Ext.getCmp('periodefin').getValue()=="Période fin"){Ext.getCmp('periodefin').setValue("");}
                    if (isWhereParam()==false) {
                        Ext.getCmp('hidden-geom').setValue(application.synthese.getFeatureWKT(map.getExtent().toGeometry()));
                        mapBoundsSearch = true;
                    }
                    else{
                        if(application.synthese.searchVectorLayer.features.length>0){
                            Ext.getCmp('hidden-geom').setValue(application.synthese.getFeatureWKT(application.synthese.searchVectorLayer.features[0].geometry));
                        }
                        mapBoundsSearch = false;
                    }
                    formSearcher.triggerSearch();
                }
            },{
                id:'btn-raz'
                ,text: "RAZ"
                ,iconCls: 'annuler'
                ,handler: function() {
                    formSearcher.form.reset();
                    Ext.getCmp('combo-secteurs').getStore().reload();
                    Ext.getCmp('combo-communes').getStore().reload();
                    if(Ext.getCmp('tree-taxons')){application.synthese.search.resetTree();}
                    application.synthese.searchVectorLayer.removeAllFeatures();
                    Ext.getCmp('hidden-geom').setValue(null);
                    if(map.getZoom()!=0){map.zoomToMaxExtent();}
                    Ext.getCmp('result_count').setText("les 50 dernières observations");
                    Ext.getCmp('hidden-start').setValue('yes');
                    mapBoundsSearch = false;
                    formSearcher.triggerSearch();
                }
            }
        ];
        return {
            region: 'west'
            ,title:'Critères de recherche'
            ,width: 270
            ,split: true
            ,collapsible:true
            ,autoScroll: true
            ,defaults: {
                border: false
                ,bodyStyle:"padding:3px;background-color:#eeeeee"
            }
            ,items: [{
                id: 'search-form'
                ,xtype: 'form'
                ,bodyStyle: 'padding: 5px;background-color:#eeeeee'
                ,disabled: false
                ,labelAlign: 'left'
                ,monitorValid:true
                ,tbar: mabarre
                ,bbar: mabarre
                ,items: getFormItems()
            }]
            ,listeners: {
                afterlayout: function () {
                    formSearcher = new mapfish.ux.Searcher.Form.Ext({
                        store: store
                        ,protocol: eventProtocol
                        ,form: Ext.getCmp('search-form').getForm()
                    });
                    filterProtocol.register(formSearcher);
                }
            }
        };
        
    };

    /**
     * Method: getViewportEastItem
     * builds the config for the observations list grid
     */
    var getViewportEastItem = function() {
        createStore();
        createMediator();
        createTemplates();
        
        toolbarItems =  new Ext.Toolbar({items:[]});
        if(application.synthese.user.statuscode >= 2){
            var addFicheCfButton = new Ext.Button({
                iconCls: 'add'
                ,text: 'Contact faune'
                ,disabled: false
                ,handler: function() {
                    application.synthese.editCf.loadFiche(null,'add',null);
                }
                ,scope: this
            });
            var addFicheInvButton = new Ext.Button({
                iconCls: 'add'
                ,text: 'Invertébré'
                ,disabled: false
                ,handler: function() {
                    application.synthese.editInvertebre.loadFiche(null,'add',null);
                }
                ,scope: this
            });
            
            var exportXlsObsButton = new Ext.Button({
                iconCls: 'xls'
                ,text:'Observations'
                ,tooltip: 'Télécharger les observations (format xls)'
                ,handler: function() {
                    application.synthese.search.exportXlsObs();
                }
            });
            toolbarItems.add(exportXlsObsButton);
            var exportXlsStatutsButton = new Ext.Button({
                iconCls: 'xls'
                ,text:'Statuts'
                ,tooltip: 'Télécharger les statuts juridiques des espèces (format xls)'
                ,handler: function() {
                    application.synthese.search.exportXlsStatuts();
                }
            });
            toolbarItems.add(exportXlsStatutsButton);
            var exportShpButton = new Ext.Button({
                iconCls: 'export_shape'
                ,text:'SIG'
                ,tooltip: 'Télécharger les observations au format Shape'
                ,handler: function() {
                    application.synthese.search.exportShp();
                }
            });
            toolbarItems.add(exportShpButton); 
            var exportKmlButton = new Ext.Button({
                iconCls: 'add'
                ,text:'test'
                ,tooltip: 'Exporter les données au format Kml pour google Earth'
                ,handler: function() {
                    Ext.Ajax.request({
                        url: 'synthese/tokml'
                        ,success: function(request) {
                            alert(request.responseText);
                        }
                        ,failure: function() {
                            Ext.Msg.alert('Attention',"Un problème à été rencontré.");
                        }
                        ,scope: this
                        ,synchronous: true
                    });
                }
            });
        }
         toolbarItems.add('->');
         toolbarItems.add({xtype: 'label',id: 'result_count',text:'les 50 dernières observations'});
        
        var colModel = new Ext.grid.ColumnModel({
            columns : [
                {
                    xtype : 'actioncolumn'
                    ,sortable : false
                    ,hideable : false
                    ,menuDisabled : true
                    ,width:25
                    ,items : [{
                        tooltip : 'Ce taxon bénéfie d\'un statut de protection'
                        ,getClass : function(v, meta, record, rowIndex, colIdx, store) {
                            return (record.data.no_protection ? '' : 'fr');
                        }
                        ,scope : this
                        ,handler : function(grid, rowIndex, colIndex) {
                            var record = grid.getStore().getAt(rowIndex);
                            window.open('http://inpn.mnhn.fr/espece/cd_nom/' + record.data.cd_nom + '/tab/statut');
                        }
                    }]
                },{
                    xtype : 'actioncolumn'
                    ,sortable : false
                    ,hideable : false
                    ,menuDisabled : true
                    ,width:25
                    ,items : [{
                        tooltip : 'Ce taxon est patrimonial pour '+pn_name_long
                        ,getClass : function(v, meta, record, rowIndex, colIdx, store) {
                            return (record.data.no_patrimonial ? '' : 'logo_pne_mini');
                        }
                        ,scope : this
                    }]
                }
                ,{header: "Id", width: 60,  sortable: true, dataIndex: 'id_synthese',hidden: true}
                ,{header: "Id source", width: 25,  sortable: true, dataIndex: 'id_source',hidden: true}
                ,{header: "Id propriétaire", width: 25,  sortable: true, dataIndex: 'id_organisme',hidden: true}
                ,{header: "Code fiche", width: 100,  sortable: true, dataIndex: 'code_fiche_source',hidden: true}
                ,{header: "cd nom", width: 50, sortable: true, dataIndex: 'cd_nom',hidden: true}
                ,{header: "Latin", width: 100, sortable: true, dataIndex: 'taxon_latin',hidden: true}
                ,{id:'taxon',header: "Français", width: 100, sortable: true, dataIndex: 'taxon_francais'}
                ,{header: "Date",  width: 60, sortable: true, dataIndex: 'dateobs',renderer: Ext.util.Format.dateRenderer('d/m/Y')}
                ,{header: "Altitude", width: 40, sortable: true, dataIndex: 'altitude',hidden: true}
                ,{header: "Commune", width: 120, sortable: true, dataIndex: 'nomcommune',hidden: true}
                ,{header: "Programme", width: 90, sortable: true, dataIndex: 'nom_programme'}
                ,{header: "Observateurs",width: 90,  sortable: true, dataIndex: 'observateurs',hidden: true}
                ,{header: "Patri", width: 30, sortable: true, dataIndex: 'patrimonial',hidden: true}
                ,{header: "Diffusable", width: 50, sortable: true, dataIndex: 'diffusable',hidden: true}
                ,{
                    xtype : 'actioncolumn'
                    ,sortable : false
                    ,hideable : false
                    ,menuDisabled : true
                    ,width:25
                    ,items : [{
                        tooltip : 'Modifier cette observation'
                        ,getClass : function(v, meta, record, rowIndex, colIdx, store) {
                            var displayClass = '';
                            if(record.data.edit_ok){
                                displayClass = 'action-edit';
                            }
                            return displayClass;
                        }
                        ,scope : this
                        ,handler : function(grid, rowIndex, colIndex) {
                            var record = grid.getStore().getAt(rowIndex);
                            var code = record.data.code_fiche_source;
                            if(code!=''||code!=null){
                                var reg=new RegExp("[-]+", "g");
                                var tableau=code.split(reg);
                                var id_fiche = tableau[0].substr(1,20);
                                var id_releve = tableau[1].substr(1,20);
                                if(record.data.id_source==id_source_contactfaune&&record.data.id_protocole==id_protocole_contact_vertebre){application.synthese.editCf.loadFiche(id_fiche,'update',null);}
                                if(record.data.id_source==id_source_mortalite&&record.data.id_protocole==id_protocole_mortalite){application.synthese.editMortalite.loadFiche(id_fiche,'update',null);}
                                if(record.data.id_source==id_source_contactinv){application.synthese.editInvertebre.loadFiche(id_fiche,'update',null);}
                                if(record.data.id_source==id_source_contactflore){application.synthese.editCflore.loadFiche(id_fiche,'update',null);}
                            }
                        }
                    }]
                },{
                    xtype : 'actioncolumn'
                    ,sortable : false
                    ,hideable : false
                    ,menuDisabled : true
                    ,width:25
                    ,items : [{
                        tooltip : 'Supprimer cette observation'
                        ,getClass : function(v, meta, record, rowIndex, colIdx, store) {
                            var displayClass = '';
                            if(record.data.edit_ok){
                                displayClass = 'action-remove';
                            }
                            return displayClass;
                        }
                        ,scope : this
                        ,handler : function(grid, rowIndex, colIndex) {
                            var record = grid.getStore().getAt(rowIndex);
                            Ext.Msg.confirm('Attention !'
                                ,'Etes-vous certain de vouloir supprimer cette observation de "'+record.data.taxon_francais+'" ?'
                                ,function(btn) {
                                    if (btn == 'yes') {
                                        var code = record.data.code_fiche_source;
                                        if(code!=''||code!=null){
                                            var reg=new RegExp("[-]+", "g");
                                            var tableau=code.split(reg);
                                            var id_fiche = tableau[0].substr(1,20);
                                            var id_releve = tableau[1].substr(1,20);
                                            if(record.data.id_source==id_source_contactfaune&&record.data.id_protocole==id_protocole_contact_vertebre){application.synthese.search.deleteReleveCf(id_releve, record.data.taxon_francais);}
                                            if(record.data.id_source==id_source_mortalite&&record.data.id_protocole==id_protocole_mortalite){application.synthese.search.deleteReleveCf(id_releve, record.data.taxon_francais);}
                                            if(record.data.id_source==id_source_contactinv){application.synthese.search.deleteReleveInv(id_releve, record.data.taxon_latin);}
                                            if(record.data.id_source==id_source_contactflore){application.synthese.search.deleteReleveCflore(id_releve, record.data.taxon_latin);}
                                        }
                                    }
                                }
                                ,this // scope
                            );
                        }
                    }]
                },{
                    xtype : 'actioncolumn'
                    ,sortable : false
                    ,hideable : false
                    ,menuDisabled : true
                    ,width:25
                    ,items : [{
                        tooltip : 'Centrer la carte sur l\'observation'
                        ,getClass : function(v, meta, record, rowIdx, colIdx, store) {
                            return 'action-recenter';
                        }
                        ,scope : this
                        ,handler : function(grid, rowIndex, colIndex) {
                            var record = grid.getStore().getAt(rowIndex);
                            var zoomLevel = map.getZoomForExtent(record.data.feature.geometry.getBounds());
                            var centerGeom = record.data.feature.geometry.getBounds().getCenterLonLat();
                            if (zoomLevel > 15){zoomLevel = 15;}
                            map.setCenter(centerGeom,zoomLevel);
                        }
                    }]
                }
            ]
            ,listeners:{
                hiddenchange:function(cm,columnIndex,hidden){
                    var w = Ext.getCmp('synthese_list_grid').getInnerWidth();
                    var cm = Ext.getCmp('synthese_list_grid').getColumnModel();
                    id = cm.getColumnId(columnIndex);
                    var c = cm.getColumnById(id);
                    cw = c.width;
                    if(!hidden){
                        Ext.getCmp('synthese_list_grid').setWidth(w+cw);
                    }
                    else{
                        Ext.getCmp('synthese_list_grid').setWidth(w-cw);
                    }
                    Ext.getCmp('synthese_list_grid').ownerCt.doLayout();
                }   
            }
        });

        syntheseListGrid = new Ext.grid.GridPanel({
            region:"east"
            ,id: 'synthese_list_grid'
            ,xtype: 'grid'
            ,anchor:'30%'
            ,width:450
            ,split: true
            ,store: store
            ,loadMask: true
            // ,columns:columns
            ,colModel : colModel
            ,sm: new Ext.grid.RowSelectionModel({
                singleSelect:true
                ,listeners:{
                    rowselect:function(sm,rowIndex,record){
                        loadTaxonDetails(record);
                    }
                    ,rowdeselect:function(sm,rowIndex,record){
                        loadTaxonDetails(record);
                    }
                }
            })
            ,viewConfig: new Ext.ux.grid.BufferView({
                emptyText:'<span class="pInfo" >Aucune donnée ne peut être affichée. Voir message ci-dessus.</span>'
                ,forceFit:true
                //Return CSS class to apply to rows depending upon data values
                ,getRowClass: function(r, index,rp,ds) {
                    //pour éviter un bug quand il y a trop de réponses, on doit tester s'il y a bien des données
                    if(r.data.cd_nom){
                        var s;
                        if(vectorLayer.getFeatureByFid(r.data.id_synthese)){s = vectorLayer.getFeatureByFid(r.data.id_synthese).onScreen();}
                        else{s = r.get('onscreen');}
                        if (s) {return '';}
                        return 'grey';
                    }
                }
            })
            ,autoExpandColumn: 'taxon'
            ,stripeRows: true
            ,tbar: toolbarItems
            ,listeners:{
                rowdblclick:function(grid,rowIndex){
                    var record = grid.getStore().getAt(rowIndex);
                    if(record){
                        var code = record.data.code_fiche_source;
                        var id_source = record.data.id_source;
                        if(code!='' && code!=null && (id_source==id_source_contactfaune || id_source==id_source_contactflore || id_source==id_source_contactinv || id_source==id_source_mortalite)){
                            var reg=new RegExp("[-]+", "g");
                            var tableau=code.split(reg);
                            var id_fiche = tableau[0].substr(1,20);
                            var id_releve = tableau[1].substr(1,20);
                            var id_protocole = record.data.id_protocole;
                            if(id_source==id_source_contactfaune&&id_protocole==id_protocole_contact_vertebre&&record.data.edit_ok){
                                application.synthese.editCf.loadFiche(id_fiche,'update',null);
                            }
                            if(id_source==id_source_mortalite&&id_protocole==id_protocole_mortalite&&record.data.edit_ok){
                                application.synthese.editMortalite.loadFiche(id_fiche,'update',null);
                            }
                            if(id_source==id_source_contactinv&&id_protocole==id_protocole_contact_invertebre&&record.data.edit_ok){
                                application.synthese.editInvertebre.loadFiche(id_fiche,'update',null);
                            }
                            if(id_source==id_source_contactflore&&id_protocole==id_protocole_contact_flore&&record.data.edit_ok){
                                application.synthese.editCflore.loadFiche(id_fiche,'update',null);
                            }
                            if(!record.data.edit_ok){Ext.ux.Toast.msg('Non, non, non !', 'Vous devez être l\'auteur de cette observation ou administrateur pour la modifier.');}  
                        }
                        else{Ext.ux.Toast.msg('Donnée ancienne', 'Cette observation n\'est pas modifiable.');} 
                    }
                }
            }
        });
        return syntheseListGrid;		
    };

    /**
     * Method: zoomToRecord
     *
     * Parameters:
     * record {Ext.data.Record} - the record which feature to zoom to
     */
    var zoomToRecord = function(record) {
        var extent = record.data.extent.split(',');
        var bounds = new OpenLayers.Bounds(extent[0], extent[1], extent[2], extent[3]);
        var zoomLevel = map.getZoomForExtent(bounds);
        var centerGeom = bounds.getCenterLonLat();
        if (zoomLevel > 16){zoomLevel = 16;}
        map.setCenter(centerGeom,zoomLevel);
    };

    /**
     * Method: getViewportCenterItem
     */
    var getViewportCenterItem = function() {
        createMap();
        toolbar = new mapfish.widgets.toolbar.Toolbar({
            map: map
            ,configurable: false
            ,height:60
        });
        // createMapSearcher();// commenter pour ne pas chercher sur chaque mouvement ou zoom sur la carte

        return {
            region: 'center'
            ,xtype: 'mapcomponent'
            ,id : 'search-tab-mapcomponent'
            ,map: map
            ,width:400
            ,tbar: toolbar
        };
    };
    
    var getUploadShpFormPanel = function(){
        var formUploadShp = new Ext.FormPanel({
            id: 'form-upload-synthse-shp'
            ,fileUpload: true
            ,width: 400
            ,frame: true
            ,autoHeight: true
            ,bodyStyle: 'padding: 10px 10px 0 10px;'
            ,labelWidth: 50
            ,defaults: {
                anchor: '95%',
                allowBlank: false,
                msgTarget: 'side'
            }
            ,items: [{
                xtype: 'hidden',
                name: 'username',
                value: application.synthese.user.nom
            },{
                xtype: 'fileuploadfield',
                emptyText: 'Sélectionner un fichier (format zip uniquement)',
                fieldLabel: 'Fichier',
                name: 'nom_fichier',
                buttonText: '',
                buttonCfg: {
                      iconCls: 'upload-icon'
                }
            }]
            ,buttons: [{
                text: 'Annuler',
                handler: function(){
                    formUploadShp.getForm().reset();
                }
            },{
                text: 'Enregistrer',
                handler: function(){
                    if(formUploadShp.getForm().isValid()){
                        randomnumber = Math.floor(Math.random()*101);
                        var params = {};
                        params.randomnumber = randomnumber;
                        formUploadShp.getForm().submit({
                            url: 'synthese/uploadshp',
                            enctype:'multipart/form-data',
                            waitMsg: 'chargement de votre fichier...',
                            params:params,
                            success: function(form, action){
                                if(action.result.success==true){
                                        application.synthese.search.addGmlFeatures();
                                        Ext.ux.Toast.msg('Téléchargement !', 'Fichier zip de la shape a été téléchargé et ajouté comme zone de recherche.');
                                    }
                                    else{
                                        Ext.ux.Toast.msg('Attention !', 'Téléchargement du fichier zip : <br>'+action.result.errors);
                                    }
                                    application.synthese.search.windowUploadShp.destroy();
                                    
                            },
                            failure :  function(form, action) {
                                if(action.result.success==false){
                                    Ext.ux.Toast.msg('Attention !', 'Une erreur est survenue');
                                }
                                application.synthese.search.windowUploadShp.destroy();
                            }
                        });
                    }
                    else{alert('biiiiiip ! Saisie non valide');}
                }
            }]
        });
        return formUploadShp;
    };
    var initFormUploadShp = function() {
        return new Ext.Window({
          layout:'fit'
            ,title: 'Charger ue couche shape de polygone(s) au format zip : projection Lambert 93 uniquement'
            ,closeAction:'destroy'
            ,plain: true
            ,modal: true
            ,width: 550
            ,buttons: [{
                text: 'Fermer'
                ,handler: function(){
                    application.synthese.search.windowUploadShp.destroy();
                }
            }]
            ,items: [ getUploadShpFormPanel() ]
        });
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
                    ,handler: function() {
                        syntheseListGrid.getView().refresh();
                    }
                }
            );
            
            application.synthese.utils.addSeparator(toolbar);

            var history = new OpenLayers.Control.NavigationHistory();
            map.addControl(history);
            toolbar.addControl(history.previous, {
                iconCls: 'previous'
                ,toggleGroup: 'navigation'
                ,tooltip: 'Etendue précédente'
                ,handler: function() {
                    syntheseListGrid.getView().refresh();
                }
            });

            toolbar.addControl(
                new OpenLayers.Control.ZoomBox({
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
                    title: 'Déplacer la carte'
                    ,isDefault: true
                }), {
                    iconCls: 'pan',
                    toggleGroup: this.id
                    ,handler: function() {
                        selectControl.activate();
                    }   
                }
            );
            
            application.synthese.utils.addSeparator(toolbar);

            toolbar.add({
                text: 'shp'
                ,id: 'edit-synthese-shp'
                ,iconCls: 'import_shape'
                ,tooltip: 'Télécharger un fichier shape de polygone(s) au format zip comme zone(s) de recherche. Projection Lambert 93 uniquement.'
                ,handler: function() {
                    if (application.synthese.searchVectorLayer.features.length>0 && mapBoundsSearch==false) {
                        Ext.Msg.confirm('Dessiner une autre zone de recherche à partir d\'un fichier shape?'
                            ,'Voulez vous supprimer la zone de recherche existante ?'
                            ,function(btn) {
                                if (btn == 'yes') {
                                    Ext.getCmp('hidden-geom').setValue(null);
                                    application.synthese.searchVectorLayer.removeAllFeatures();
                                    application.synthese.search.addGml();
                                }
                            }
                        );
                    }
                    else{application.synthese.search.addGml();}
                    Ext.getCmp('combo-communes').clearValue();
                    Ext.getCmp('combo-secteurs').clearValue();
                }
            });
            toolbar.addControl(
              drawPolygonControl = new OpenLayers.Control.DrawFeature(application.synthese.searchVectorLayer, OpenLayers.Handler.Polygon, {
                title: 'Dessiner une zone de recherche'
              })
              ,{
                iconCls: 'drawpolygon'
                ,toggleGroup: this.id
                ,handler: function(){
                    application.synthese.searchVectorLayer.events.on({
                        "featureadded":function(feature){
                            if(mapBoundsSearch==true){
                                application.synthese.searchVectorLayer.removeFeatures(application.synthese.searchVectorLayer.features[0]);
                                mapBoundsSearch=false;
                            }
                            if(application.synthese.searchVectorLayer.features.length>1){
                                Ext.Msg.confirm('Definir une autre zone de recherche ?'
                                    ,'Voulez vous supprimer la zone de recherche précédente ?'
                                    ,function(btn) {
                                        if (btn == 'yes') {
                                            Ext.getCmp('hidden-geom').setValue(null);
                                            application.synthese.searchVectorLayer.removeFeatures(application.synthese.searchVectorLayer.features[0]);
                                        }
                                        else{application.synthese.searchVectorLayer.removeFeatures(application.synthese.searchVectorLayer.features[1]);}
                                    }
                                );
                            }
                            
                        }
                    });
                    Ext.getCmp('combo-communes').clearValue();
                    Ext.getCmp('combo-secteurs').clearValue();
                }
              }
            );

            toolbar.addControl(
              modifyFeatureControl = new OpenLayers.Control.ModifyFeature(application.synthese.searchVectorLayer, {
                title: 'Modifier la zone de recherche'
              }), {
                iconCls: 'modifyfeature'
                ,toggleGroup: this.id
              }
            );
            toolbar.add({
                id: 'edit-observation-geometry-erase'
                ,iconCls: 'erase'
                ,tooltip: 'Supprimer la zone de recherche'
                ,handler: function() {
                    Ext.Msg.confirm('Attention'
                        ,'Voulez vous supprimer la zone de recherche existante ?'
                        ,function(btn) {
                            if (btn == 'yes') {
                                Ext.getCmp('hidden-geom').setValue(null);
                                application.synthese.searchVectorLayer.removeAllFeatures();
                            }
                        }
                    );
                }
            });
            
            application.synthese.utils.addSeparator(toolbar);
            toolbar.add({
                iconCls: 'legend'
                ,id:'search-layertreetip'
                ,enableToggle: true
                ,tooltip: 'Gérer les couches affichées'
                ,handler: function(button) {
                    showLayerTreeTip(button.pressed);
                }
            });

            toolbar.add('->');
            toolbar.activate();
            toolbarInitializedOnce = true;
        }
    };

    /**
     * Method: showLayerTreeTip
     * Shows or hide the layer tree tip
     */
    var showLayerTreeTip = function(show) {
        layerTreeTip.setVisible(show);
    };


    /**
     * Method: getFormItems
     */
    var getFormItems = function() {
        myProxyCommunes = new Ext.data.HttpProxy({
            url: 'bibs/communes'
            ,method: 'GET'
        });
        var communesStore = new Ext.data.JsonStore({
            storeId:'communes-store'
            ,url: myProxyCommunes
            ,fields: [
                'insee'
                ,'nomcommune'
                ,'extent'
            ]
            ,sortInfo: {
                field: 'nomcommune'
                ,direction: 'ASC'
            }
            ,autoLoad: true
        });
        myProxySecteurs = new Ext.data.HttpProxy({
            url: 'bibs/secteurssynthese'
            ,method: 'GET'
        });
        var secteursStore = new Ext.data.JsonStore({
            storeId:'secteurs-store'
            ,url: myProxySecteurs
            ,fields: [
                'id_secteur'
                ,'nom_secteur'
                ,'extent'
            ]
            ,sortInfo: {
                field: 'nom_secteur'
                ,direction: 'ASC'
            }
            ,autoLoad: true
        });
        var checkboxComment = function(){
            var cbGroup = [];
            application.synthese.storeProgrammes.each(function(record){
                var id = record.data.id_programme;
                var chk = true;
                // if(id == 6 || id == 7 || id == 8){chk = false;}
                var cb = new Ext.form.Checkbox({
                    boxLabel: record.data.nom_programme
                    ,name: 'p-'+id
                    ,inputValue: id
                    ,submitValue:false
                    ,checked: chk
                    ,listeners: {
                        render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl()
                                ,text: record.data.desc_programme
                            });
                        }
                    }
                });
                cbGroup.push(cb);
            });
            return cbGroup;
        };
        
        var mesItems = [{
            // Fieldset 
            xtype:'fieldset'
            ,id:'fieldset-1-synthese'
            ,columnWidth: 1
            ,title: 'Quoi ?'
            ,collapsible: true
            ,autoHeight:true
            ,anchor:'98%'
            ,defaults: {
                anchor: '-20' // leave room for error icon}
                ,hideLabel: true
            }
            ,items :[
                {
                    xtype:'hidden'
                    ,id:'hidden-zoom'
                    ,name:'zoom'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-start'
                    ,name:'start'
                    ,value:'yes'
                },{
                    xtype:'hidden'
                    ,id:'hidden-patri'
                    ,name:'patrimonial'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-protege'
                    ,name:'protection_stricte'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-idstaxons'
                    ,name:'idstaxons'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-programmes'
                    ,name:'programmes'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-geom'
                    ,name:'searchgeom'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-commune'
                    ,name:'commune'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-secteur'
                    ,name:'secteur'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-extent'
                    ,name:'extent'
                    ,value:''
                },{
                    xtype: 'radiogroup'
                    ,id:'radio-fff'
                    ,items: [
                        {boxLabel: 'Faune', name: 'fff', inputValue: 'Animalia'},
                        {boxLabel: 'Flore', name: 'fff', inputValue: 'Plantae'},
                        {boxLabel: 'Fonge', name: 'fff', inputValue: 'Fungi'},
                        {boxLabel: 'Tout', name: 'fff', inputValue: 'all', checked: true},
                    ]
                    ,listeners: {
                        change: function(cb,checked) {
                            application.synthese.search.manageCombosTaxons();
                            if(application.synthese.search.windowTaxons){application.synthese.search.manageTree();}
                        }
                    }
                },{
                    xtype: 'checkbox'
                    ,id: 'cb-patri'
                    ,fieldLabel: ''
                    ,cls:'bluebold'
                    ,boxLabel: 'Taxons patrimoniaux'
                    ,inputValue: true
                    ,name: 'rb-patri'
                    ,listeners: {
                        check: function(cb,checked) {
                            if(checked){Ext.getCmp('hidden-patri').setValue(true);}
                            else{Ext.getCmp('hidden-patri').setValue(false);}
                            application.synthese.search.manageCombosTaxons();
                            if(application.synthese.search.windowTaxons){application.synthese.search.manageTree();}
                        }
                    }
                },{
                    xtype: 'checkbox'
                    ,id: 'cb-protege'
                    ,fieldLabel: ''
                    ,cls:'bluebold'
                    ,boxLabel: 'Taxons protégés'
                    ,inputValue: true
                    ,name: 'rb-protege'
                    ,listeners: {
                        check: function(cb,checked) {
                            if(checked){Ext.getCmp('hidden-protege').setValue(true);}
                            else{Ext.getCmp('hidden-protege').setValue(false);}
                            application.synthese.search.manageCombosTaxons();
                            if(application.synthese.search.windowTaxons){application.synthese.search.manageTree();}
                        }
                    }
                },{
                    xtype:"twintriggercombo"
                    ,id:'combo-synthese-taxons-fr'
                    // ,tpl: '<tpl for="."><div class="x-combo-list-item" style="<tpl if="patrimonial">font-weight:bold</tpl>" ><img src="{picto}" width=20 height=20/> {nom_francais}</div></tpl></tpl>'
                    ,emptyText: "Taxons français"
                    ,name:"taxonfr"
                    ,hiddenName:"taxonfr"
                    ,store: application.synthese.storeTaxonsSyntheseFr
                    ,valueField: "cd_nom"
                    ,displayField: "nom_francais"
                    ,valueNotFoundText:"Ce taxon n'a pas de nom français"
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,listWidth: 230
                    ,anchor:'95%'
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                    ,listeners: {
                        expand: function(combo, record) {
                            combo.getStore().sort('nom_francais','ASC');
                        }
                        ,select: function(combo, record, index){
                            Ext.getCmp('combo-synthese-taxons-latin').setValue(record.data.cd_nom);
                            if(application.synthese.search.windowTaxons){application.synthese.search.resetTree();}
                            Ext.getCmp('label-choix-taxons').setText('');                            
                        }
                    }
                },{
                    xtype:"twintriggercombo"
                    ,id:'combo-synthese-taxons-latin'
                    // ,tpl: '<tpl for="."><div class="x-combo-list-item" style="<tpl if="patrimonial">font-weight:bold</tpl>" ><img src="{picto}" width=20 height=20/> {nom_latin}</div></tpl></tpl>'
                    ,emptyText: "Taxons latin"
                    ,name:"taxonl"
                    ,hiddenName:"taxonl"
                    ,store: application.synthese.storeTaxonsSyntheseLatin
                    ,valueField: "cd_nom"
                    ,displayField: "nom_latin"
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,listWidth: 260
                    ,anchor:'95%'
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                    ,listeners: {
                        expand: function(combo, record) {
                            combo.getStore().sort('nom_latin','ASC');
                        }
                        ,select: function(combo, record, index){
                            Ext.getCmp('combo-synthese-taxons-fr').setValue(record.data.cd_nom);
                            if(application.synthese.search.windowTaxons){application.synthese.search.resetTree();}
                            Ext.getCmp('label-choix-taxons').setText('');
                        }
                    }
                },{
                    xtype: 'button'
                    ,text: 'choisir plusieurs taxons'
                    ,id: 'choise-taxons'
                    ,iconCls: 'tetras'
                    ,qtip: 'Ouvre une fenêtre permettant de construire une requête renvoyant plusieurs taxons'
                    ,handler: function() {
                        Ext.getCmp('radio-fff').setValue('all');
                        application.synthese.search.choiseTaxons();
                    }
                }
                ,{id:'label-choix-taxons',xtype:'label',text: '',cls:'redbold'}
            ]
        },{
            // Fieldset 
            xtype:'fieldset'
            ,id:'fieldset-2-synthese'
            ,columnWidth: 1
            ,title: 'Quand ?'
            ,collapsible: true
            ,autoHeight:true
            ,anchor:'98%'
            ,defaults: {
                anchor: '-20' // leave room for error icon}
                ,hideLabel: true
            }
            ,items :[
                {
                    id: 'datedebut'
                    ,xtype:'datefield'
                    ,fieldLabel: 'Date début'
                    ,emptyText: 'Date début'
                    ,name: 'datedebut'
                    ,maxValue: new Date()
                    ,format: 'd/m/Y'
                    ,value:  new Date(cetteAnnee - 10,0,1)
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                    ,listeners:{ 
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                        ,render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl()
                                ,text: 'Date de début'
                            });
                        }                        
                    }
                },{
                    id: 'datefin'
                    ,xtype:'datefield'
                    ,fieldLabel: 'Date fin'
                    ,emptyText: 'Date fin'
                    ,name: 'datefin'
                    ,maxValue: new Date()
                    ,format: 'd/m/Y'
                    ,value: new Date()
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                    ,listeners:{ 
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                        ,render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl()
                                ,text: 'Date de fin'
                            });
                        }                        
                    }
                }
                ,{xtype:'label',text: 'Limiter la recherche à une période',cls:'bluebold'}
                ,{
                    id: 'periodedebut'
                    ,xtype:'datefield'
                    ,fieldLabel: 'Période début'
                    ,emptyText: 'Période début'
                    ,name: 'periodedebut'
                    ,format: 'd/m'
                    ,value: new Date(2000,0,1)
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                    ,listeners:{ 
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);} 
                        ,render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl()
                                ,text: 'Saisir une date de début de période, sans l\'année, au format 19/11'
                            });
                        }
                    }
                },{
                    id: 'periodefin'
                    ,xtype:'datefield'
                    ,fieldLabel: 'Période fin'
                    ,emptyText: 'Période fin'
                    ,name: 'periodefin'
                    ,format: 'd/m'
                    ,value: new Date(2000,11,31)
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                    ,listeners:{ 
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                        ,render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl()
                                ,text: 'Saisir une date de fin de période, sans l\'année, au format 19/11'
                            });
                        }
                    }
                }
            ]
        }
        ,{
            // Fieldset 
            xtype:'fieldset'
            ,id:'fieldset-3-synthese'
            ,columnWidth: 1
            ,title: 'Où ?'
            ,collapsible: true
            ,autoHeight:true
            ,anchor:'98%'
            ,defaults: {
                anchor: '-20' // leave room for error icon}
                ,hideLabel: true
            }
            ,items :[
                {
                    xtype:"twintriggercombo"
                    ,id: 'combo-secteurs'
                    ,emptyText: "Secteur"
                    ,name:"nom_secteur"
                    ,hiddenName:"id_secteur"
                    ,store: secteursStore
                    ,valueField: "id_secteur"
                    ,displayField: "nom_secteur"
                    ,typeAhead: true
                    ,anchor:'95%'
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: false
                    ,rezisable:true
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-hidden'
                    ,listeners: {
                        beforeselect: function(combo, record) {
                            if (application.synthese.searchVectorLayer.features.length>0 && mapBoundsSearch==false) {
                                Ext.Msg.confirm('Vous aviez dessiné ou téléchargé une zone de recherche.'
                                    ,'Voulez vous supprimer cette zone de recherche ?'
                                    ,function(btn) {
                                        if (btn == 'yes') {
                                            Ext.getCmp('hidden-geom').setValue(null);
                                            application.synthese.searchVectorLayer.removeAllFeatures();
                                            return true;
                                        }
                                        combo.clearValue();
                                        return false;
                                    }
                                );
                            } 
                        }
                        ,select: function(combo, record) {
                            Ext.getCmp('combo-reserves').clearValue();
                            Ext.getCmp('combo-n2000').clearValue();
                            Ext.getCmp('combo-communes').clearValue();
                            myProxyCommunes.url = 'bibs/communes?secteur='+combo.getValue();
                            communesStore.reload();
                            Ext.getCmp('hidden-extent').setValue(record.data.extent);   
                            Ext.getCmp('hidden-secteur').setValue(record.data.id_secteur); 
                            Ext.getCmp('hidden-commune').setValue('');                            
                        }
                        ,clear: function(combo) {
                            Ext.getCmp('combo-communes').clearValue();
                            Ext.getCmp('hidden-secteur').setValue('');
                            Ext.getCmp('hidden-commune').setValue('');
                            myProxyCommunes.url = 'bibs/communes';
                            communesStore.reload();
                        }
                    }
                },{
                    xtype:"twintriggercombo"
                    ,id: 'combo-communes'
                    ,emptyText: "Commune"
                    ,name:"nomcommune"
                    ,hiddenName:"insee"
                    ,store: communesStore
                    ,valueField: "insee"
                    ,displayField: "nomcommune"
                    ,listWidth: 200
                    ,anchor:'95%'
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,resizable: true
                    ,mode: 'local'
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-hidden'
                    ,listeners: {
                        beforeselect: function(combo, record) {
                            if (application.synthese.searchVectorLayer.features.length>0 && mapBoundsSearch==false) {
                                Ext.Msg.confirm('Vous aviez dessiné ou téléchargé une zone de recherche.'
                                    ,'Voulez vous supprimer cette zone de recherche ?'
                                    ,function(btn) {
                                        if (btn == 'yes') {
                                            Ext.getCmp('hidden-geom').setValue(null);
                                            application.synthese.searchVectorLayer.removeAllFeatures();
                                            return true;
                                        }
                                        combo.clearValue();
                                        return false;
                                    }
                                );
                            } 
                        }
                        ,select: function(combo, record) {
                            Ext.getCmp('combo-reserves').clearValue();
                            Ext.getCmp('combo-n2000').clearValue();
                            Ext.getCmp('hidden-commune').setValue(record.data.insee);
                        }
                        ,clear: function(combo) {
                            combo.reset();
                            Ext.getCmp('hidden-commune').setValue('');
                        }
                    }
                }
                ,{
                    xtype:"twintriggercombo"
                    ,id: 'combo-reserves'
                    ,emptyText: "Reserve"
                    ,name:"nom_reserve"
                    ,hiddenName:"id_reserve"
                    ,store: application.synthese.storeReserves
                    ,valueField: "id_reserve"
                    ,displayField: "nom_reserve"
                    ,listWidth: 200
                    ,anchor:'95%'
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,resizable: true
                    ,mode: 'local'
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-hidden'
                    ,listeners: {
                        beforeselect: function(combo, record) {
                            if (application.synthese.searchVectorLayer.features.length>0 && mapBoundsSearch==false) {
                                Ext.Msg.confirm('Vous aviez dessiné ou téléchargé une zone de recherche.'
                                    ,'Voulez vous supprimer cette zone de recherche ?'
                                    ,function(btn) {
                                        if (btn == 'yes') {
                                            Ext.getCmp('hidden-geom').setValue(null);
                                            application.synthese.searchVectorLayer.removeAllFeatures();
                                            return true;
                                        }
                                        combo.clearValue();
                                        return false;
                                    }
                                );
                            } 
                        }
                        ,select: function(combo, record) {
                            Ext.getCmp('combo-communes').clearValue();
                            Ext.getCmp('combo-secteurs').clearValue();
                            Ext.getCmp('combo-n2000').clearValue();
                        }
                        ,clear: function(combo) {
                            combo.reset();
                        }
                    }
                },{
                    xtype:"twintriggercombo"
                    ,id: 'combo-n2000'
                    ,emptyText: "Natura 2000"
                    ,name:"nom_n2000"
                    ,hiddenName:"id_n2000"
                    ,store: application.synthese.storeN2000
                    ,valueField: "id_n2000"
                    ,displayField: "nom_n2000"
                    ,listWidth: 200
                    ,anchor:'95%'
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,resizable: true
                    ,mode: 'local'
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-hidden'
                    ,listeners: {
                        beforeselect: function(combo, record) {
                            if (application.synthese.searchVectorLayer.features.length>0 && mapBoundsSearch==false) {
                                Ext.Msg.confirm('Vous aviez dessiné ou téléchargé une zone de recherche.'
                                    ,'Voulez vous supprimer cette zone de recherche ?'
                                    ,function(btn) {
                                        if (btn == 'yes') {
                                            Ext.getCmp('hidden-geom').setValue(null);
                                            application.synthese.searchVectorLayer.removeAllFeatures();
                                            return true;
                                        }
                                        combo.clearValue();
                                        return false;
                                    }
                                );
                            } 
                        }
                        ,select: function(combo, record) {
                            Ext.getCmp('combo-communes').clearValue();
                            Ext.getCmp('combo-secteurs').clearValue();
                            Ext.getCmp('combo-reserves').clearValue();
                        }
                        ,clear: function(combo) {
                            combo.reset();
                        }
                    }
                }
                ,{xtype:'label',text: 'Pour dessiner une zone de recherche, cliquer sur le bouton jaune dans la barre au dessus de la carte',cls:'bluetext'}
            ]
        },{
            // Fieldset 
            xtype:'fieldset'
            ,id:'fieldset-5-synthese'
            ,columnWidth: 1
            ,title: 'Qui ?'
            ,collapsible: true
            ,autoHeight:true
            ,anchor:'98%'
            ,defaults: {
                anchor: '-20' // leave room for error icon}
                ,hideLabel: true
            }
            ,items :[{
                    id: 'textfield-observateur'
                    ,xtype:'textfield'
                    ,emptyText: "Observateur"
                    ,name: 'observateur'
                    ,anchor: '95%'
                    ,listeners: {
                        render: function(c) {
                            Ext.QuickTips.register({
                                target: c.getEl(),
                                text: 'Saisir librement le nom ou le début du nom d\'un observateur.'
                            });
                        }
                    }
                }
            ]//fin du items
        },{
            // Fieldset 
            xtype:'fieldset'
            ,id:'fieldset-4-synthese'
            ,columnWidth: 1
            ,title: 'Comment ?'
            ,collapsible: true
            ,collapsed:true
            ,autoHeight:true
            ,anchor:'98%'
            ,defaults: {
                anchor: '-20' // leave room for error icon}
                ,hideLabel: true
            }
            ,items :[
                {xtype:'label',text: 'Attention certains programmes ne sont pas cochés par défaut',cls:'bluetext'}
                ,{
                    xtype: 'checkboxgroup'
                    ,id:'cbg-programmes'
                    ,itemCls: 'x-check-group-alt'
                    ,columns: 1
                    ,items: checkboxComment()
                    ,listeners: {
                        change: function(cbg, arrayChecked) {
                            var a = [];
                            Ext.each(arrayChecked,function(cb){
                                if(cb.checked){a.push(cb.inputValue);}
                            });
                            Ext.getCmp('hidden-programmes').setValue(a.join(','));
                        }
                    }
                }
            ]
        }//fin du fieldset
        ];//fin de mesItems        
        return mesItems;
    };

    /**
     * Method: createLayer
     * Creates the vector layer
     *
     * Return
     * <OpenLayers.Layer.Vector>
     */
    var createLayer = function() {
        var syntheseDefaultStyle = new OpenLayers.Style(
        );
        //règles de coloration des points selon patrimonialité
    var rule0 = new OpenLayers.Rule({
		filter: new OpenLayers.Filter.Comparison({
			type: OpenLayers.Filter.Comparison.EQUAL_TO
			,property: "patrimonial"
			,value: false
		}),
		symbolizer: {
			fillColor:'#FF9922' //rouge clair
			,pointRadius: 5
			,strokeColor:'#f00' //contour rouge
			,strokeWidth:1
            ,fillOpacity:0.4
			,graphicZIndex:1
		}
	});
	var rule1 = new OpenLayers.Rule({
		filter: new OpenLayers.Filter.Comparison({
			type: OpenLayers.Filter.Comparison.EQUAL_TO
			,property: "patrimonial"
			,value: true
		}),
		symbolizer: {
			fillColor:'#8a62a2' //violet
			,pointRadius: 5
			,strokeColor:'#f00' //contour rouge
			,strokeWidth:2
            ,fillOpacity:0.4
			,graphicZIndex:2 // au dessus des non patrimoniaux
		}
	});
	syntheseDefaultStyle.addRules([rule0, rule1]);
    var syntheseSelectStyle = new OpenLayers.Style({
		fillColor:'#808080' //bleu clair
		,pointRadius: 7
		,strokeColor:'#00f' //contour bleu
		,strokeWidth:2
		,graphicZIndex:3 //toujours dessus
	});

        var styleMap = new OpenLayers.StyleMap({
            'default':syntheseDefaultStyle
           ,'select': syntheseSelectStyle
        });

        vectorLayer = new OpenLayers.Layer.Vector("vector"
            ,{
                protocol: eventProtocol
                ,strategies: [
                    new mapfish.Strategy.ProtocolListener()
                ]
                ,styleMap: styleMap
                ,rendererOptions: { zIndexing: true }
                ,format: OpenLayers.Format.GeoJSON
                ,projection : map.getProjection()
                ,units: map.getProjection().getUnits()
                ,maxExtent: extent_max
            }
        );
        return vectorLayer;
    };

    /**
     * Method: createMap
     * Creates the map
     *
     * Return
     * <OpenLayers.Map>
     */
    var createMap = function() {
        map = application.synthese.createMap();
        var vector = createLayer();
        map.addLayers([vector]);
        function createPopup(feature) {
            var dataDiv = '<div class="popupGeoNature"><span style="font-weight:bold;color:orangered">'+ feature.attributes.taxon_francais+ '</span><br/>';
            if(feature.attributes.dateobs){
                var maDate = Ext.util.Format.date(feature.data.dateobs,'d/m/Y');
                dataDiv = dataDiv + '<span style="font-size:0.85em">Le '+ maDate+'</span>';
            }
            dataDiv = dataDiv + '</div>';
            feature.popup = new OpenLayers.Popup("data",
                feature.geometry.getBounds().getCenterLonLat(),
                null,
                dataDiv,
                false
            );
            feature.popup.backgroundColor='#fff';
            feature.popup.opacity=0.8;
            feature.popup.autoSize=true;
            // feature.popup.displayClass='popupGeoNature';
            feature.popup.keepInMap=true;
            map.addPopup(feature.popup);
        }
 
        // This function destroys the popup when the user clicks the X.
        function destroyPopup(feature) {
            if(feature.popup!=null){feature.popup.destroy();}
            feature.popup = null;
        }
        selectControl = new OpenLayers.Control.SelectFeature(vector, {
            multiple: false
            ,id:'vectorselect'
            ,onSelect: createPopup
            ,hover:true
            ,onUnselect: destroyPopup
        });
        var mediator = new mapfish.widgets.data.GridRowFeatureMediator({
            grid: syntheseListGrid,
            selectControl: selectControl
        });
        map.addControl(selectControl);
        selectControl.activate();

        map.zoomToMaxExtent();
        maMap = map;//debug
    };


    /**
     * Method: createMapSearcher
     */
    var createMapSearcher = function() {
        mapSearcher = new mapfish.Searcher.Map({
            protocol: eventProtocol
            ,mode: mapfish.Searcher.Map.EXTENT
            ,map: map
        });
        mapSearcher.activate();
        filterProtocol.register(mapSearcher);
    };
//------------------------------------fenêtre pour choisir pls taxons---------------------------------------------------
    
    //construction automatique de l'arbre des taxons à partir de la base de données
    var constructListTaxons = function(){
        var monArbre = [];
        var childrensRegne = [];
        var childrensEmbranchement = [];
        var childrensClasse = [];
        var childrensOrdre = [];
        var childrensFamille = [];
        var kd = null;
        var emb = null;
        var cl = null;
        var desc_cl = null;
        var ord = null;
        var fam = null;
        var nouveauRegne=false;
        var nouvelEmbranchement=false;
        var nouvelleClasse=false;
        var nouvelOrdre=false;
        var nouvelleFamille=false;
        var child = {};
        var regne = {};
        var embranchement = {};
        var classe = {};
        var ordre = {};
        var famille = {};
        //on bouble sur les enregistrements du store des taxons issu de la base
        application.synthese.taxonsTreeStore.each(function(record){
            if(kd==null){kd = record.data.nom_regne;}//initialisation
            if(emb==null){emb = record.data.nom_embranchement;}//initialisation
            if(cl==null){cl = record.data.nom_classe;}//initialisation
            if(desc_cl==null){desc_cl = record.data.desc_classe;}//initialisation
            if(ord==null){ord = record.data.nom_ordre;}//initialisation
            if(fam==null){fam = record.data.nom_famille;}//initialisation
            if(kd != record.data.nom_regne){nouveauRegne=true;}// si on a changé de niveau de règne
            if(emb != record.data.nom_embranchement){nouvelEmbranchement=true;}// si on a changé de niveau d'embranchement
            if(cl != record.data.nom_classe){nouvelleClasse=true;}// si on a changé de niveau de classe
            if(ord != record.data.nom_ordre){nouvelOrdre=true;}// si on a changé de niveau d'ordre
            if(fam != record.data.nom_famille){nouvelleFamille=true;}// si on a changé de niveau de famille
            //création d'un noeud final avec checkbox
            child = {
                id:record.data.cd_ref
                ,text:record.data.nom_latin+' - '+record.data.nom_francais
                ,leaf:true
                ,checked:false
            };
            if(nouvelleFamille){ //on crée le groupe
                famille = {
                    text: fam
                    ,checked:false
                    ,children:childrensFamille
                };
                childrensOrdre.push(famille); //on ajoute ce groupe à l'arbre
                nouvelleFamille=false; //on repasse à false pour les prochains tests
                childrensFamille = []; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
            }
            if(nouvelOrdre){ //on crée le groupe
                ordre = {
                    text: ord
                    ,checked:false
                    ,children:childrensOrdre
                };
                childrensClasse.push(ordre); //on ajoute ce groupe à l'arbre
                nouvelOrdre=false; //on repasse à false pour les prochains tests
                childrensOrdre = []; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
            }
            if(nouvelleClasse){ //on crée le groupe
                classe = {
                    text: cl+ ' - ' +desc_cl
                    ,checked:false
                    ,children:childrensClasse
                };
                childrensEmbranchement.push(classe); //on ajoute ce groupe à l'arbre
                nouvelleClasse=false; //on repasse à false pour les prochains tests
                childrensClasse = []; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
            }
            if(nouvelEmbranchement){ //on crée le groupe
                embranchement = {
                    text: emb
                    ,checked:false
                    ,children:childrensEmbranchement
                };
                childrensRegne.push(embranchement); //on ajoute ce groupe à l'arbre
                nouvelEmbranchement=false; //on repasse à false pour les prochains tests
                childrensEmbranchement = []; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
            }
            if(nouveauRegne){ //on crée le groupe
                regne = {
                    text: kd
                    ,checked:false
                    ,children:childrensRegne
                };
                monArbre.push(regne); //on ajoute ce groupe à l'arbre
                nouveauRegne=false; //on repasse à false pour les prochains tests
                childrensRegne = []; //on vide la variable qui contenait le groupe pour en accueillir un nouveau
            }
            childrensFamille.push(child);//ajout du noeud au groupe
            kd = record.data.nom_regne; //kd prend la valeur en cours du groupe pour un nouveau test en début de boucle 
            emb = record.data.nom_embranchement; //emb prend la valeur en cours du groupe pour un nouveau test en début de boucle 
            cl = record.data.nom_classe; //cl prend la valeur en cours du groupe pour un nouveau test en début de boucle 
            desc_cl = record.data.desc_classe; //
            ord = record.data.nom_ordre; //ord prend la valeur en cours du groupe pour un nouveau test en début de boucle 
            fam = record.data.nom_famille; //fam prend la valeur en cours du groupe pour un nouveau test en début de boucle
        }); //fin de la boucle
        //ajout du dernier groupe après la fin de la dernière boucle
        famille = {
            text: fam
            ,checked:false
            ,children:childrensFamille
        };
        ordre = {
            text: ord
            ,checked:false
            ,children:childrensOrdre
        };
        classe = {
            text: cl+ ' - ' +desc_cl
            ,checked:false
            ,children:childrensClasse
        };
        embranchement = {
            text: emb
            ,checked:false
            ,children:childrensEmbranchement
        };
        regne = {
            text: kd
            ,checked:false
            ,children:childrensRegne
        };
        childrensOrdre.push(famille);
        childrensClasse.push(ordre);
        childrensEmbranchement.push(classe);
        childrensRegne.push(embranchement);
        monArbre.push(regne);
        return monArbre;
    };
    var getTaxonsFormPanel = function(){
        var formTaxons = new Ext.FormPanel({
            id: 'form-taxons'
            ,width: 500
            ,frame: true
            ,autoHeight: true
            ,bodyStyle: 'padding: 10px 10px 0 10px;'
            ,labelWidth: 50
            ,defaults: {
                anchor: '95%',
                allowBlank: false,
                msgTarget: 'side'
            }
            ,items: [{
                xtype: 'hidden'
                ,name: 'idstaxons'
                ,value: ''
            }
            ,{id:'label-patience-tree',xtype:'label',text: 'Vous pouvez choisir par espèce ou par groupe d\'espèces',cls:'redbold'}
            ,{
                xtype: 'treepanel'
                ,autoScroll: true
                ,id: 'tree-taxons'
                ,animate: false
                ,anchor:'95%'
                ,root: {
                    text: 'Taxons'
                    ,children: constructListTaxons()
                }
                ,listeners:{
                    checkchange:function(node,checked){
                        node.getOwnerTree().suspendEvents();
                        var label =  Ext.getCmp('label-patience-tree');
                        label.setText('La machine travaille mais y\'a du boulot, patience...');
                        treeMask.show();

                        //On décale d'un dixième de seconde la gestion de l'arbre, pour qu'Ext ai le temps d'afficher le mask et faire le changement de label
                          //Fonction récursive qui va étendre et cocher/décocher l'ensemble des descendant du noeud passé en paramètre
                          var cascadeToggle = function(treeChunk, expand, isRoot){
                            //On étend ou non le noeud suivant si la case est coché ou non
                            if (expand) {
                                treeChunk.expand();
                            } else {
                                treeChunk.collapse();
                            }

                            //Si on est pas sur le noeud racine
                            if(isRoot !== true){
                                //Alors on joue sur la checkbox
                                treeChunk.getUI().toggleCheck(expand);
                            }

                            //Si le noeud courant a des enfant
                            if(!Ext.isEmpty(treeChunk.childNodes)){
                                //Alors on boucle dessus et on relance cette fonction, avec chaque enfant
                                Ext.each(treeChunk.childNodes, function(childNode) {
                                    cascadeToggle(childNode, expand, false);
                                });
                            }
                          };

                        Ext.defer(function(){
                            cascadeToggle(node, checked, true);
                            application.synthese.search.manageTree(true);
                            node.getOwnerTree().resumeEvents();
                            label.setText('Vous pouvez choisir par espèce ou par groupe d\'espèces');
                            treeMask.hide();
                        },25);                

                  }
               }

            }
            ]
        });
        return formTaxons;
    };
    var initFormTaxons = function() {
        return new Ext.Window({
            id:'windows-taxons-tree'
            ,layout:'fit'
            ,title: 'Choisir plusieurs taxons'
            ,closeAction:'hide'
            ,plain: true
            ,modal: true
            ,autoScroll:true
            ,width: 650
            ,height:500
            ,buttons: [{
                text: 'Réinitialiser de la liste',
                handler: function(){
                    application.synthese.search.resetTree();
                }
            },{
                text: 'Valider et fermer',
                handler: function(){
                    application.synthese.search.windowTaxons.hide();
                }
            }]
            ,items: [ getTaxonsFormPanel() ]
            ,listeners: {
                show: function(){
                    Ext.getCmp('combo-synthese-taxons-fr').clearValue();
                    Ext.getCmp('combo-synthese-taxons-latin').clearValue();
                }
                ,hide: function(){
                    if(Ext.getCmp('search-form').getForm().findField('idstaxons').getValue() == ''){
                        Ext.getCmp('label-choix-taxons').setText('');
                    }
                }
            }
        });
    };
//---------------------------------------fin de la fenêtre pour choisir pls taxons----------------------------------------------------
        
    // public space
    return {
        init: function() {
            createProtocol();
            return initPanel();
            
        }
        ,initWindowTaxons: function() {
                this.windowTaxons = initFormTaxons();
                treeMask = new Ext.LoadMask(Ext.getBody(), {msg:"Patience ça bosse..."});
        }
        ,choiseTaxons: function() {
            if (!this.windowTaxons) {this.initWindowTaxons();}
            this.windowTaxons.show();
        }
        ,manageTree: function(masked){
            //récupération des valeurs des cases à cocher patrimoniaux et protégés
            //Si on a deja appliqué un mask, on ne le refait pas
            if(masked !== true){
              treeMask.show();
              Ext.getCmp('label-patience-tree').setText('La machine travaille mais y\'a du boulot, patience...');
            }
            Ext.getCmp('windows-taxons-tree').doLayout();
            var patri = Ext.getCmp('hidden-patri').getValue();
            var protege = Ext.getCmp('hidden-protege').getValue();
            var txtTaxons = 'Taxons';
            var fff = Ext.getCmp('radio-fff').getValue().inputValue;
            if(fff == 'all'){
                if (patri =='true' && protege =='true'){txtTaxons='Taxons patrimoniaux et protégés ';}
                else if (patri =='true' && protege !='true'){txtTaxons='Taxons patrimoniaux ';}
                else if (patri !='true' && protege =='true'){txtTaxons='Taxons protégés ';}
            }
            else{
                if (patri =='true' && protege =='true'){txtTaxons=fff+' -  Taxons patrimoniaux et protégés ';}
                else if (patri =='true' && protege !='true'){txtTaxons=fff+' -  Taxons patrimoniaux ';}
                else if (patri !='true' && protege =='true'){txtTaxons=fff+' -  Taxons protégés ';}
            }
            var t = Ext.getCmp('tree-taxons');
            var compt = 0;
            var ids = [];
            application.synthese.taxonsTreeStore.each(function(record){
                var node = t.getNodeById(record.data.cd_nom);
                var includeRecord = false;
                if(fff == null){
                    if (patri !='true' && protege !='true'){includeRecord=true;}
                    else if (patri =='true' && protege =='true'){if(record.data.patrimonial==true && record.data.protection_stricte == true){includeRecord=true;}}
                    else if (patri =='true' && protege !='true'){if(record.data.patrimonial==true){includeRecord=true;}}
                    else if (patri !='true' && protege =='true'){if(record.data.protection_stricte == true){includeRecord=true;}}
                }
                else{
                    if (patri !='true' && protege !='true' && record.data.regne == fff){includeRecord=true;}
                    else if (patri =='true' && protege =='true'){if((record.data.patrimonial==true && record.data.protection_stricte == true) && record.data.regne == fff) {includeRecord=true;}}
                    else if (patri =='true' && protege !='true'){if(record.data.patrimonial==true && record.data.regne == fff){includeRecord=true;}}
                    else if (patri !='true' && protege =='true'){if(record.data.protection_stricte == true && record.data.regne == fff){includeRecord=true;}}
                }
                if(node){
                    if (!includeRecord) {node.getUI().hide();}
                    else {node.getUI().show();}
                }
            });
            Ext.each(t.getChecked(), function(node) {
                if(node.leaf && !node.hidden){
                    compt++;
                    ids.push(parseInt(node.id));
                }
            });
            Ext.getCmp('tree-taxons').getRootNode().setText(txtTaxons + '('+compt+')');
            if(compt>0){Ext.getCmp('label-choix-taxons').setText(compt+' taxon(s) sélectionné(s)');}
            else{Ext.getCmp('label-choix-taxons').setText('');}
            Ext.getCmp('search-form').getForm().findField('idstaxons').setValue(ids);

             //Si on a deja appliqué un mask, on ne le refait pas
            if(masked !== true){
              Ext.getCmp('label-patience-tree').setText('Vous pouvez choisir par espèce ou par groupe d\'espèces');
              treeMask.hide();
            }

        }
        ,manageCombosTaxons: function(){
            //récupération des valeurs des cases à cocher patrimoniaux et protégés et faune/flore/fonge
            var patri = Ext.getCmp('cb-patri').getValue();
            var protege = Ext.getCmp('cb-protege').getValue()
            var fff = Ext.getCmp('radio-fff').getValue().inputValue;
            Ext.getCmp('combo-synthese-taxons-fr').getStore().clearFilter();
            Ext.getCmp('combo-synthese-taxons-latin').getStore().clearFilter();
            Ext.getCmp('combo-synthese-taxons-fr').clearValue();
            Ext.getCmp('combo-synthese-taxons-latin').clearValue();
            myProxyTaxonsSyntheseFr.url = 'bibs/taxonssynthesefr/'+fff+'/'+patri+'/'+protege
            myProxyTaxonsSyntheseLatin.url = 'bibs/taxonssyntheselatin/'+fff+'/'+patri+'/'+protege
            Ext.getCmp('combo-synthese-taxons-fr').getStore().reload();
            Ext.getCmp('combo-synthese-taxons-latin').getStore().reload();
        }
        ,resetTree: function(){
            Ext.getCmp('tree-taxons').getRootNode().setText('Taxons (0)');
            Ext.each(Ext.getCmp('tree-taxons').getRootNode(), function(node){
                var args=[false];
                node.cascade(function(){
                    this.ui.toggleCheck(args[0]);
                    this.attributes.checked=args[0];
                    this.collapse();
                },null,args);
            });
            Ext.getCmp('tree-taxons').getRootNode().setText('Taxons');
            Ext.getCmp('label-choix-taxons').setText('');
            Ext.getCmp('search-form').getForm().findField('idstaxons').setValue('');
            treeMask.hide();
        }
        ,zoomTo: function(extent) {
            extent = extent.split(',');
            var bounds = new OpenLayers.Bounds(extent[0], extent[1], extent[2], extent[3]);
            map.zoomToExtent(bounds);
        }
        ,refreshSynthese: function() {
            formSearcher.triggerSearch();
            // redraw the WMS layer (true to force the redraw)
            map.getLayersByName('overlay')[0].redraw(true);
        }
        ,triggerSearch : function() {
            return formSearcher.triggerSearch();
        }
        ,changeGridCss : function(){
            var f = vectorLayer.features;
            Ext.each(f,function(item,index){
                var id = item.data.id_synthese; 
                var regId = new RegExp ("^"+id+"$",'gi');
                var rec = store.getAt(store.find('id_synthese',regId));
                if(rec){
                    if(item.onScreen()){rec.set('onscreen','yes');}
                    else{rec.set('onscreen','');}
                }            
            });
            syntheseListGrid.getView().refresh();
        }
        ,exportXlsObs : function(){
            var ob = Ext.getCmp('textfield-observateur').getValue();
            var sd, ed, ep, sp = new Date();
            sd = Ext.getCmp('datedebut').getValue();
            ed = Ext.getCmp('datefin').getValue();
            sp = Ext.getCmp('periodedebut').getValue();
            ep = Ext.getCmp('periodefin').getValue();
            if(Ext.getCmp('periodedebut').getValue()=="Période debut"){sp = null;}
            if(Ext.getCmp('periodefin').getValue()=="Période fin"){ep = null;}
            var st = "no";
            if(Ext.getCmp('result_count').text=="les 50 dernières observations"){st = "yes";}
            var tfr = Ext.getCmp('combo-synthese-taxons-fr').getValue();
            var tl = Ext.getCmp('combo-synthese-taxons-latin').getValue();
            var fff = Ext.getCmp('radio-fff').getValue().inputValue;
            var ids = Ext.getCmp('search-form').getForm().findField('idstaxons').getValue();
            var p = Ext.getCmp('hidden-patri').getValue();
            var pr = Ext.getCmp('hidden-protege').getValue();
            var c = Ext.getCmp('hidden-commune').getValue();
            var s = Ext.getCmp('hidden-secteur').getValue();
            var r = Ext.getCmp('combo-reserves').getValue();
            var n = Ext.getCmp('combo-n2000').getValue();
            var prog = Ext.getCmp('hidden-programmes').getValue();
            var geom = Ext.getCmp('hidden-geom').getValue();
            var ido = application.synthese.user.id_organisme;
            var idu = application.synthese.user.id_secteur;
            var userName = application.synthese.user.userNom+' '+application.synthese.user.userPrenom;
            var monUrl = 'synthese/xlsobs?usage='+usage+'&observateur='+ob+'&insee='+c+'&id_reserve='+r+'&id_n2000='+n+'&id_secteur='+s+'&patrimonial='+p+'&protection_stricte='+pr+'&searchgeom='+geom+'&datedebut='+sd+'&datefin='+ed+'&periodedebut='+sp+'&periodefin='+ep+'&start='+st+'&taxonfr='+tfr+'&taxonl='+tl+'&fff='+fff+'&idstaxons='+ids+'&programmes='+prog+'&id_organisme='+ido+'&id_unite='+idu+'&userName='+userName;
            Ext.getBody().mask("Géneration du fichier Excel des observations …");
            //FileDownloader.load renvoie une promise
            var p = FileDownloader.load({
                url : monUrl,
                format : 'xls',
                filename : 'synthese_observations_' + ((new Date()).format('Y_m_d_His'))
            });
            p.then(function() {
                Ext.getBody().unmask();
            });
            p['catch'](function(e) {
                Ext.getBody().unmask();
                Ext.Msg.alert('Erreur', e);
            });
        }
        ,exportXlsStatuts : function(){
            var ob = Ext.getCmp('textfield-observateur').getValue();
            var sd, ed, ep, sp = new Date();
            sd = Ext.getCmp('datedebut').getValue();
            ed = Ext.getCmp('datefin').getValue();
            sp = Ext.getCmp('periodedebut').getValue();
            ep = Ext.getCmp('periodefin').getValue();
            if(Ext.getCmp('periodedebut').getValue()=="Période debut"){sp = null;}
            if(Ext.getCmp('periodefin').getValue()=="Période fin"){ep = null;}
            var st = "no";
            if(Ext.getCmp('result_count').text=="les 50 dernières observations"){st = "yes";}
            var tfr = Ext.getCmp('combo-synthese-taxons-fr').getValue();
            var tl = Ext.getCmp('combo-synthese-taxons-latin').getValue();
            var fff = Ext.getCmp('radio-fff').getValue().inputValue;
            var ids = Ext.getCmp('search-form').getForm().findField('idstaxons').getValue();
            var p = Ext.getCmp('hidden-patri').getValue();
            var pr = Ext.getCmp('hidden-protege').getValue();
            var c = Ext.getCmp('hidden-commune').getValue();
            var s = Ext.getCmp('hidden-secteur').getValue();
            var r = Ext.getCmp('combo-reserves').getValue();
            var n = Ext.getCmp('combo-n2000').getValue();
            var prog = Ext.getCmp('hidden-programmes').getValue();
            var geom = Ext.getCmp('hidden-geom').getValue();
            var ido = application.synthese.user.id_organisme;
            var idu = application.synthese.user.id_secteur;
            var userName = application.synthese.user.userNom+' '+application.synthese.user.userPrenom;
            var monUrl = 'synthese/xlsstatus?usage='+usage+'&observateur='+ob+'&insee='+c+'&id_reserve='+r+'&id_n2000='+n+'&id_secteur='+s+'&patrimonial='+p+'&protection_stricte='+pr+'&searchgeom='+geom+'&datedebut='+sd+'&datefin='+ed+'&periodedebut='+sp+'&periodefin='+ep+'&start='+st+'&taxonfr='+tfr+'&taxonl='+tl+'&fff='+fff+'&idstaxons='+ids+'&programmes='+prog+'&id_organisme='+ido+'&id_unite='+idu+'&userName='+userName;
            Ext.getBody().mask("Géneration du fichier Excel des statuts juridiques …");
            //FileDownloader.load renvoie une promise
            var p = FileDownloader.load({
                url : monUrl,
                format : 'xls',
                filename : 'synthese_statuts_' + ((new Date()).format('d_m_Y_His'))
            });
            p.then(function() {
                Ext.getBody().unmask();
            });
            p['catch'](function(e) {
                Ext.getBody().unmask();
                Ext.Msg.alert('Erreur', e);
            });
            // window.location.href = 'synthese/xlsstatus?usage='+usage+'&observateur='+ob+'&insee='+c+'&id_reserve='+r+'&id_n2000='+n+'&id_secteur='+s+'&patrimonial='+p+'&protection_stricte='+pr+'&searchgeom='+geom+'&datedebut='+sd+'&datefin='+ed+'&periodedebut='+sp+'&periodefin='+ep+'&start='+st+'&taxonfr='+tfr+'&taxonl='+tl+'&fff='+fff+'&idstaxons='+ids+'&programmes='+prog+'&id_organisme='+ido+'&id_unite='+idu+'&userName='+userName;
        }
        ,exportShp : function(){
            var ob = Ext.getCmp('textfield-observateur').getValue();
            var sd, ed, ep, sp = new Date();
            sd = Ext.getCmp('datedebut').getValue();
            ed = Ext.getCmp('datefin').getValue();
            sp = Ext.getCmp('periodedebut').getValue();
            ep = Ext.getCmp('periodefin').getValue();
            if(Ext.getCmp('periodedebut').getValue()=="Période debut"){sp = null;}
            if(Ext.getCmp('periodefin').getValue()=="Période fin"){ep = null;}
            var st = "no";
            if(Ext.getCmp('result_count').text=="les 50 dernières observations"){st = "yes";}
            var tfr = Ext.getCmp('combo-synthese-taxons-fr').getValue();
            var tl = Ext.getCmp('combo-synthese-taxons-latin').getValue();
            var fff = Ext.getCmp('radio-fff').getValue().inputValue;
            var ids = Ext.getCmp('search-form').getForm().findField('idstaxons').getValue();
            var p = Ext.getCmp('hidden-patri').getValue();
            var pr = Ext.getCmp('hidden-protege').getValue();
            var c = Ext.getCmp('hidden-commune').getValue();
            var s = Ext.getCmp('hidden-secteur').getValue();
            var r = Ext.getCmp('combo-reserves').getValue();
            var n = Ext.getCmp('combo-n2000').getValue();
            var prog = Ext.getCmp('hidden-programmes').getValue();
            var geom = Ext.getCmp('hidden-geom').getValue();
            var ido = application.synthese.user.id_organisme;
            var idu = application.synthese.user.id_secteur;
            var userName = application.synthese.user.userNom+' '+application.synthese.user.userPrenom;
            var monUrl = 'synthese/shp?usage='+usage+'&observateur='+ob+'&insee='+c+'&id_reserve='+r+'&id_n2000='+n+'&id_secteur='+s+'&patrimonial='+p+'&protection_stricte='+pr+'&searchgeom='+geom+'&datedebut='+sd+'&datefin='+ed+'&periodedebut='+sp+'&periodefin='+ep+'&start='+st+'&taxonfr='+tfr+'&taxonl='+tl+'&fff='+fff+'&idstaxons='+ids+'&programmes='+prog+'&id_organisme='+ido+'&id_unite='+idu+'&userName='+userName;
            Ext.getBody().mask("Géneration des fichiers shape (compressés) des observations …");
            //FileDownloader.load renvoie une promise
            var p = FileDownloader.load({
                url : monUrl,
                format : 'zip',
                filename : 'synthese_' + ((new Date()).format('d_m_Y_His'))
            });
            p.then(function() {
                Ext.getBody().unmask();
            });
            p['catch'](function(e) {
                Ext.getBody().unmask();
                Ext.Msg.alert('Erreur', e);
            });
            // window.location.href = 'synthese/shp?usage='+usage+'&observateur='+ob+'&insee='+c+'&id_reserve='+r+'&id_n2000='+n+'&id_secteur='+s+'&patrimonial='+p+'&protection_tricte='+pr+'&searchgeom='+geom+'&datedebut='+sd+'&datefin='+ed+'&periodedebut='+sp+'&periodefin='+ep+'&start='+st+'&taxonfr='+tfr+'&taxonl='+tl+'&fff='+fff+'&idstaxons='+ids+'&programmes='+prog+'&id_organisme='+ido+'&id_unite='+idu+'&userName='+userName;
        }
        ,initWindowUploadShp : function() {
                this.windowUploadShp = initFormUploadShp();
                this.windowUploadShp.show();
                
        }
        ,deleteReleveCf: function(id, taxon) {
            var params = {};
            if (id) {params.id_releve_cf = id;}
            Ext.Ajax.request({
                url : 'cf/deletereleve'
                ,method: 'POST'
                ,params: params
                ,success: function (result, request) {
                    Ext.ux.Toast.msg('Suppression !', 'L\'observation de "'+taxon+'" a été supprimée.');
                    formSearcher.triggerSearch();
                }
                ,failure: function (result, request) { 
                    Ext.MessageBox.alert('Erreur lors de la suppression'); 
                } 
            });
        }
        ,deleteReleveInv: function(id, taxon) {
            var params = {};
            if (id) {params.id_releve_inv = id;}
            Ext.Ajax.request({
                url : 'invertebre/deletereleve'
                ,method: 'POST'
                ,params: params
                ,success: function (result, request) {
                    Ext.ux.Toast.msg('Suppression !', 'L\'observation de "'+taxon+'" a été supprimée.');
                    formSearcher.triggerSearch();
                }
                ,failure: function (result, request) { 
                    Ext.MessageBox.alert('Erreur lors de la suppression');
                } 
            });
        }
        ,deleteReleveCflore: function(id, taxon) {
            var params = {};
            if (id) {params.id_releve_cflore = id;}
            Ext.Ajax.request({
                url : 'cflore/deletereleve'
                ,method: 'POST'
                ,params: params
                ,success: function (result, request) {
                    Ext.ux.Toast.msg('Suppression !', 'L\'observation de "'+taxon+'" a été supprimée.');
                    formSearcher.triggerSearch();
                }
                ,failure: function (result, request) { 
                    Ext.MessageBox.alert('Erreur lors de la suppression'); 
                } 
            });
        }
        ,addGml: function() {
            this.initWindowUploadShp();
        }
        /**
         * Method: addGmlFeatures
         * Add features to searchVectorLayer from gml layer from a shape upload to the server in a zip file
         * the server transform the shapefile to gml file with OGR2OGR
         * use : addGmlFeatures();
         * Return
         * <OpenLayers.Layer.Vector>
         */  
        ,addGmlFeatures: function() {
            // This will enable us to autozoom the map to the displayed data.
			var dataExtent;
			var setExtent = function(){
				if(dataExtent){dataExtent.extend(this.getDataExtent());}
				else{dataExtent = this.getDataExtent();}
				map.zoomToExtent(dataExtent);
			};
            //identification de l'utilisateur dans le nom du gml
            var reg=new RegExp("( )", "g");
            var gmlFile = application.synthese.user.nom.replace(reg,"_");
            Ext.Ajax.request({
                url : "uploads/shapes/"+gmlFile+"_"+randomnumber+".gml"  
                ,method: 'GET',
                success: function (result, request) {
                    var featurecollection= result.responseText;
                    var gml_format = new OpenLayers.Format.GML({
                        externalProjection : import_shp_projection
                        ,internalProjection : new OpenLayers.Projection("EPSG:3857")
                    });
                    application.synthese.searchVectorLayer.addFeatures(gml_format.read(featurecollection));
                },
                failure: function (result, request) { 
                    Ext.MessageBox.alert('Erreur'); 
                } 
            });
        }
        ,addGml: function() {
            this.initWindowUploadShp();
            
        }
        /**
         * Method: createGmlLayer
         * Creates the vector gml layer from a shape upload to the server in a zip file
         * the server transform the shapefile to gml file with OGR2OGR
         * use : createGmlLayer();
         * Return
         * <OpenLayers.Layer.Vector>
         */
        ,createGmlLayer: function() {
            if(map.getLayersByName('gml')[0]){
                selcontrol.deactivate();
                map.getLayersByName('gml')[0].destroy();
            }
            var styleMap = new OpenLayers.StyleMap({
                'default': {
                    fillColor: "gray"
                    ,strokeColor: "yellow"
                    ,cursor: "pointer"
                    ,fillOpacity: 0.5
                    ,strokeOpacity: 0.75
                    ,strokeWidth: 2
                    ,pointRadius: 7
                }
                ,select : {
                    fillColor: "blue"
                    ,strokeColor: "blue"
                    ,cursor: "pointer"
                    ,fillOpacity: 0.6
                    ,strokeOpacity: 1
                    ,strokeWidth: 2
                    ,pointRadius: 7
                }
            });
            // This will enable us to autozoom the map to the displayed data.
			var dataExtent;
			var setExtent = function(){
				if(dataExtent){dataExtent.extend(this.getDataExtent());}
				else{dataExtent = this.getDataExtent();}
				map.zoomToExtent(dataExtent);
			};
            //identification de l'utilisateur dans le nom du gpx
            var reg=new RegExp("( )", "g");
            var gmlFile = application.synthese.user.nom.replace(reg,"_");
            vectorGmlLayer = new OpenLayers.Layer.Vector("gml",{
                protocol: new OpenLayers.Protocol.HTTP({
                    url: host_uri+"/"+app_uri+"/uploads/shapes/"+gmlFile+"_"+randomnumber+".gml"
                    ,format: new OpenLayers.Format.GML()
                })
                ,strategies: [new OpenLayers.Strategy.Fixed()]
                ,styleMap: styleMap
                ,projection: import_shp_projection      
            });
            // This will perform the autozoom as soon as the GPX file is loaded.
            vectorGmlLayer.events.register("loadend", vectorGmlLayer, setExtent);
            map.addLayer(vectorGmlLayer);
 
            // This feature connects the click events to the functions defined above, such that they are invoked when the user clicks on the map.
            selcontrol = new OpenLayers.Control.SelectFeature(vectorGmlLayer, {});
            map.addControl(selcontrol);
            selcontrol.activate();
        }
    };
}();
