({
    // Added by JaysonLabnao [Namespace Issue Fixes] August192022
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

    // Added by JaysonLabnao [NamespaceIssueFixes] August172022
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
            helper.doInitHelper(component, event, helper, null);
        });
        $A.enqueueAction(action);
    },

    //Updated by MMallorca [CCN793,794,795] Oct192021 Add sortByValue param
    doInitHelper: function (component, event, helper, sortByValue) {
        document.title = 'Loading....';
        let namespaceVal = '';
        
       //Updated by MMallorca [CCN793,794,795] Oct192021
        if(component.get("v.isFilter") != true){
            component.set("v.showSpinner", true);
        }
        let url_string = document.location.href;
        let eventId = url_string.split("id=")[1].slice(0, 11);
        const urlParams = new URLSearchParams(url_string);
        
        component.set("v.eventId", eventId);
        //component.set('v.contactId',contactId);
        
        var device = $A.get("$Browser.formFactor");
        
        let action = component.get("c.getProjectDetails");
        
        action.setParams({
            eventId: eventId,
            //contactId : contactId,
            //Updated by MMallorca [CCN793,794,795] Oct192021 Add sortByValue param
            sortByValue : sortByValue
        });
        
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let resultMap = helper.cleanUpNamespace(JSON.parse(response.getReturnValue()));;
                const {campaignRecord, typeList, sessionWrapper, projIssueList} = resultMap;
                let parkingLots = resultMap.projIssueList;
                const dataTableReady = projIssueList.map((issue) => {
                    const Description__c = issue.Description__c || "";
                    const Resolution__c = issue.Resolution__c || "";
                    const Type__c = issue.Type__c || "";
                    const Status__c = issue.Status__c || "";
                    const Session_Name = issue.Session__r.Name || "";
                    const { Name, Date_Raised__c, Raised_By_Email__c} = issue;
                                                         
					//Issue Tracker Info
					// const DateRaised = new Date(issue.Date_Raised__c);
                	// const Date_RaisedFormatted = ((DateRaised.getMonth() > 8) ? (DateRaised.getMonth() + 1) : ('0' + (DateRaised.getMonth() + 1))) + '-' + ((DateRaised.getDate() > 9) ? DateRaised.getDate() : ('0' + DateRaised.getDate())) + '-' + DateRaised.getFullYear();

                    // UPDATED BY JC Espino [CCN-1283] MARCH 28 2022
                    // Directly gets date from record field. Previous implementation instantiates a new Date object which in turn gets TZ from the machine.
                    const DateSplit = (issue.Date_Raised__c).split('-'); // FROM YYYY-MM-DD
                    const Date_RaisedFormatted = DateSplit[1] + '-' + DateSplit[2] + '-' + DateSplit[0]; // TO MM-DD-YYYY

                    const Issue_Tracker_Info_Desktop = '<b>' + issue.Name + '</b>' +'\n' + issue.Raised_By_Email__c + '\n' + Date_RaisedFormatted  + '\n' + Session_Name+ '\n' + Status__c+ '\n' + Type__c;
                    const Issue_Tracker_Info = '<b>' + issue.Name + '</b>' + '\n' + issue.Raised_By_Email__c + '\n' + Date_RaisedFormatted  + '\n' + Session_Name+ '\nStatus: ' + Status__c+ '\nIssue Type: ' + Type__c;
                    return {
                        Description__c,
                        Resolution__c,
                        Type__c,
                        Status__c,
                        Session_Name,
                        Name,
                        Date_Raised__c,
                        Raised_By_Email__c,
                        Issue_Tracker_Info_Desktop,
						Issue_Tracker_Info,
                        Date_RaisedFormatted
                    };
                });
                // for (let i = 0; i < parkingLots.length; i++) {
                //     let row = parkingLots[i];
                //     if (row.Description__c) {
                //         row.Description__c = row.Description__c;
                //     } else {
                //         row.Description__c = "";
                //     }
                //     if (row.Resolution__c) {
                //         row.Resolution__c = row.Resolution__c;
                //     } else {
                //         row.Resolution__c = "";
                //     }
                //     if (row.Type__c) {
                //         row.Type__c = row.Type__c;
                //     } else {
                //         row.Type__c = "";
                //     }
                //     if (row.Status__c) {
                //         row.Status__c = row.Status__c;
                //     } else {
                //         row.Status__c = "";
                //     }
                //     if (row.Session__c){
                //         row.Session_Name = row.Session__r.Name;
                //     }
                //     else{
                //         row.Session_Name ='';
                //     }
                // }
                
                //Updated by Jayson Labnao [EVENT REFRESH FIXES] Jan142022
                if(resultMap.contact) {
                    component.set("v.email", resultMap.contact.Email);
                }
                        
                if(device == 'DESKTOP'){
                    component.set("v.columns", [
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '8%'},
                        {label: 'Issue Information', fieldName: 'Issue_Tracker_Info_Desktop', type: 'text' ,editable: false, wrapText: true, fixedWidth: '14%'},
                        {label: 'Description', fieldName: namespaceVal+'Description__c', type: 'text' ,editable: true, wrapText: true, fixedWidth: '34%'},
                        {label: 'Resolution/Answer', fieldName: namespaceVal+'Resolution__c', type: 'text' ,editable: false, wrapText: true, isSortColumn: true}, // isSortColumn shouldn't have width
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '10%'}
                
                    ]);
                }
                else if(device == 'TABLET'){
                    component.set('v.columns', [                            
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '2%'},
                        {label: 'Issue Information', fieldName: 'Issue_Tracker_Info', type: 'text' ,editable: false, wrapText: true, fixedWidth: '20%'},
                        {label: 'Description', fieldName: namespaceVal+'Description__c', type: 'text' ,editable: true, wrapText: true, fixedWidth: '35%'},
                        {label: 'Resolution/Answer', fieldName: namespaceVal+'Resolution__c', type: 'text' ,editable: false, wrapText: true, isSortColumn: true}, // isSortColumn shouldn't have width
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '3%'},
                    ]); 
                }
                
                if(campaignRecord.Issue_Tracker_Page_Title__c != null || campaignRecord.Issue_Tracker_Page_Title__c !=  undefined){
                    component.set("v.issueTrackerPageTitle", campaignRecord.Issue_Tracker_Page_Title__c);
                    document.title = campaignRecord.Issue_Tracker_Page_Title__c;
                }else{
                    component.set("v.issueTrackerPageTitle", 'ISSUE TRACKER');
                }
                
                component.set("v.eventRecordId", campaignRecord.Id);
                component.set("v.types", typeList);
                component.set('v.sessionList', sessionWrapper);
                
                // component.set("v.parkingLots", parkingLots);
                component.set("v.parkingLots", dataTableReady);
                component.set("v.showSpinner", false);

                /* Updated [EVENT REFRESH FIXES] JaysonLabnao Feb072022 */
                // render table
                helper.renderTable(component);
            }
            //Error
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = "Error on Loading Parking lot page"; // Default error message
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
        // Updated by JaysonLabnao [NamespaceIssueFixes] August192022
        let namespacePrefix = component.get('v.namespacePrefix');
        let namespace = namespacePrefix ? namespacePrefix : 'c';
        let container = component.find('table-container');
        $A.createComponent(
            `${namespace}:compassTable`,
            {
                keyField: 'Id',
                columns: component.get('v.columns'),
                rows: component.get('v.parkingLots'),
                hasSortbutton: 'true',
                sortOptions: component.get('v.sortByOptions')
            },
            function(cmp) {
                container.set("v.body", [cmp]); 
            }
        );
    },
    
    submitParkingLot: function (component, event, helper) {
        let action = component.get("c.createProjectIssue");
        
        action.setParams({
            eventId: component.get("v.eventId"),
            session: component.get("v.selectedSessionId"),
            email: component.get("v.email"),
            description: component.get("v.description"),
            type: component.get("v.type"),
        });
        
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                this.showToast(
                    "Success!",
                    "Your issue has been submitted.",
                    "success",
                    "pester"
                );
                component.set("v.showSpinner", false);
                //Reset fields
                component.set("v.description", "");
                component.set("v.type", "");
                component.set("v.email", "");
                
                //Updated by MMallorca [CCN793,794,795] Oct192021 Add sortByValue param set to null
                helper.doInitHelper(component, event, helper, null);
            } else if (state === "ERROR") {
                let errors = response.getError();
                let message = "Error on Creating Parking Issue"; // Default error message
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
    /*
    updateParkingLots : function(component, event, helper) {
        let action = component.get("c.updateParkingLots");    
        let draftValues = event.getParam('draftValues');
        action.setParams({
            parkingLots : JSON.stringify(draftValues)
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            console.log('FLAG 3');
            if (state === "SUCCESS") {
                console.log('FLAG 4');
                this.showToast('Success!', "Your changes has been saved.", "success", "pester");
                component.set("v.showSpinner", false);
                helper.doInitHelper(component,event,helper,true);
               
                //$A.get('e.force:refreshView').fire();
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = 'Error on Uodating Parking Lots'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                   message = errors[0].message;
                }
                this.showToast('Oops!', message, "error", "pester");
                component.set("v.showSpinner", false);
            }
            else {
                console.log('FLAG 5');
                console.log("Failed with state: " + state);
                this.showToast('Oops!', "Something's not right. Please contact the administrator for help.", "error", "pester");
                component.set("v.showSpinner", false);
            }
        });
        console.log('FLAG 6');
        $A.enqueueAction(action);
        console.log('FLAG 7');
    },
	*/
});