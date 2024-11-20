({
    cleanUpNamespace : function(jsonData){	
        let responseStr = JSON.stringify(jsonData);	
        	
        if(responseStr.includes('beta_ccn__')){	
            responseStr = responseStr.replaceAll('beta_ccn__', '');	
        }	
        	
        if(responseStr.includes('compass_cn__') ){	
            responseStr = responseStr.replaceAll('compass_cn__', '');	
        }	
        	
        return JSON.parse(responseStr);	
    },

    initializePrefix : function(component, event, helper){
        let action = component.get('c.getNamespacePrefix');
        action.setCallback(this, function(response){
            if(response.getState() === 'SUCCESS'){
                const prefix = response.getReturnValue();
                if(prefix){
                    component.set('v.namespacePrefix', prefix);
                }
            }
            else{
                let error = response.getError();
                console.error({error});
            }
            this.doInitHelper(component, event, helper, null);
        });
        $A.enqueueAction(action);
    },

    doInitHelper: function (component, event, helper, sortByValue) {
        document.title = 'Loading....';
        let namespaceVal = '';
        
        if(component.get("v.isFilter") != true){
            component.set("v.showSpinner", true);
        }
        let url_string = document.location.href;
        let campaignId = url_string.split("id=")[1];
        
        component.set("v.campaignId", campaignId);
        var device = $A.get("$Browser.formFactor");
        
        let action = component.get("c.getRaidDetails");
        action.setParams({
            campaignId: campaignId,
            sortByValue : sortByValue
        });
        
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let resultMap = this.cleanUpNamespace(JSON.parse(response.getReturnValue()));;
                const { eventInfoList, raidInfoList, typeList} = resultMap;
                const dataTableReady = raidInfoList.map((raid) => {
                    const Description__c = raid.Description__c || "";
                    const Resolution__c = raid.Resolution_Answer__c || "";
                    const Type__c = raid.Type__c || "";
                    const Status__c = raid.Status__c || "";
                    const Event_Name = raid.Event__r.Name || "";
                    const { Name, Date_Raised__c, Raised_By_Email__c} = raid;
                    
                    //Issue Tracker Info
					// Directly gets date from record field. Previous implementation instantiates a new Date object which in turn gets TZ from the machine.
                    const DateSplit = (raid.Date_Raised__c).split('-'); // FROM YYYY-MM-DD
                    const Date_RaisedFormatted = DateSplit[1] + '-' + DateSplit[2] + '-' + DateSplit[0]; // TO MM-DD-YYYY

                    const Raid_Info_Desktop = '<b>' + raid.Name + '</b>' +'\n' + Event_Name + '\nStatus: ' + Status__c  + '\nType: ' + Type__c;
                    const RaidInfo = '<b>' + raid.Name + '</b>' +'\nSession Name: ' + Event_Name + '\nStatus: ' + Status__c  + '\nType: ' + Type__c;

                    const Intake_details = 'Date Raised:\n' + Date_RaisedFormatted + '\nRaised By:\n' + Raised_By_Email__c;
                    return {
                        Description__c,
                        Resolution__c,
                        Type__c,
                        Status__c,
                        Event_Name,
                        Name,
                        Date_Raised__c,
                        Raised_By_Email__c,
                        Raid_Info_Desktop,
						RaidInfo,
                        Intake_details,
                        Date_RaisedFormatted
                    };
                });
                        
                /*Start CCN-CAM-3431-DV Gabriel Delavin Aug.21.2023 - Updated Raid Item to RAID Item*/          
                if(device == 'DESKTOP'){
                    component.set("v.columns", [
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '8%'},
                        {label: 'RAID Item', fieldName: 'Raid_Info_Desktop', type: 'text' ,editable: false, wrapText: true, fixedWidth: '14%'},
                        {label: 'Intake Details', fieldName: 'Intake_details', type: 'text' ,editable: false, wrapText: true, fixedWidth: '14%'},
                        {label: 'Description', fieldName: namespaceVal+'Description__c', type: 'text' ,editable: true, wrapText: true, fixedWidth: '34%'},
                        {label: 'Resolution/Answer', fieldName: namespaceVal+'Resolution__c', type: 'text' ,editable: true, wrapText: true, fixedWidth: '34%'},
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '10%'}
                
                    ]);
                }
                else if(device == 'TABLET'){
                    component.set('v.columns', [                            
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '2%'},
                        {label: 'Raid Item', fieldName: 'RaidInfo', type: 'text' ,editable: false, wrapText: true, fixedWidth: '20%'},
                        {label: 'Intake Details', fieldName: 'Intake_details', type: 'text' ,editable: false, wrapText: true, fixedWidth: '14%'},
                        {label: 'Description', fieldName: namespaceVal+'Description__c', type: 'text' ,editable: true, wrapText: true, fixedWidth: '35%'},
                        {label: 'Resolution/Answer', fieldName: namespaceVal+'Resolution__c', type: 'text' ,editable: false, wrapText: true, fixedWidth: '35%'}, 
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '3%'},
                    ]); 
                }
                
                document.title = 'Campaign RAID';
                
                component.set("v.raidList", dataTableReady);
                component.set('v.eventList', eventInfoList);
                component.set("v.types", typeList);
                component.set("v.showSpinner", false);

                
                // render table
                this.renderTable(component);
            }
            //Error
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = "Error on Loading Campaign Raid page"; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                this.showToast("Oops!", message, "error", "pester");
                component.set("v.showSpinner", false);
            }
        });
        
        $A.enqueueAction(action);
    },

    renderTable : function(component){
        let namespacePrefix = component.get('v.namespacePrefix');
        let namespace = namespacePrefix ? namespacePrefix : 'c';
        let container = component.find('table-container');
        $A.createComponent(
            `${namespace}:compassTable`,
            {
                keyField: 'Id',
                columns: component.get('v.columns'),
                rows: component.get('v.raidList'),
                hasSortbutton: 'true',
                sortOptions: component.get('v.sortByOptions')
            },
            function(cmp) {
                container.set("v.body", [cmp]); 
            }
        );
    },

    submitRaid: function (component, event, helper) {

        let action = component.get("c.createRaid");
        
        action.setParams({
            campaignId: component.get("v.campaignId"),
            eventId: component.find("eventInput").get("v.value"),
            email: component.get("v.email"),
            description: component.get("v.description"),
            type: component.get("v.type"),
        });
        
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                this.showToast(
                    "Success!",
                    "Your raid has been submitted.",
                    "success",
                    "pester"
                );
                component.set("v.showSpinner", false);
                //Reset fields
                component.set("v.description", "");
                component.set("v.type", "");
                component.set("v.email", "");
                
                this.doInitHelper(component, event, helper, null);
            } else if (state === "ERROR") {
                let errors = response.getError();
                let message = "Error on Creating Raid"; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                this.showToast("Oops!", message, "error", "pester");
                component.set("v.showSpinner", false);
            } else {
                this.showToast(
                    "Oops!",
                    "Something's not right. Please contact the administrator for help.",
                    "error",
                    "pester"
                );
                component.set("v.showSpinner", false);
            }
        });
        $A.enqueueAction(action);
    },

    showToast: function (title, message, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            type: type,
            mode: mode,
        });
        toastEvent.fire();
    },
    
});