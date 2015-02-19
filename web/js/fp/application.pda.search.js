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
     * Property: ZpListGrid
     * {Ext.grid.GriPanel}
     */
    var ZpListGrid = null;

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

	var nbFeatures = null;
    var gridMask = null;

    // private functions

    /**
     * Method: createProtocol
     * Create the search protocol.
     */
    var createProtocol = function() {
        protocol = new mapfish.Protocol.MapFish({'url': 'zp/get'});
        filterProtocol = new mapfish.Protocol.MergeFilterDecorator({
            protocol: protocol
        });
        eventProtocol = new mapfish.Protocol.TriggerEventDecorator({
            protocol: filterProtocol
            ,eventListeners: {
                crudtriggered: function() {
                    ZpListGrid.loadMask.show();
                }
                ,crudfinished: function(response) {
                    if(response.features!=null){
                        nbFeatures = null;
                        //cas ou il n'y a pas de réponse
                        if (response.features.length == 0) {
                            store.removeAll();
                            ZpListGrid.loadMask.hide();
                            Ext.getCmp('zp_count').setText("Aucune zone de prospection ne correspond à la recherche.");
                            Ext.getCmp('zp_count').addClass('redtext');
                            Ext.getCmp('zp_count').removeClass('bluetext');
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
            id:'store-zp-search'
            ,reader: new mapfish.widgets.data.FeatureReader({}, [
                {name: 'indexzp'}
                ,{name: 'taxon_francais'}
                ,{name: 'taxon_latin'}
                ,{name: 'objets_a_compter'}
                ,{name: 'observateurs'}
                ,{name:'dateobs', type: 'date', xtype: 'datecolumn', dateFormat:'d/m/Y'}
                ,{name:'date_insert', type: 'date', xtype: 'datecolumn', dateFormat:'d/m/Y'}
                ,{name:'date_update', type: 'date', xtype: 'datecolumn', dateFormat:'d/m/Y'}
                ,{name: 'nb_obs', type: 'float'}
                ,{name: 'nb_ap', type: 'float'}
                ,{name: 'statut'}
                ,{name: 'topo'}
                ,{name: 'validated'/*, defaultValue: false*/}
                ,{name: 'notvalidated'/*, defaultValue: false*/}
                ,{name: 'topovalidated'/*, defaultValue: false*/}
                ,{name: 'toponotvalidated'/*, defaultValue: false*/}
            ])
            ,listeners: {
                load: function(store, records) {
                    //on test si on est sur la recherche par défaut de la première page
                    if(Ext.getCmp('hidden-start').getValue()=='no'){
                        var count = store.getTotalCount();
                        //on test s'il y a trop de features ou pas
                        if (nbFeatures =='trop'){
                            store.removeAll();
                            ZpListGrid.loadMask.hide();
                            Ext.getCmp('zp_count').setText("Il y a trop de réponses, précisez votre recherche.");
                            Ext.getCmp('zp_count').addClass('redtext');
                            Ext.getCmp('zp_count').removeClass('bluetext');
                        }
                        else{
                            Ext.getCmp('zp_count').setText(count + " zone(s) de prospection");
                            Ext.getCmp('zp_count').addClass('bluetext');
                            Ext.getCmp('zp_count').removeClass('redtext');
                        }
                    }
                    else{
                        Ext.getCmp('hidden-start').setValue('no');
                        Ext.getCmp('zp_count').addClass('bluetext');
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
	/*var createGridMask = function() {
		gridMask = new Ext.LoadMask(Ext.getCmp('zp_list_grid').getEl(), {
			msg: "Faut bosser maintenant il a dit Cédric."
			,msgCls: 'pInfo'
		});
		return gridMask;
	};*/
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
                    map.events.on({
                        move:function() {
                            //alert(map.zoom);
                            Ext.getCmp('hidden-zoom').setValue(map.zoom);
                        }
                    });
                }
                ,activate: function(panel) {
                    panel.doLayout();
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
            ,bodyStyle:"background-color:#ffffce"
            ,split: false
            ,autoScroll:true
            ,layout:"column"
            ,defaults:{
                border:false
                ,bodyStyle:"padding: 3px;background-color:#ffffce"
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
     * builds the config for the zps list grid
     */
    var getViewportWestItem = function() {
        createStore();
        createMediator();
        var rowActions = new Ext.ux.grid.RowActions({
            actions: [{
                iconCls: 'action-recenter',
                tooltip: 'Recentrer la carte sur la zone de prospection'
            }]
            ,listeners: {
                action: function (grid, record, action) {
                    switch (action) {
                        case 'action-recenter':
                            //on limit le zoom à 9
                            var zoomLevel = map.getZoomForExtent(record.data.feature.geometry.getBounds());
                            var centerGeom = record.data.feature.geometry.getBounds().getCenterLonLat();
                            if (zoomLevel > 9){zoomLevel = 9;}
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
                tooltip: 'Afficher le détail de la zone de prospection',
                iconCls: 'action-detail'
            }]
            ,listeners: {
                action: function (grid, record, action) {
                    switch (action) {
                        case 'action-detail':
                            application.layout.loadZp(record);
                            break;
                    }
                }
            }
            ,fixed: true
            ,autoWidth: false
            ,width: 25
        });
        var relecture = new Ext.ux.grid.RowActions({
            actions: [{
                iconCls: 'notvalidated'
                ,tooltip: 'Zone de prospection non relue'
                ,hideIndex: 'validated'
            },{
                iconCls: 'validated'
                ,tooltip: 'Zone de prospection relue'
                ,hideIndex: 'notvalidated'
            }]
            ,listeners: {
                action: function (grid, record, action) {
                    switch (action) {
                        case 'notvalidated':
                            if(application.user.statuscode >= 3){Ext.Msg.alert('Information', 'Pour changer le statut de lecture d\'une zone de prospection tu dois l\'avoir lu... Donc ouvre l\'onglet de cette ZP et tu pourras changer son statut. ;-)');}
                            break;
                        case 'validated':
                            if(application.user.statuscode >= 3){Ext.Msg.alert('Information', 'Pour changer le statut de lecture d\'une zone de prospection tu dois l\'avoir lu... Donc ouvre l\'onglet de cette ZP et tu pourras changer son statut. ;-)');}
                            break;
                    }
                }
            }
            ,hideMode: 'display'
            ,header: 'Relue'
            ,fixed: true
            ,autoWidth: false
            ,width: 40
        }); 
        var topologie = new Ext.ux.grid.RowActions({
            actions: [{
                iconCls: 'notvalidated'
                ,tooltip: 'Topologie non valide'
                ,hideIndex: 'topovalidated'
            },{
                iconCls: 'validated'
                ,tooltip: 'Topologie valide'
                ,hideIndex: 'toponotvalidated'
            }]
            ,listeners: {
                action: function (grid, record, action) {
                    switch (action) {
                        case 'notvalidated':
                            Ext.Msg.alert('Information', 'Pour modifier la topologie, il faut modifier le polygone de la zone de prospection. Donc ouvre l\'onglet de cette ZP et tu pourras modifier le dessin de son contour.');
                            break;
                        case 'validated':
                            Ext.Msg.alert('Information', 'Pour modifier la topologie, il faut modifier le polygone de la zone de prospection. Donc ouvre l\'onglet de cette ZP et tu pourras modifier le dessin de son contour.');
                            break;
                    }
                }
            }
            ,hideMode: 'display'
            ,header: 'Topo'
            ,fixed: true
            ,autoWidth: false
            ,width: 35
        });        

        toolbarItems =  new Ext.Toolbar({items:[]});
        if(application.user.statuscode >= 2){
            var addZpButton = new Ext.Button({
                iconCls: 'add'
                ,text: 'Nouvelle prospection'
                ,disabled: false
                ,handler: function() {
                    application.editZp.loadZp(null,'add',map.getExtent());
                }
                ,scope: this
            });
            toolbarItems.add(addZpButton);
        }
         toolbarItems.add('->');
         toolbarItems.add({xtype: 'label',id: 'zp_count',text:'les 50 dernières prospections'});
		//toolbarItems.concat(['->',{   
            //,handleMouseEvents: false
        //}]);
        var columns = [
            rowActions3
            ,{header: "Index Zp",  sortable: true, dataIndex: 'indexzp',hidden: true}
            ,{header: "Observateurs",  sortable: true, dataIndex: 'observateurs',hidden: true}
            ,{id: 'taxon', header: "Taxon",  sortable: true, dataIndex: 'taxon_latin',hidden: false}
            ,{header: "Taxon français",  sortable: true, dataIndex: 'taxon_francais',hidden: true}
            ,{header: "Date",  width: 75, sortable: true, dataIndex: 'dateobs',renderer: Ext.util.Format.dateRenderer('d/m/Y'),hidden: false}
            ,{header: "Inséré",  width: 75, sortable: true, dataIndex: 'date_insert',renderer: Ext.util.Format.dateRenderer('d/m/Y'),hidden: true}
            ,{header: "Modifié",  width: 75, sortable: true, dataIndex: 'date_update',renderer: Ext.util.Format.dateRenderer('d/m/Y'),hidden: true}
            ,{header: "Nb Obs", width: 45, sortable: true, dataIndex: 'nb_obs'}
            ,{header: "Nb AP", width: 45, sortable: true, dataIndex: 'nb_ap'}
        ];
        var actions = [rowActions, rowActions3];
        if (application.user.statuscode > 1) {
            columns.push(topologie);
            actions.push(topologie);
            columns.push(relecture);
            actions.push(relecture);
        }
        columns.push(rowActions);

        ZpListGrid = new Ext.grid.GridPanel({
            region:"west"
            ,id: 'zp_list_grid'
            ,xtype: 'grid'
            ,width:500
            ,split: true
            ,store: store
            ,viewConfig:{
                emptyText:'<span class="pInfo" >Aucune donnée ne peut être affichée. Voir message ci-dessus</span>'
            }
            ,loadMask: true
            ,columns:columns
            ,plugins: actions
            ,sm: new Ext.grid.RowSelectionModel({singleSelect:true})
            ,autoExpandColumn: 'taxon'
            ,stripeRows: true
            ,tbar: toolbarItems
            ,listeners:{
                rowdblclick:function(grid,rowIndex){
                    var record = grid.getStore().getAt(rowIndex);
                    if(record){
                        application.layout.loadZp(record);
                    }
                }
            }
        });
        return ZpListGrid;		
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
        //transform depuis 2154 pour les communes cbna, 27572 pour les communes pne
        bounds.transform(new OpenLayers.Projection("EPSG:2154"),map.getProjection());
        var zoomLevel = map.getZoomForExtent(bounds);
        var centerGeom = bounds.getCenterLonLat();
        if (zoomLevel > 9){zoomLevel = 9;}
        map.setCenter(centerGeom,zoomLevel);
    };

    /**
     * Method: getViewportCenterItem
     */
    var getViewportCenterItem = function() {
        createMap();
        // maMap = map; //debug
        toolbar = new mapfish.widgets.toolbar.Toolbar({
            map: map,
            configurable: false
        });
        createMapSearcher();

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
                    iconCls: 'zoomfull',
                    toggleGroup: this.id
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
                    iconCls: 'pan',
                    toggleGroup: this.id
                }
            );

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
                ,id: 'combo-pda-secteur'
                ,fieldLabel:"Territoire - Site"
                ,emptyText: "Territoire - Site"
                ,name:"nomsecteur"
                ,hiddenName:"secteur_carto"
                ,store: application.secteurCbnaStore
                ,valueField: "id_secteur"
                ,displayField: "nom_secteur"
                ,width: 200
                ,typeAhead: true
                ,typeAheadDelay:750
                ,forceSelection: true
                ,selectOnFocus: true
                ,editable: true
                ,resizable:true
                ,triggerAction: 'all'
                ,trigger3Class: 'x-hidden'
                ,listeners: {
                    select: function(combo, record) {
                        Ext.getCmp('combo-commune').clearValue();
                        myProxyCommunes.url = 'bibs/communescbna?secteur='+combo.getValue();
                        communeStore.reload();
                        if(Ext.getCmp('ra-window')){
                            if(!Ext.getCmp('ra-window').isVisible()){
                                Ext.getCmp('ra-combo-commune').clearValue();
                                Ext.getCmp('hidden-commune').setValue('');
                                zoomToRecord(record);
                            }
                        }
                        else{
                        zoomToRecord(record);
                        }
                    }
                    ,clear: function(combo) {
                        myProxyCommunes.url = 'bibs/communescbna';
                        communeStore.reload();
                        // Ext.getCmp('hidden-extent').setValue('');
                        if(Ext.getCmp('ra-window')){
                            if(!Ext.getCmp('ra-window').isVisible()){
                                Ext.getCmp('ra-combo-commune').clearValue();
                                Ext.getCmp('hidden-commune').setValue('');                                
                            }
                        }
                        else{
                            map.zoomToMaxExtent();
                        }
                    }
                    ,trigger3Click: function(combo) {
                        var index = combo.view.getSelectedIndexes()[0];
                        var record = combo.store.getAt(index);
                        zoomToRecord(record);
                    }
                }
            });
            myProxyCommunes = new Ext.data.HttpProxy({
                url: 'bibs/communescbna'
                ,method: 'GET'
            });
            var communeStore = new Ext.data.JsonStore({
                storeId:'commune-store'
                ,url: myProxyCommunes
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
                ,id: 'combo-commune'
                ,fieldLabel:"Commune"
                ,emptyText: "Commune"
                ,name:"nomcommune"
                ,hiddenName:"commune_carto"
                ,store: communeStore
                ,valueField: "insee"
                ,displayField: "nomcommune"
                ,typeAhead: true
                ,typeAheadDelay:750
                ,forceSelection: true
                ,selectOnFocus: true
                ,resizable:true
                ,triggerAction: 'all'
                ,mode: 'local'
                ,trigger3Class: 'x-hidden'
                // keep the clear button never displayed
                // ,trigger1Class: 'x-form-clear-trigger always-hidden'
                ,listeners: {
                    select: function(combo, record) {
                        // combo.triggers[2].removeClass('x-hidden');
                        if(Ext.getCmp('ra-combo-commune')){Ext.getCmp('ra-combo-commune').setValue(combo.getValue());}
                        zoomToRecord(record);
                    }
                    ,clear: function(combo) {
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
                    ,id:'combo-pda-annee'
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
                    ,id:'hidden-commune'
                    ,name:'commune'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-extent'
                    ,name:'extent'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-topologie'
                    ,name:'topologie'
                    ,value:''
                },{
                    xtype:'hidden'
                    ,id:'hidden-relecture'
                    ,name:'relecture'
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
                    ,id:'combo-pda-observateur'
                    ,fieldLabel:"Observateur"
                    ,name:"observateur"
                    ,hiddenName:"id_role"
                    ,store: application.auteursStorePda
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
                }]
            },{
                items:[{
                    xtype:"twintriggercombo"
                    ,id:'combo-pda-latin'
                    ,fieldLabel:"Taxon latin"
                    ,name:"taxonl"
                    ,hiddenName:"lcd_nom"
                    ,store: application.taxonsLStore
                    ,valueField: "cd_nom"
                    ,displayField: "latin"
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,listWidth: 230
                    ,width:220
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                }]
            },{
                items:[{
                    xtype:"twintriggercombo"
                    ,id: 'combo-pda-organisme'
                    ,fieldLabel:"Organisme producteur"
                    ,name:"organisme"
                    ,hiddenName:"id_organisme"
                    ,store: application.organismeStore
                    ,valueField: "id_organisme"
                    ,displayField: "nom_organisme"
                    ,typeAhead: true
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,listWidth: 130
                    ,width: 150
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                }]
            }
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

        columns.push({
            width: 250
            ,height: 50
            ,buttons: [{
                id:'btn-raz'
                ,text: "RAZ"
                ,handler: function() {
                    formSearcher.form.reset();
                    application.rechercheAvancee.formReset();
                    map.zoomToMaxExtent();
                    // formSearcher.triggerSearch();
                    Ext.getCmp('zp_count').setText("les 50 dernières prospections");
                }
                ,listeners: {click: function(button, e) {Ext.getCmp('btn-avancee').removeClass('red-btn');}}
            },{
                id:'btn-rechercher'
                ,text: "Rechercher"
                ,handler: function() {
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
            ,tooltip: 'Exporter les données vers Excel'
            ,handler: function() {
                var a = Ext.getCmp('combo-pda-annee').getValue();
                var ob = Ext.getCmp('combo-pda-observateur').getValue();
                var org = application.user.id_organisme;
                var t = Ext.getCmp('combo-pda-latin').getValue();
                var o = Ext.getCmp('combo-pda-organisme').getValue();
                var c = Ext.getCmp('hidden-commune').getValue();
                var topo = Ext.getCmp('hidden-topologie').getValue();
                var r = Ext.getCmp('hidden-relecture').getValue();
                var tp = Ext.getCmp('hidden-typeperiode').getValue();
                var sd, ed = new Date();
                var sd = Ext.getCmp('hidden-startdate').getValue();
                var ed = Ext.getCmp('hidden-enddate').getValue(); 
                var st = "no";
                if(Ext.getCmp('zp_count').text=="les 50 dernières prospections"){st = "yes"};
                var b = map.getExtent().toBBOX();                
                window.location = 'ap/xls?annee='+a+'&observateur='+ob+'&id_organisme='+org+'&taxon='+t+'&organisme='+o+'&commune='+c+'&topologie='+topo+'&relecture='+r+'&box='+b+'&box='+b+'&typeperiode='+tp+'&startdate='+sd+'&enddate='+ed+'&start='+st;
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
        var zpDefaultStyle = new OpenLayers.Style({
            fillColor:'#FF9922',
            pointRadius: 5,
            strokeColor:'#f00',
            strokeWidth:2,
            fillOpacity:0.4,
            graphicZIndex:2,
        });

        var styleMap = new OpenLayers.StyleMap({
            'default':zpDefaultStyle
           ,'select': OpenLayers.Util.extend({display: ""},
                OpenLayers.Feature.Vector.style['select'])
        });

        // create a lookup table with different symbolizers for the different
        // state values
        var lookup = {
            "topologies_valides": {
                fillColor: "green"
                ,strokeColor: "green"
                ,cursor: "pointer"
            }
        };

        styleMap.addUniqueValueRules("default", lookup);

        return new OpenLayers.Layer.Vector("vector"
            ,{
                protocol: eventProtocol
                ,strategies: [
                    new mapfish.Strategy.ProtocolListener()
                ]
                ,format: OpenLayers.Format.GeoJSON
                ,styleMap: styleMap
                ,projection : map.getProjection()
                ,units: map.getProjection().getUnits()
                // ,projection : new OpenLayers.Projection("IGNF:GEOPORTALFXX")
                // ,units: new OpenLayers.Projection("IGNF:GEOPORTALFXX").getUnits()
                ,maxResolution: resolution_max
                // ,maxResolution: 0.02197265625
                // ,maxExtent: new OpenLayers.Bounds(-1572863.9803763316, 3670016.0381122422,2097151.9738351088, 6815743.991265957)
                ,maxExtent: extent_max
            }
        );
    };

    /**
     * Method: createMap
     * Creates the map
     *
     * Return
     * <OpenLayers.Map>
     */
    var createMap = function() {
        map = application.createMap();

        var vector = createLayer();
        map.addLayers([vector]);

        var selectControl = new OpenLayers.Control.SelectFeature([vector], {
            multiple: false
        });

        var mediator = new mapfish.widgets.data.GridRowFeatureMediator({
            grid: ZpListGrid,
            selectControl: selectControl
        });

        map.addControl(selectControl);
        selectControl.activate();

        map.zoomToMaxExtent();
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

    /**
     * Method: updateMap
     * Updates the map by adding/removing WMS layers in the overlay WMS layer (communes, bv, etc...)
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
        ,zoomTo: function(extent) {
            //extent = extent.split(',');
            var bounds = new OpenLayers.Bounds(extent[0], extent[1], extent[2], extent[3]);
            //transform depuis 2154 pour les communes cbna
            bounds.transform(new OpenLayers.Projection("EPSG:2154"),map.getProjection());
            map.zoomToExtent(bounds);
        }
        ,refreshZps: function() {
            formSearcher.triggerSearch();
            // redraw the WMS layer (true to force the redraw)
            map.getLayersByName('overlay')[0].redraw(true);
        }
        ,triggerSearch : function() {
            return formSearcher.triggerSearch();
        }
    }
}();
