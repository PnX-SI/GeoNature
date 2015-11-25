/**
 * @class application.search
 * Singleton to build the search panel (tab)
 *
 * @singleton
 */

application.search = function() {
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
     * Property: store
     * {Ext.data.Store} The search result store.
     */
    var store = null;

    /**
     * Property: StationListGrid
     * {Ext.grid.GriPanel}
     */
    var StationListGrid = null;

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
    var mapBoundsSearch = false;
	var nbFeatures = null;
    var gridMask = null;

    /**
     * Property: communeStore
     * {Ext.data.JsonStore}
     */


    // private functions

    /**
     * Method: createProtocol
     * Create the search protocol.
     */
    var createProtocol = function() {
        protocol = new mapfish.Protocol.MapFish({'url': 'bryo/get'});
        filterProtocol = new mapfish.Protocol.MergeFilterDecorator({
            protocol: protocol
        });
        eventProtocol = new mapfish.Protocol.TriggerEventDecorator({
            protocol: filterProtocol
            ,eventListeners: {
                crudtriggered: function() {
                    StationListGrid.loadMask.show();
                }
                ,crudfinished: function(response) {
                    if(response.features!=null){
                        nbFeatures = null;
                        //cas ou il n'y a pas de réponse
                        if (response.features.length == 0) {
                            store.removeAll();
                            StationListGrid.loadMask.hide();
                            Ext.getCmp('station_count').setText("Aucune station ne correspond à la recherche.");
                            Ext.getCmp('station_count').addClass('redtext');
                            Ext.getCmp('station_count').removeClass('bluetext');
                        }
                        else{
                            //cas où il y a trop de réponse, la requête retourne la feature contenant une géometry null voir lib/sfRessourcesActions
                            if (response.features[0].geometry == null ) {
                                nbFeatures = 'trop';
                            }
                        }
                    }
                    else{application.checklog();}
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
            storeId:'store-station-search'
            ,reader: new mapfish.widgets.data.FeatureReader({}, [
                {name: 'id_station'}
                ,{name: 'commune'}
                ,{name: 'nom_support'}
                ,{name:'dateobs', type: 'date', xtype: 'datecolumn', dateFormat:'Y-m-d'}
                ,{name:'date_insert', type: 'date', xtype: 'datecolumn', dateFormat:'d/m/Y'}
                ,{name:'date_update', type: 'date', xtype: 'datecolumn', dateFormat:'d/m/Y'}
                ,{name: 'nb_obs', type: 'float'}
                ,{name: 'nb_taxons', type: 'float'}
                ,{name: 'releve'}
                ,{name: 'onscreen',type: 'string',defaultValue:'yes'}
            ])
            ,listeners: {
                load: function(store, records) {
                    //on test si on est sur la recherche par défaut de la première page
                    if(Ext.getCmp('hidden-start').getValue()=='no'){
                        var count = store.getTotalCount();
                        //on test s'il y a trop de features ou pas
                        if (nbFeatures =='trop'){
                            store.removeAll();
                            StationListGrid.loadMask.hide();
                            Ext.getCmp('station_count').setText("Il y a trop de réponses, précisez votre recherche.");
                            Ext.getCmp('station_count').addClass('redtext');
                            Ext.getCmp('station_count').removeClass('bluetext');
                        }
                        else{
                            Ext.getCmp('station_count').setText(count + " station(s)");
                            Ext.getCmp('station_count').addClass('bluetext');
                            Ext.getCmp('station_count').removeClass('redtext');
                        }
                    }
                    else{
                        Ext.getCmp('hidden-start').setValue('no');
                        Ext.getCmp('station_count').addClass('bluetext');
                    }
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
     * Method: initPanel
     */
    var initPanel = function() {
        return  {
            title: 'Recherche'
            ,layout: 'border'
            ,iconCls: 'back_to_search'
            ,defaults: {
                //split: true
                border: false
            }
            ,items: [
                getViewportWestItem()
                ,getViewportNorthItem()
                ,getViewportCenterItem()
            ]
            ,listeners: {
                afterlayout: function() {
                    layerTreeTip = application.createLayerWindow(map);
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
                    panel.doLayout()
                    //action suivant les actions sur la carte
                    map.events.on({
                        move: function(e) { 
                            Ext.getCmp('hidden-zoom').setValue(map.zoom);
                            StationListGrid.getView().refresh();                            
                        }
                    });
                }
                ,scope: this
            }
        }
    };

    /**
     * Method: getViewportNorthItem
     */
    var getViewportNorthItem = function() {
        var formPanel = new Ext.form.FormPanel({
            region: 'north'
            ,xtype: 'formpanel'
            ,height:53
            ,bodyStyle:"background-color:#3fdbbc"
            ,split: false
            ,autoScroll:true
            ,layout:"column"
            ,defaults:{
                border:false
                ,bodyStyle:"padding: 3px;background-color:#3fdbbc"
                ,layout: 'form'
                ,labelAlign: 'top'
            }
            ,items: getFormColumns()
        });
        formSearcher = new mapfish.ux.Searcher.Form.Ext({
            store: store
            ,protocol: eventProtocol
            ,form: formPanel.getForm()
        });
        filterProtocol.register(formSearcher);
        return formPanel;
    };

    /**
     * Method: getViewportWestItem
     * builds the config for the stations list grid
     */
    var getViewportWestItem = function() {
        createStore();
        createMediator();
        var rowActions = new Ext.ux.grid.RowActions({
            actions: [{
                iconCls: 'action-recenter',
                tooltip: 'Recentrer la carte sur la station'
            }]
            ,listeners: {
                action: function (grid, record, action) {
                    switch (action) {
                        case 'action-recenter':
                            //on limit le zoom à 15
                            var zoomLevel = map.getZoomForExtent(record.data.feature.geometry.getBounds());
                            var centerGeom = record.data.feature.geometry.getBounds().getCenterLonLat();
                            if (zoomLevel > 15){zoomLevel = 15;}
                            map.setCenter(centerGeom,zoomLevel);
                            break;
                    }
                }
            },
            fixed: true
            ,autoWidth: false
            ,width: 25
        });
        var rowActions3 = new Ext.ux.grid.RowActions({
            actions: [{
                tooltip: 'Afficher le détail de la station',
                iconCls: 'action-detail'
            }]
            ,listeners: {
                action: function (grid, record, action) {
                    switch (action) {
                        case 'action-detail':
                            application.layout.loadStation(record.data);
                            break;
                    }
                }
            }
            ,fixed: true
            ,autoWidth: false
            ,width: 25
        });
        
        toolbarItems =  new Ext.Toolbar({items:[]});
        if(application.user.statuscode >= 2){
            var addStationButton = new Ext.Button({
                iconCls: 'add'
                ,text: 'Nouvelle station'
                ,disabled: false
                ,handler: function() {
                    application.editStation.loadStation(null,'add');
                }
                ,scope: this
            });
            toolbarItems.add(addStationButton);
        }
         toolbarItems.add('->');
         toolbarItems.add({xtype: 'label',id: 'station_count',text:'les 50 dernières stations'});

        var columns = [
            rowActions3
            ,{header: "Id",  width: 50, sortable: true, dataIndex: 'id_station'}
            ,{header: "Date",  width: 75, sortable: true, dataIndex: 'dateobs',renderer: Ext.util.Format.dateRenderer('d/m/Y')}
            ,{header: "Inséré",  width: 75, sortable: true, dataIndex: 'date_insert',renderer: Ext.util.Format.dateRenderer('d/m/Y'),hidden: true}
            ,{header: "Modifié",  width: 75, sortable: true, dataIndex: 'date_update',renderer: Ext.util.Format.dateRenderer('d/m/Y'),hidden: true}
            ,{header: "Nb_obs", width: 45, sortable: true, dataIndex: 'nb_obs',hidden: true}
            ,{header: "Nb_Taxons", width: 60, sortable: true, dataIndex: 'nb_taxons'}
            ,{header: "Relevé", width: 45, sortable: true, dataIndex: 'releve'}
            ,{header: "Support", width: 100, sortable: true, dataIndex: 'nom_support',hidden: true}
            ,{header: "Commune", width: 45, sortable: true, dataIndex: 'commune',hidden: true}
        ];
        var actions = [rowActions, rowActions3];
        columns.push(rowActions);

        StationListGrid = new Ext.grid.GridPanel({
            region:"west"
            ,id: 'station_list_grid'
            ,xtype: 'grid'
            ,width:500
            ,split: true
            ,store: store
            ,loadMask: true
            ,columns:columns
            ,plugins: actions
            ,sm: new Ext.grid.RowSelectionModel({singleSelect:true})
            ,viewConfig: new Ext.ux.grid.BufferView({
                emptyText:'<span class="pInfo" >Aucune donnée ne peut être affichée. Voir message ci-dessus.</span>'
                ,forceFit:true
                //Return CSS class to apply to rows depending upon data values
                ,getRowClass: function(r, index,rp,ds) {
                    //pour éviter un bug quand il y a trop de réponses, on doit tester s'il y a bien des données
                    if(r.data.id_station){
                        var s;
                        if(vectorLayer.getFeatureByFid(r.data.id_station)){s = vectorLayer.getFeatureByFid(r.data.id_station).onScreen();}
                        else{s = r.get('onscreen');}
                        if (s) {return '';}
                        return 'grey';
                    }
                }
            })
            ,stripeRows: true
            ,tbar: toolbarItems
            ,listeners:{
                rowdblclick:function(grid,rowIndex){
                    var record = grid.getStore().getAt(rowIndex);
                    if(record){
                        application.layout.loadStation(record.data);
                    }
                }
            }
        });
        return StationListGrid;		
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
        map.zoomToExtent(bounds);
    };

    /**
     * Method: getViewportCenterItem
     */
    var getViewportCenterItem = function() {
        application.search.createMap();
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
            ,tbar: toolbar
        }
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
                    iconCls: 'zoomfull'
                    ,toggleGroup: this.id
                    ,handler: function() {
                        application.search.selectControl.activate();
                        Ext.getCmp('combo-bryo-secteur').clearValue();
                        Ext.getCmp('combo-bryo-commune').clearValue();
                    }
                }
            );

            application.utils.addSeparator(toolbar);

            var history = new OpenLayers.Control.NavigationHistory();
            map.addControl(history);
            toolbar.addControl(history.previous, {
                iconCls: 'previous'
                ,toggleGroup: 'navigation'
                ,tooltip: 'Etendue précédente'
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
                    iconCls: 'pan'
                    ,toggleGroup: this.id
                    ,handler: function() {
                        application.search.selectControl.activate();
                    }   
                }
            );

            application.utils.addSeparator(toolbar);
            toolbar.addControl(
                drawPolygonControl = new OpenLayers.Control.DrawFeature(application.searchVectorLayer, OpenLayers.Handler.Polygon, {
                    title: 'Dessiner une zone de recherche'
                }), {
                    iconCls: 'drawpolygon'
                    ,toggleGroup: this.id
                    ,handler: function(){
                        application.searchVectorLayer.events.on({
                            "featureadded":function(feature){
                                if(mapBoundsSearch==true){
                                    application.searchVectorLayer.removeFeatures(application.searchVectorLayer.features[0]);
                                    mapBoundsSearch=false;
                                }
                                if(application.searchVectorLayer.features.length>1){
                                    Ext.Msg.confirm('Definir une autre zone de recherche ?'
                                        ,'Voulez vous supprimer la zone de recherche précédente ?'
                                        ,function(btn) {
                                            if (btn == 'yes') {
                                                Ext.getCmp('hidden-geom').setValue(null);
                                                application.searchVectorLayer.removeFeatures(application.searchVectorLayer.features[0]);
                                            }
                                            else{application.searchVectorLayer.removeFeatures(application.searchVectorLayer.features[1]);}
                                        }
                                    );
                                }
                                
                            }
                        });
                        Ext.getCmp('combo-bryo-commune').clearValue();
                        Ext.getCmp('combo-bryo-secteur').clearValue();
                    }
                }
            );

            toolbar.addControl(
              modifyFeatureControl = new OpenLayers.Control.ModifyFeature(application.searchVectorLayer, {
                title: 'Modifier la zone de recherche'
              }), {
                iconCls: 'modifyfeature'
                ,toggleGroup: this.id
              }
            );
            toolbar.add({
                id: 'station-geometry-erase'
                ,iconCls: 'erase'
                ,tooltip: 'Supprimer la zone de recherche'
                ,handler: function() {
                    Ext.Msg.confirm('Attention'
                        ,'Cela supprimera définitivement la zone de recherche que vous avez dessinée !<br />Confirmer ?'
                        ,function(btn) {
                            if (btn == 'yes') {
                                Ext.getCmp('hidden-geom').setValue(null);
                                application.searchVectorLayer.removeFeatures(application.searchVectorLayer.features[0]);
                                formSearcher.triggerSearch();
                            }
                        }
                    )
                }
            });
            
            application.utils.addSeparator(toolbar);
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
            
            toolbar.add({
                xtype:"twintriggercombo"
                ,id: 'combo-bryo-secteur'
                ,fieldLabel:"Secteur"
                ,emptyText: "Secteur"
                ,name:"nomsecteur"
                ,hiddenName:"secteur"
                ,store: application.secteurStore
                ,valueField: "id_secteur"
                ,displayField: "nom_secteur"
                ,typeAhead: true
                ,width: 150
                ,forceSelection: true
                ,selectOnFocus: true
                ,editable: false
                ,mode: 'local'
                ,triggerAction: 'all'
                // ,trigger1Class: 'x-form-clear-trigger always-hidden'
                ,trigger3Class: 'x-hidden'
                ,listeners: {
                    beforeselect: function(combo, record) {
                        if (application.searchVectorLayer.features.length>0 && mapBoundsSearch==false) {
                            Ext.Msg.confirm('Vous aviez défini une zone de recherche.'
                                ,'Voulez vous supprimer cette zone de recherche ?'
                                ,function(btn) {
                                    if (btn == 'yes') {
                                        Ext.getCmp('hidden-geom').setValue(null);
                                        application.searchVectorLayer.removeAllFeatures();
                                        return true;
                                    }
                                    combo.clearValue();
                                    return false;
                                }
                            );
                        } 
                    }
                    ,select: function(combo, record) {
                        Ext.getCmp('combo-bryo-commune').clearValue();
                        if(Ext.getCmp('ra-combo-bryo-secteur')){Ext.getCmp('ra-combo-bryo-secteur').clearValue();}
                        if(Ext.getCmp('ra-combo-commune')){Ext.getCmp('ra-combo-commune').clearValue();}
                        Ext.getCmp('hidden-extent').setValue(record.data.extent);
                        myProxyCommunes.url = 'bibs/communes?secteur='+combo.getValue();
                        communeStore.reload();
                        // combo.triggers[2].removeClass('x-hidden');
                        zoomToRecord(record);
                    }
                    ,clear: function(combo) {
                        // combo.triggers[2].addClass('x-hidden');
                        if(Ext.getCmp('ra-combo-bryo-secteur')){Ext.getCmp('ra-combo-bryo-secteur').clearValue();}
                        if(Ext.getCmp('ra-combo-commune')){Ext.getCmp('ra-combo-commune').clearValue();}
                        myProxyCommunes.url = 'bibs/communes'
                        communeStore.reload();
                        Ext.getCmp('hidden-extent').setValue('');
                    }
                    ,trigger3Click: function(combo) {
                        var index = combo.view.getSelectedIndexes()[0];
                        var record = combo.store.getAt(index);
                        zoomToRecord(record);
                    }
                }
            });
            var myProxyCommunes = new Ext.data.HttpProxy({
                id:'store-communes-proxy'
                ,url: 'bibs/communes'
                ,method: 'GET'
            });
            var communeStore= new Ext.data.JsonStore({
                url: myProxyCommunes
                // url:'bibs/communes'
                ,sortInfo: {
                    field: 'nomcommune'
                    ,direction: 'ASC'
                }
                ,fields: [
                    'insee'
                    ,'nomcommune'
                    ,'extent'
                ]
                ,autoLoad: true
            })
            toolbar.add({
                xtype:"twintriggercombo"
                ,id: 'combo-bryo-commune'
                ,fieldLabel:"Commune"
                ,emptyText: "Commune"
                ,name:"nomcommune"
                ,hiddenName:"commune"
                ,store: communeStore
                ,valueField: "insee"
                ,displayField: "nomcommune"
                ,typeAhead: true
                ,forceSelection: true
                ,selectOnFocus: true
                ,mode: 'local'
                ,triggerAction: 'all'
                // keep the clear button never displayed
                // ,trigger1Class: 'x-form-clear-trigger always-hidden'
                ,trigger3Class: 'x-hidden'
                ,listeners: {
                    beforeselect: function(combo, record) {
                        if (application.searchVectorLayer.features.length>0 && mapBoundsSearch==false) {
                            Ext.Msg.confirm('Vous aviez défini une zone de recherche.'
                                ,'Voulez vous supprimer cette zone de recherche ?'
                                ,function(btn) {
                                    if (btn == 'yes') {
                                        Ext.getCmp('hidden-geom').setValue(null);
                                        application.searchVectorLayer.removeAllFeatures();
                                        return true;
                                    }
                                    combo.clearValue();
                                    return false;
                                }
                            );
                        } 
                    }
                    ,select: function(combo, record) {
                        // combo.triggers[2].removeClass('x-hidden');
                        if(Ext.getCmp('ra-combo-commune')){Ext.getCmp('ra-combo-commune').clearValue();}
                        zoomToRecord(record);
                    }
                    ,clear: function(combo) {
                        if(Ext.getCmp('ra-combo-commune')){Ext.getCmp('ra-combo-commune').clearValue();}
                        // combo.triggers[2].addClass('x-hidden');
                    }
                    ,trigger3Click: function(combo) {
                        var index = combo.view.getSelectedIndexes()[0];
                        var record = combo.store.getAt(index);
                        zoomToRecord(record)
                    }
                }
            });
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
     * Method: getFormColumns
     */
    var getFormColumns = function() {
        var columns = [{
                items:[{
                    xtype:"twintriggercombo"
                    ,id:'combo-bryo-annee'
                    ,fieldLabel:"Année"
                    ,name:"annee"
                    ,hiddenName:"annee"
                    ,store: application.anneeStore
                    ,valueField: "annee"
                    ,displayField: "annee"
                    ,typeAhead: true
                    ,forceSelection: true
                    ,selectOnFocus: true
                    //,editable: true
                    ,listWidth: 80
                    ,width:100
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                    /*,listeners: {
                        select: function(combo, record) {
                            formSearcher.triggerSearch();
                        }
                        ,clear: function() {
                            formSearcher.triggerSearch();
                        }
                    }*/
                },{
                    xtype:'hidden'
                    ,id:'hidden-id-station'
                    ,name:'by_id_station'
                    ,value:''
                },{
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
                    ,id:'hidden-geom'
                    ,name:'geom'
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
                    xtype:'hidden'
                    ,id:'hidden-otaxon'
                    ,name:'otaxon'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-exposition'
                    ,name:'exposition'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-releve'
                    ,name:'releve'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-startdate'
                    ,name:'startdate'
                    ,value:''
                    ,format: 'd/m/Y'
                    ,altFormats:'Y/m/d'
                },{
                    xtype:'hidden'
                    ,id:'hidden-enddate'
                    ,name:'enddate'
                    ,value:''
                    ,format: 'd/m/Y'
                    ,altFormats:'Y/m/d'
                },{
                    xtype:'hidden'
                    ,id:'hidden-typeperiode'
                    ,name:'typeperiode'
                    ,value:'aa'
                }]
            },{
                items:[{
                    xtype:"twintriggercombo"
                    ,id:'combo-bryo-observateur'
                    ,fieldLabel:"Observateur"
                    ,name:"observateur"
                    ,hiddenName:"id_role"
                    ,store: application.auteursStoreBryo
                    ,valueField: "id_role"
                    ,displayField: "auteur"
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,listWidth: 230
                    ,width:190
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                    /*,listeners: {
                        select: function(combo, record) {
                            formSearcher.triggerSearch();
                        }
                        ,clear: function() {
                            formSearcher.triggerSearch();
                        }
                    }*/
                }]
            },{
                items:[{
                    xtype:"twintriggercombo"
                    ,id:'combo-bryo-rtaxon'
                    ,fieldLabel:"Taxons"
                    ,name:"rtaxon"
                    ,hiddenName:"rcd_nom"
                    ,store: application.filtreTaxonsOrigineStore
                    ,valueField: "cd_nom"
                    ,displayField: "lb_nom"
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,resizable: true
                    ,listWidth: 230
                    ,width:220
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                    /*,listeners: {
                        select: function(combo, record) {
                            formSearcher.triggerSearch();
                        }
                        ,clear: function() {
                            formSearcher.triggerSearch();
                        }
                    }*/
                }]
            }
            // ,{
                // items:[{
                    // xtype:"twintriggercombo"
                    // ,id: 'combo-bryo-secteurfp'
                    // ,fieldLabel:"Secteur"
                    // ,name:"secteurfp"
                    // ,hiddenName:"id_secteur_fp"
                    // ,store: application.secteurFpStore
                    // ,valueField: "id_secteur_fp"
                    // ,displayField: "nom_secteur_fp"
                    // ,typeAhead: true
                    // ,forceSelection: true
                    // ,selectOnFocus: true
                    // ,editable: true
                    // ,listWidth: 130
                    // ,width: 150
                    // ,triggerAction: 'all'
                    // ,mode: 'local'
                    // ,trigger3Class: 'x-hidden'
                // }]
            // }
        ];
        
        Ext.each(columns, function(column) {
            Ext.each(column.items, function(item) {
                item.listeners = (item.listeners || {});
                Ext.apply(item.listeners, {
                    specialkey: function(field, evt) {
                        if (Ext.EventObject.getKey(evt) == Ext.EventObject.ENTER) {
                            formSearcher.triggerSearch();
                        }
                    }
                });
            });
        });
        
        var isWhereParam = function(){
            var paramCommune = Ext.getCmp('combo-bryo-commune').getValue();
            var paramSecteur = Ext.getCmp('combo-bryo-secteur').getValue();
            if(paramCommune=="" && paramSecteur=="" && application.searchVectorLayer.features.length==0){return false;}
            return true;
        };
        columns.push({
            width: 250
            ,height: 50
            ,buttons: [{
                id:'btn-raz'
                ,text: "RAZ"
                ,handler: function() {
                    application.searchVectorLayer.removeFeatures(application.searchVectorLayer.features[0]);
                    Ext.getCmp('hidden-geom').setValue(null);
                    formSearcher.form.reset();
                    application.rechercheAvancee.formReset();
                    Ext.getCmp('combo-bryo-secteur').clearValue();
                    Ext.getCmp('combo-bryo-commune').clearValue();
                    map.zoomToMaxExtent();
                    mapBoundsSearch = false;
                    Ext.getCmp('station_count').setText("les 50 dernières stations");
                    formSearcher.triggerSearch();
                }
                ,listeners: {click: function(button, e) {Ext.getCmp('btn-avancee').removeClass('red-btn');}}
            },{
                id:'btn-rechercher'
                ,text: "Rechercher"
                ,iconCls: 'search'
                ,handler: function() {
                    // if(application.searchVectorLayer.features.length>0){
                        // Ext.getCmp('hidden-start').setValue('no');
                        // Ext.getCmp('hidden-geom').setValue(application.getFeatureWKT());
                    // }
                    if (isWhereParam()==false) {
                        Ext.getCmp('hidden-geom').setValue(application.getFeatureWKT(maMap.getExtent().toGeometry()));
                        mapBoundsSearch = true;
                    }
                    else{
                        if(application.searchVectorLayer.features.length>0){
                            Ext.getCmp('hidden-geom').setValue(application.getFeatureWKT(application.searchVectorLayer.features[0].geometry));
                        }
                        mapBoundsSearch = false;
                    }
                    formSearcher.triggerSearch();
                }
            },{
                id:'btn-avancee'
                ,text: "Avancée"
                ,handler: function() {
                    application.rechercheAvancee.loadRa();
                }
                ,listeners: {click: function(button, e) {button.addClass('red-btn');}}
            }]
        });
        
        var btXls = new Ext.Button({
            iconCls: 'xls'
            ,tooltip: 'Exporter vers Excel'
            ,handler: function() {
                var a = Ext.getCmp('combo-bryo-annee').getValue();
                var o = Ext.getCmp('combo-bryo-observateur').getValue();
                var to = Ext.getCmp('hidden-otaxon').getValue();
                var tr = Ext.getCmp('combo-bryo-rtaxon').getValue();
                var c = Ext.getCmp('hidden-commune').getValue();
                var se = Ext.getCmp('hidden-secteur').getValue();
                var e = Ext.getCmp('hidden-exposition').getValue();
                var r = Ext.getCmp('hidden-releve').getValue();
                var tp = Ext.getCmp('hidden-typeperiode').getValue();
                var sd, ed = new Date();
                var sd = Ext.getCmp('hidden-startdate').getValue();
                var ed = Ext.getCmp('hidden-enddate').getValue();
                var st = "no"
                if(Ext.getCmp('station_count').text=="les 50 dernières stations"){st = "yes"};
                var b = map.getExtent().toBBOX(); 
                if(usage=='demo'){Ext.ux.Toast.msg('Limitation', 'Pour la démo, l\'export est limité à 100 lignes.');}                
                window.location = 'bryo/xls?usage='+usage+'&annee='+a+'&observateur='+o+'&rtaxon='+tr+'&otaxon='+to+'&commune='+c+'&secteur='+se+'&exposition='+e+'&releve='+r+'&box='+b+'&typeperiode='+tp+'&startdate='+sd+'&enddate='+ed+'&start='+st;
            }
        });
        columns.push({
            width: 50
            ,height: 50
            ,items: btXls
        });
        return columns;
    };

    /**
     * Method: createLayer
     * Creates the vector layer
     *
     * Return
     * <OpenLayers.Layer.Vector>
     */
    var createLayer = function() {
        var stationDefaultStyle = new OpenLayers.Style({
            fillColor:'#FF9922',
            pointRadius: 5,
            strokeColor:'#f00',
            strokeWidth:2,
            fillOpacity:0.4,
            graphicZIndex:2,
        });

        var styleMap = new OpenLayers.StyleMap({
            'default':stationDefaultStyle
           ,'select': OpenLayers.Util.extend({display: ""},
                OpenLayers.Feature.Vector.style['select'])
        });

        vectorLayer = new OpenLayers.Layer.Vector("vector"
            ,{
                protocol: eventProtocol
                ,strategies: [
                    new mapfish.Strategy.ProtocolListener()
                ]
                ,format: OpenLayers.Format.GeoJSON
                ,styleMap: styleMap
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
    // var createMap = function() {
        // map = application.createMap();

        // var vector = createLayer();
        // map.addLayers([vector]);

        // this.selectControl = new OpenLayers.Control.SelectFeature([vector], {
            // multiple: false
        // });

        // var mediator = new mapfish.widgets.data.GridRowFeatureMediator({
            // grid: StationListGrid,
            // selectControl: this.selectControl
        // });

        // map.addControl(this.selectControl);
        // this.selectControl.activate();

        // map.zoomToMaxExtent();
    // };


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

    /**
     * Method: updateMap
     * Updates the map by adding/removing WMS layers in the overlay WMS layer (communes, coeur, etc...)
     */
    var updateMap = function() {
        var params = map.getLayersByName('overlay')[0].params;
        params["_salt"] = Math.random();

        var layers = [];
        overlayLayersStore.each(function(record) {
            if (record.data.visible) {
                layers.push(record.data.id);
            }
        });
        layers.sort();
        params['LAYERS'] = layers.join(',');

        map.getLayersByName('overlay')[0].mergeNewParams(params);
    };

    // public space
    return {
        init: function() {
            createProtocol();
            return initPanel();
        }
        ,createMap : function() {
            map = application.createMap();
            var vector = createLayer();
            map.addLayers([vector]);
            function createPopup(feature) {
                var dataDiv = '<div><span style="font-weight:bold;">';
                if(feature.attributes.id_station){
                    var maDate = Ext.util.Format.date(feature.data.dateobs,'d/m/Y');
                    dataDiv = dataDiv + 'Le ' + maDate + '</span><br/>';
                    dataDiv = dataDiv + 'Station N°' + feature.data.id_station+ '</span><br/>';
                    
                }
                if(feature.attributes.nb_taxons ==0){dataDiv = dataDiv + '<small>Aucun taxon</small>';}
                if(feature.attributes.nb_taxons ==1){dataDiv = dataDiv + '<small>1 taxon</small>';}
                if(feature.attributes.nb_taxons >1){dataDiv = dataDiv + '<small>' + feature.data.nb_taxons + ' taxons</small>';}
                dataDiv = dataDiv + '</div>';
                feature.popup = new OpenLayers.Popup("data",
                    feature.geometry.getBounds().getCenterLonLat(),
                    null,
                    dataDiv,
                    false
                );
                feature.popup.backgroundColor='#ccc';
                feature.popup.opacity=0.75;
                feature.popup.autoSize=true;
                map.addPopup(feature.popup);
            }
     
            // This function destroys the popup when the user clicks the X.
            function destroyPopup(feature) {
                if(feature.popup!=null){feature.popup.destroy();}
                feature.popup = null;
            }
            this.selectControl = new OpenLayers.Control.SelectFeature([vector], {
                multiple: false
                ,id:'vectorselect'
                ,onSelect: createPopup
                ,hover:true
                ,onUnselect: destroyPopup
            });
            var mediator = new mapfish.widgets.data.GridRowFeatureMediator({
                grid: StationListGrid,
                selectControl: this.selectControl
            });
            map.addControl(this.selectControl);
            this.selectControl.activate();
            map.zoomToMaxExtent();
        }
        ,zoomTo: function(extent) {
            //extent = extent.split(',');
            var bounds = new OpenLayers.Bounds(extent[0], extent[1], extent[2], extent[3]);
            map.zoomToExtent(bounds);
        }
        ,refreshStations: function() {
            formSearcher.triggerSearch();
            // redraw the WMS layer (true to force the redraw)
            map.getLayersByName('overlay')[0].redraw(true);
        }
        ,triggerSearch : function() {
            return formSearcher.triggerSearch();
        }
    }
}();
