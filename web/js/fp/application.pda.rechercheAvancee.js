/**
 * @class application.validateCategories
 * Singleton to build the validateCategories window
 *
 * @singleton
 */
application.rechercheAvancee = function() {
    // private variables
    var initialezed = false;

    var initWindow = function(ap, zp) {
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
                ,hide:function(){
                    if(!Ext.getCmp("ra-form").getForm().isDirty()){
                        Ext.getCmp('btn-avancee').removeClass('red-btn');
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
        var relectureStore = new Ext.data.SimpleStore({
            fields: [
                {name:'relecture', type: 'string'}
                ,{name:'label', type: 'string'}
            ]
            ,data:[
                ['o','Relue']
                ,['n','Non relue']
            ]
        });
        var topologieStore = new Ext.data.SimpleStore({
            fields: [
                {name:'topologie', type: 'string'}
                ,{name:'label', type: 'string'}
            ]
            ,data:[
                ['o','Valide']
                ,['n','Non valide']
            ]
        });
        myRaProxyCommunes = new Ext.data.HttpProxy({
            url: 'bibs/communescbna'
            ,method: 'GET'
        });
        var raCommuneStore = new Ext.data.JsonStore({
            storeId:'ra-commune-store'
            ,url: myRaProxyCommunes
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
                    ,id:'ra-combo-pda-observateur'
                    ,fieldLabel:"Observateur"
                    ,emptyText:"Observateur"
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
                },{
                    xtype:"twintriggercombo"
                    ,id:'ra-combo-pda-latin'
                    ,fieldLabel:"Taxon latin"
                    ,emptyText:"Taxon latin"
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
                },{
                    xtype:"twintriggercombo"
                    ,id: 'ra-combo-pda-organisme'
                    ,fieldLabel:"Organisme"
                    ,emptyText: "Organisme"
                    ,name:"nomorganisme"
                    ,hiddenName:"organisme"
                    ,store: application.organismeStore
                    ,valueField: "id_organisme"
                    ,displayField: "nom_organisme"
                    ,typeAhead: true
                    ,width: 150
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: false
                    ,triggerAction: 'all'
                    ,trigger3Class: 'x-hidden'
                }
                ]
            },{
                 title:'Critères "expert"'
                // these are applied to fields
                ,defaults:{anchor:'-20'}
                // fields
                ,items:[{
                    xtype:"twintriggercombo"
                    ,id: 'ra-combo-pda-relecture'
                    ,fieldLabel:"Statut de relecture"
                    ,emptyText:"Statut de relecture"
                    ,name:"relecture"
                    ,hiddenName:"relecture"
                    ,store: relectureStore
                    ,valueField: "relecture"
                    ,displayField: "label"
                    ,typeAhead: true
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,listWidth: 120
                    ,width:120
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                },{
                    xtype:"twintriggercombo"
                    ,id: 'ra-combo-pda-topologie'
                    ,fieldLabel:"Topologie"
                    ,emptyText:"Topologie"
                    ,name:"topologie"
                    ,hiddenName:"topologie"
                    ,store: topologieStore
                    ,valueField: "topologie"
                    ,displayField: "label"
                    ,typeAhead: true
                    ,forceSelection: true
                    ,selectOnFocus: true
                    ,editable: true
                    ,listWidth: 120
                    ,width:120
                    ,triggerAction: 'all'
                    ,mode: 'local'
                    ,trigger3Class: 'x-hidden'
                }]
            }]
        };
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
                    ,id:'ra-combo-pda-annee'
                    ,fieldLabel:"Année"
                    ,emptyText:"Année"
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
                    ,emptyText: 'Date début'
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
                    ,emptyText: 'Date fin'
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
                    ,emptyText: 'Date début'
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
                    ,emptyText: 'Date fin'
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
                ,items:[
                // {
                    // xtype:"twintriggercombo"
                    // ,id: 'ra-combo-secteur'
                    // ,fieldLabel:"Territoire - Site"
                    // ,emptyText: "Territoire - Site"
                    // ,name:"nomsecteur"
                    // ,hiddenName:"secteur"
                    // ,store: application.secteurCbnaStore
                    // ,valueField: "id_secteur"
                    // ,displayField: "nom_secteur"
                    // ,typeAhead: true
                    // ,width: 150
                    // ,forceSelection: true
                    // ,selectOnFocus: true
                    // ,editable: false
                    // ,triggerAction: 'all'
                    // ,trigger3Class: 'x-hidden'
                    // ,listeners: {
                        // select: function(combo, record) {
                            // Ext.getCmp('ra-combo-commune').clearValue();
                            // myRaProxyCommunes.url = 'bibs/communescbna?secteur='+combo.getValue();
                            // raCommuneStore.reload();
                            // Ext.getCmp('hidden-extent').setValue(record.data.extent);
                        // }
                        // ,clear: function(combo) {
                            // Ext.getCmp('hidden-extent').setValue('');
                            // myRaProxyCommunes.url = 'bibs/communescbna';
                            // raCommuneStore.reload();
                        // }
                        // ,trigger3Click: function(combo) {
                            // var index = combo.view.getSelectedIndexes()[0];
                            // var record = combo.store.getAt(index);
                        // }
                    // }
                // },
                {
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
        
        
        Ext.getCmp('hidden-commune').setValue(Ext.getCmp('ra-combo-commune').getValue());
        Ext.getCmp('combo-pda-organisme').setValue(Ext.getCmp('ra-combo-pda-organisme').getValue());
        Ext.getCmp('combo-pda-observateur').setValue(Ext.getCmp('ra-combo-pda-observateur').getValue());
        Ext.getCmp('combo-pda-latin').setValue(Ext.getCmp('ra-combo-pda-latin').getValue());
        //Ext.getCmp('hidden-enddate').setValue(Ext.getCmp('ra-enddate').getValue());
        //Ext.getCmp('hidden-startdate').setValue(Ext.getCmp('ra-startdate').getValue());
        Ext.getCmp('combo-pda-annee').setValue(Ext.getCmp('ra-combo-pda-annee').getValue());
        Ext.getCmp('hidden-relecture').setValue(Ext.getCmp('ra-combo-pda-relecture').getValue());
        Ext.getCmp('hidden-topologie').setValue(Ext.getCmp('ra-combo-pda-topologie').getValue());
        Ext.getCmp('hidden-typeperiode').setValue(Ext.getCmp("rg-periode").items.get(0).getGroupValue());
        application.search.triggerSearch();
        application.rechercheAvancee.window.hide();
        var extent =  Ext.getCmp('hidden-extent').value.split(',');
        if (extent!=''){application.search.zoomTo(extent);}
        // Ext.getCmp('combo-pda-secteur').clearValue();
        Ext.getCmp('combo-commune').setValue(Ext.getCmp('ra-combo-commune').getValue());
        
        
        /*
		if(form.isValid()){
            form.submit({
                url: 'zp/get'
                ,params: params
                ,success: function(request) {
                        Ext.ux.Toast.msg('Attends !', 'ci pas fini');                      
                }
                ,failure: application.checklog
            });
		}
		else{
			Ext.Msg.alert('Attention', 'Une information est mal saisie ou n\'est pas valide. Vous devez la corriger avant d\'enregistrer.');
		}*/
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
            
            Ext.getCmp('ra-combo-pda-annee').setValue(Ext.getCmp('combo-pda-annee').getValue());
            Ext.getCmp('ra-combo-pda-observateur').setValue(Ext.getCmp('combo-pda-observateur').getValue());
            Ext.getCmp('ra-combo-pda-latin').setValue(Ext.getCmp('combo-pda-latin').getValue());
            Ext.getCmp('ra-combo-pda-organisme').setValue(Ext.getCmp('combo-pda-organisme').getValue());
            //resetWindow();
            this.window.show();
        }
        ,formReset:function(){
            if (Ext.getCmp('ra-form')){Ext.getCmp('ra-form').getForm().reset();} 
        }
    }
}();