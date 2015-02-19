/**
 * @class application.validateCategories
 * Singleton to build the validateCategories window
 *
 * @singleton
 */
application.rechercheAvancee = function() {
    // private variables
    var initialezed = false;

    var initWindow = function() {
        return new Ext.Window({
            title: "Recherche avancée"
            ,id: 'ra-window'
            ,layout: 'fit'
            ,modal: true
            ,plain: true
            ,aspect: true
            ,width: 700
            ,height: 500
            ,closeAction: 'hide'
            ,defaults: {
                border: false
            }
            ,items: getFormPanel()
            ,buttons: [{
				text:'Rechercher'
				,id:'raSaveButton'
				,handler: submitForm
			},{
				text: 'Annuler'
				,handler: function(){
					application.rechercheAvancee.window.hide();
				}
			}]
            ,listeners:{
                afterlayout:function(){
                    if(!initialezed){
                    Ext.getCmp("rsa").setValue(true);
                    Ext.getCmp("raa").setValue(false);
                    initialezed  = true;
                    }
                }
            }
        });
    };
    var getFormPanel = function() {
        var formPanel = new Ext.form.FormPanel({
            region: 'center'
            ,id:'ra-form'
            ,xtype: 'formpanel'
            ,height:50
            ,split: false
            ,layout:"column"
            ,labelWidth:100
            ,frame:true
            ,defaults:{
                border:false
                ,bodyStyle:"padding: 3px"
                ,layout: 'form'
                ,labelAlign: 'left'
                //config saki
                ,columnWidth:0.5
                ,hideLabels:true
            }
            ,items: getFormColumns()
        });
        return formPanel;
    };
    /**
     * Method: getContent
     * Creates the msg grid
     */
    var getFormColumns = function() {
        var releveStore = new Ext.data.SimpleStore({
            fields: [
                {name:'releve', type: 'string'}
                ,{name:'label', type: 'string'}
            ]
            ,data:[
                ['P','partiel']
                ,['C','complet']
            ]
        });
        
            
        var col1 = {
            // these are applied to fieldsets
             defaults:{layout:'form', anchor:'100%', autoHeight:true}
            // fieldsets
            ,items:[{
                title:'Critères de base'
                // these are applied to fields
                ,defaults:{anchor:'-20'}
                // fields
                ,items:[{
                    xtype:"twintriggercombo"
                    ,id:'ra-combo-bryo-observateur'
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
                },{
                    xtype:"twintriggercombo"
                    ,id:'ra-combo-bryo-otaxon'
                    ,fieldLabel:"Taxon origine"
                    ,name:"otaxon"
                    ,hiddenName:"ocd_nom"
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
                },{
                    xtype:"twintriggercombo"
                    ,id:'ra-combo-bryo-rtaxon'
                    ,fieldLabel:"Taxon de référence"
                    ,name:"rtaxon"
                    ,hiddenName:"rcd_nom"
                    ,store: application.filtreTaxonsReferenceStore
                    ,valueField: "cd_nom"
                    ,displayField: "nom_complet"
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
                }
                ]
            },{
                 title:'Critères "expert"'
                // these are applied to fields
                ,defaults:{anchor:'-20'}
                // fields
                ,items:[{
                    id: 'ra-textefield-id-station'
                    ,xtype: 'numberfield'
                    ,allowDecimals :false
                    ,allowNegative: false
                    ,fieldLabel: 'Numéro de station '
                    ,name: 'a_id_station'
                    ,width: 120
                },{
                    xtype:"twintriggercombo"
                    ,id: 'ra-combo-bryo-releve'
                    ,fieldLabel:"Niveau de relevé"
                    ,name:"releve"
                    ,hiddenName:"releve"
                    ,store: releveStore
                    ,valueField: "releve"
                    ,displayField: "label"
                    ,emptyText:'Niveau de relevé'
                    ,typeAhead: true
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,listWidth: 120
                    ,width:120
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                }
,{
                    xtype:"twintriggercombo"
                    ,id: 'ra-combo-bryo-exposition'
                    ,fieldLabel:"Exposition"
                    ,name:"id_exposition"
                    ,hiddenName:"id_exposition"
                    ,store: application.expositionStore
                    ,valueField: "id_exposition"
                    ,displayField: "nom_exposition"
                    ,emptyText:'Exposition'
                    ,typeAhead: true
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,width:120
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                }]
            }]
        };

        var myProxyCommunes = new Ext.data.HttpProxy({
            id:'store-communes-proxy'
            ,url: 'bibs/communes'
            ,method: 'GET'
        });
        var raCommuneStore = new Ext.data.JsonStore({
            url: myProxyCommunes
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
        });
        
        var col2 = {
            // these are applied to fieldsets
             defaults:{layout:'form', anchor:'100%', autoHeight:true}
            // fieldsets
            ,items:[{
                 title:'Critères de dates ou de période'
                // these are applied to fields
                ,defaults:{anchor:'-20'}
                // fields
                ,items:[{
                    xtype:"twintriggercombo"
                    ,id:'ra-combo-bryo-annee'
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
                    xtype: 'radiogroup'
                    ,id:'rg-periode'
                    ,fieldLabel: 'Recherche sur une période'
                    ,name:'typeperiode'
                    ,items: [
                        {
                            boxLabel: 'sans année'
                            ,id:'rsa'
                            ,name: 'rb-typeperiode'
                            ,inputValue: 'sa'
                            ,listeners: {
                                check: function(cb,value) {
                                    if(value){
                                        var typeperiode = Ext.getCmp('rg-periode').items.get(0).getGroupValue();
                                        if (typeperiode == 'sa'){
                                            Ext.getCmp('ra-startdate-aa').hide();
                                            Ext.getCmp('ra-enddate-aa').hide();
                                            Ext.getCmp('ra-startdate-sa').show();
                                            Ext.getCmp('ra-enddate-sa').show();
                                            Ext.getCmp('hidden-enddate').setValue(Ext.getCmp('ra-enddate-sa').getValue());
                                            Ext.getCmp('hidden-startdate').setValue(Ext.getCmp('ra-startdate-sa').getValue());
                                        }
                                    }
                                }
                            }
                        },{
                            boxLabel: 'avec année'
                            ,id:'raa'
                            ,name: 'rb-typeperiode'
                            ,inputValue: 'aa'
                            ,checked: true
                            ,listeners: {
                                check: function(cb,value) {
                                    if(value){
                                        var typeperiode = Ext.getCmp('rg-periode').items.get(0).getGroupValue();
                                        if (typeperiode == 'aa'){
                                            Ext.getCmp('ra-startdate-sa').hide();
                                            Ext.getCmp('ra-enddate-sa').hide();
                                            Ext.getCmp('ra-startdate-aa').show();
                                            Ext.getCmp('ra-enddate-aa').show();
                                            Ext.getCmp('hidden-enddate').setValue(Ext.getCmp('ra-enddate-aa').getValue());
                                            Ext.getCmp('hidden-startdate').setValue(Ext.getCmp('ra-startdate-aa').getValue());
                                        }
                                    }
                                }
                            }
                        }
                    ]
                },{
                    id: 'ra-startdate-aa'
                    ,xtype:'datefield'
                    ,fieldLabel: 'Date début'
                    ,name: 'aadatedebut'
                    ,format: 'd/m/Y'
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                    ,listeners:{ 
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                        ,change:function(df,date){Ext.getCmp('hidden-startdate').setValue(date);}                        
                    }
                },{
                    id: 'ra-enddate-aa'
                    ,xtype:'datefield'
                    ,fieldLabel: 'Date fin'
                    ,name: 'aadatefin'
                    ,format: 'd/m/Y'
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                    ,listeners:{ 
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                        ,change:function(df,date){Ext.getCmp('hidden-enddate').setValue(date);}                        
                    }
                },{
                    id: 'ra-startdate-sa'
                    ,xtype:'datefield'
                    ,fieldLabel: 'Date début'
                    ,name: 'sadatedebut'
                    ,format: 'd/m'
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                    ,listeners:{ 
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);} 
                        ,change:function(df,date){Ext.getCmp('hidden-startdate').setValue(date);}
                    }
                },{
                    id: 'ra-enddate-sa'
                    ,xtype:'datefield'
                    ,fieldLabel: 'Date fin'
                    ,name: 'sadatefin'
                    ,format: 'd/m'
                    //function pour cacher ou afficher les label en même temps que le champ de saisie
                    ,listeners:{ 
                        beforehide:function(nf){nf.getEl().up('.x-form-item').setDisplayed(false);}
                        ,beforeshow:function(nf){nf.getEl().up('.x-form-item').setDisplayed(true);}
                        ,change:function(df,date){Ext.getCmp('hidden-enddate').setValue(date);}
                    }
                }
                ]
            },{
                 title:'Critères de localisation'
                // these are applied to fields
                ,defaults:{anchor:'-20'}
                // fields
                ,items:[{
                    xtype:"twintriggercombo"
                    ,id: 'ra-combo-bryo-secteur'
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
                        select: function(combo, record) {
                            Ext.getCmp('ra-combo-commune').clearValue();
                            Ext.getCmp('hidden-extent').setValue(record.data.extent);
                            myProxyCommunes.url = 'bibs/communes?secteur='+combo.getValue();
                            raCommuneStore.reload();
                            // combo.triggers[2].removeClass('x-hidden');
                        }
                        ,clear: function(combo) {
                            Ext.getCmp('hidden-extent').setValue('');
                            // combo.triggers[2].addClass('x-hidden');
                            myProxyCommunes.url = 'bibs/communes'
                            raCommuneStore.reload();
                        }
                        ,trigger3Click: function(combo) {
                            var index = combo.view.getSelectedIndexes()[0];
                            var record = combo.store.getAt(index);
                        }
                    }
                },{
                    xtype:"twintriggercombo"
                    ,id: 'ra-combo-commune'
                    ,fieldLabel:"Commune"
                    ,emptyText: "Commune"
                    ,name:"nomcommune"
                    ,hiddenName:"commune"
                    ,store: raCommuneStore
                    ,valueField: "insee"
                    ,displayField: "nomcommune"
                    ,typeAhead: true
                    ,typeAheadDelay:750
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,mode: 'local'
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-hidden'
                    ,listeners: {
                        select: function(combo, record) {
                            Ext.getCmp('hidden-extent').setValue(record.data.extent);
                        }
                        ,clear: function(combo) {
                            Ext.getCmp('hidden-extent').setValue('');
                        }
                    }
                }
                ]
            }]

        };
        var columns = [col1, col2];
        
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

        return columns;
    };

	var submitForm = function() {
        Ext.ux.Toast.msg('zi va !', 'go');
       
        Ext.getCmp('hidden-id-station').setValue(Ext.getCmp('ra-textefield-id-station').getValue());
        Ext.getCmp('hidden-commune').setValue(Ext.getCmp('ra-combo-commune').getValue());
        Ext.getCmp('hidden-secteur').setValue(Ext.getCmp('ra-combo-bryo-secteur').getValue());
        Ext.getCmp('combo-bryo-observateur').setValue(Ext.getCmp('ra-combo-bryo-observateur').getValue());
        Ext.getCmp('combo-bryo-rtaxon').setValue(Ext.getCmp('ra-combo-bryo-rtaxon').getValue());
        //Ext.getCmp('hidden-enddate').setValue(Ext.getCmp('ra-enddate').getValue());
        //Ext.getCmp('hidden-startdate').setValue(Ext.getCmp('ra-startdate').getValue());
        Ext.getCmp('combo-bryo-annee').setValue(Ext.getCmp('ra-combo-bryo-annee').getValue());
        Ext.getCmp('hidden-releve').setValue(Ext.getCmp('ra-combo-bryo-releve').getValue());
        Ext.getCmp('hidden-otaxon').setValue(Ext.getCmp('ra-combo-bryo-otaxon').getValue());
        Ext.getCmp('hidden-exposition').setValue(Ext.getCmp('ra-combo-bryo-exposition').getValue());
        Ext.getCmp('hidden-typeperiode').setValue(Ext.getCmp("rg-periode").items.get(0).getGroupValue());
        application.search.triggerSearch();
        application.rechercheAvancee.window.hide();
        var extent =  Ext.getCmp('hidden-extent').value.split(',');
        if (extent!=''){application.search.zoomTo(extent);}
 	};

    /**
     * Method: resetWindow
     * Reset for next usage
     */
    var resetWindow = function() {
        Ext.getCmp('ra-startdate-aa').hide();
        Ext.getCmp('ra-enddate-aa').hide();
        Ext.getCmp('ra-startdate-sa').show();
        Ext.getCmp('ra-enddate-sa').show();
    };
    // public space
    return {
        window: null
        ,init: function() {
            this.window = initWindow();
        }
        ,loadRa: function() {
            if (!this.window) {
                this.init();
            }
            
            Ext.getCmp('ra-combo-bryo-annee').setValue(Ext.getCmp('combo-bryo-annee').getValue());
            Ext.getCmp('ra-combo-bryo-observateur').setValue(Ext.getCmp('combo-bryo-observateur').getValue());
            Ext.getCmp('ra-combo-bryo-rtaxon').setValue(Ext.getCmp('combo-bryo-rtaxon').getValue());
            // Ext.getCmp('ra-combo-bryo-secteur').setValue('');
            //resetWindow();
            this.window.show();
        }
        ,formReset:function(){
            if (Ext.getCmp('ra-form')){Ext.getCmp('ra-form').getForm().reset();} 
        }
    }
}();