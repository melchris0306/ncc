({
    // Added by JaysonLabnao [NamespaceIssueFixes] August172022
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
            helper.doInitHelper(component, event, helper, null, false); 
        });
        $A.enqueueAction(action);
    },

    doInitHelper : function(component, event, helper, sortByValue) {
        document.title = 'Loading....';
        let namespaceVal = '';
        // Updated by MMallorca [CCN790,791,792] Oct212021 
        if(component.get("v.isFilter") != true){
            component.set("v.showSpinner", true);
        }
        /*component.set('v.columns', [
            {label: 'Parking Lot', fieldName: 'Name', type: 'text' ,editable: false},
           // {label: 'Session', fieldName: 'Session_Name', type: 'text' ,editable: false},
            {label: 'Raised By', fieldName: 'Raised_By__Name', type: 'text' ,editable: false},
            {label: 'Question', fieldName: 'Description__c', type: 'text' , wrapText: true }, 
            {label: 'Resolution/Aswer', fieldName: 'Resolution_Answer__c', type: 'text' ,editable: false},
            {label: 'Type', fieldName: 'Type__c', type: 'text' ,editable: true},
            {label: 'Status', fieldName: 'Status__c', type: 'text' ,editable: true},
            {label: 'Addressed By', fieldName: 'Addressed_By__Name', type: 'text' ,editable: false},
            {label: 'Escalated to', fieldName: 'Escalated_To__c', type: 'text' ,editable: false } 
        ]);*/
        
        var url_string = document.location.href;
        var eventId = (url_string.split('id=')[1]).slice(0,11);
        var contactId = null;
        const contactParam = (url_string.split('contactId=')[1]);
        
        if(contactParam != undefined){
            contactId = contactParam.slice(0,11);
            component.set('v.contactId',contactId);
        }
        
        component.set('v.eventId',eventId);
        var device = $A.get("$Browser.formFactor");
        
        let action = component.get("c.getParkingLotDetails");
        
        action.setParams({ 
            eventId : eventId,
            contactId : contactId,
            sortByValue : sortByValue
        });
        
        action.setCallback(this, function(response){
            let state = response.getState();
            if (state === "SUCCESS") {
                let resultMap = JSON.parse(response.getReturnValue());
                let parkingLots = resultMap.parkingLotList; 
                //Modified by RexieDavid CCN-EVE-3029-DV-ParkingLot
                if(resultMap.campaignRecord.hasOwnProperty('Parking_Lot_Close_Date__c')){
                    let dateNow = new Date().toJSON().slice(0, 10);
                    let dateNowIsGreaterThanCloseDate = (dateNow > resultMap.campaignRecord.Parking_Lot_Close_Date__c) ? true : false;
                    component.set('v.showCloseFields', dateNowIsGreaterThanCloseDate); 
                    component.set('v.closeMessage', resultMap.campaignRecord.Parking_Lot_Close_Message__c);
                }
                
                if(parkingLots){
                    for (let i = 0; i < parkingLots.length; i++) {
                        // Updated by MMallorca [CCN790,791,792] Oct212021 
                        let row = parkingLots[i];
                        
                        
                        if( row.Description__c){
                            row.Description__c = row.Description__c;
                        }
                        
                        else{
                            row.Description__c = '';
                        }
                        if( row.Resolution_Answer__c){
                            row.Resolution_Answer__c = row.Resolution_Answer__c;
                        }
                        
                        else{
                            row.Resolution_Answer__c = '';
                        }
                        if( row.Type__c){
                            row.Type__c = row.Type__c;
                        }
                        
                        else{
                            row.Type__c = '';
                        }
                        
                        if( row.Status__c){
                            row.Status__c = row.Status__c;
                        }
                        
                        else{
                            row.Status__c = '';
                        }
                        if( row.Escalated_To__c){
                            row.Escalated_To__c = row.Escalated_To__c;
                        }
                        
                        else{
                            row.Escalated_To__c = '';
                        }
                        if( row.Raised_By__c){
                            row.Raised_By__Name = row.Raised_By__r.Name;
                        }
                        
                        else{
                            row.Raised_By__Name = '';
                        }
                        if (row.Addressed_By__c){
                            row.Addressed_By__Name = row.Addressed_By__r.Name;
                        }
                        else{
                            row.Addressed_By__Name ='';
                        }
                        if (row.Session__c){
                            row.Session_Name = row.Session__r.Name;
                        }
                        else{
                            row.Session_Name ='';
                        }
                        //Parking Lot Info
                        row.Parking_Lot_Info_Desktop = '<b>' + row.Name + '</b>' + '\n' + row.Session_Name + '\n' + row.Status__c  + '\n' + row.Type__c;
                        row.Parking_Lot_Info = '<b>' + row.Name + '</b>' + '\n' + row.Session_Name + '\nStatus: ' + row.Status__c  + '\nType: ' + row.Type__c;
                    }
                }
                
                if(resultMap.campaignRecord.Location__c){
                    component.set('v.location', resultMap.campaignRecord.Location__r.Name); 
                }
                else{
                    component.set('v.location', ''); 
                }
                
                
                if(resultMap.campaignRecord.Parking_Lot_Page_Title__c != null || resultMap.campaignRecord.Parking_Lot_Page_Title__c !=  undefined){
                    component.set('v.parkingPageTitle', resultMap.campaignRecord.Parking_Lot_Page_Title__c);
                    document.title = resultMap.campaignRecord.Parking_Lot_Page_Title__c;
                }else{
                    component.set('v.parkingPageTitle', 'PARKING LOT');
                }
                
                //Updated by Jayson Labnao [EVENT REFRESH FIXES] Jan142022
                if(resultMap.contact){
                    component.set('v.email', resultMap.contact.Email); 
                }
                
                if(device == 'DESKTOP'){
                    component.set('v.columns', [
                        // Updated by Jayson Labnao Jan082022 [CCN790,791,792-Parking Lot Table Fix]
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '7%'},
                        {label: 'Parking Lot Information', fieldName: 'Parking_Lot_Info_Desktop', type: 'text' ,editable: false, wrapText: true, fixedWidth: '15%'},
                        {label: 'Description', fieldName: namespaceVal+'Description__c', type: 'text' ,editable: true, wrapText: true, fixedWidth: '33%'},
                        {label: 'Resolution/Answer', fieldName: namespaceVal+'Resolution_Answer__c', type: 'text' ,editable: false, wrapText: true, isSortColumn: true},
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '5%'}
                    ]);
                }
                else if(device == 'TABLET'){
                    component.set('v.columns', [
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '2%'},
                        {label: 'Parking Lot Information', fieldName: 'Parking_Lot_Info', type: 'text' ,editable: false, wrapText: true, fixedWidth: '20%'},
                        {label: 'Description', fieldName: namespaceVal+'Description__c', type: 'text' ,editable: true, wrapText: true, fixedWidth: '35%'},
                        {label: 'Resolution/Answer', fieldName: namespaceVal+'Resolution_Answer__c', type: 'text' ,editable: false, wrapText: true, isSortColumn: true},
                        {label: '', fieldName: '', type: 'text' ,editable: false, wrapText: true, fixedWidth: '3%'}
                    ]);
                }
                
                component.set('v.commentTag', resultMap.campaignRecord.Parking_Lot_Tag_Line__c);
                component.set('v.commentMessage', resultMap.campaignRecord.Parking_Lot_Message__c);
                component.set('v.eventName', resultMap.campaignRecord.Name);
                component.set('v.eventRecordId', resultMap.campaignRecord.Id);
                resultMap.sessionList[0].selected = true;
                component.set('v.session', resultMap.sessionList[0]);
                //component.set("v.selectedSessionId",resultMap.sessionList[0].Id);//commented 20201230 JL bug/fix#00601:Session Picklist
                component.set("v.selectedSessionId",resultMap.sessionList[0].recordId);//added 20201230 JL bug/fix#00601:Session Picklist
                component.set('v.types', resultMap.typeList);
                component.set('v.categories', resultMap.categoryList);
                //component.set('v.sessionList', resultMap.sessionList);//commented 20201230 JL bug/fix#00601:Session Picklist
                component.set('v.sessionList', resultMap.sessionWrapper);//added 20201230 JL bug/fix#00601:Session Picklist
                component.set('v.parkingLots', parkingLots);
                component.set("v.showSpinner", false);
                // console.log('parkingLots>>>'+JSON.stringify(parkingLots));
                //Empty Fields
                
                /* Updated [EVENT REFRESH FIXES] JaysonLabnao Feb072022 */
                // render table
                helper.renderTable(component);
            }	
            //Error
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = 'Error on Loading Parking lot page'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                this.showToast('Oops!', message, "error", "pester");
                component.set("v.showSpinner", false);
            }
        });
        
        $A.enqueueAction(action);
    },

    renderTable : function(component){
        let container = component.find('table-container');
        $A.createComponent(
            "c:compassTable",
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
    
    submitParkingLot : function(component, event, helper) {
        let action = component.get("c.createParkingLot");    
        
        action.setParams({
            eventId : component.get("v.eventRecordId"),
            session : component.get("v.selectedSessionId"),
            email : component.get("v.email"),
            phone : component.get("v.phone"),
            description : component.get("v.description"),
            type : component.get("v.type"),
            category : component.get("v.category")
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if (state === "SUCCESS") {
                //CCN-701 Apr.14.2022 - Updated the success message
                this.showToast('Success!', "Your Parking Lot item has been submitted.", "success", "pester");
                component.set("v.showSpinner", false);
                //Reset fields
                component.set("v.description","");
                component.set("v.type","");
                component.set("v.email","");
                component.set("v.category","");
                helper.doInitHelper(component,event,helper,null);
                
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = 'Error on Creating Parking Lot'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                this.showToast('Oops!', message, "error", "pester");
                component.set("v.showSpinner", false);
            }
                else {
                    this.showToast('Oops!', "Something's not right. Please contact the administrator for help.", "error", "pester");
                    component.set("v.showSpinner", false);
                }
        });
        
        $A.enqueueAction(action);
    },
    
    
    showToast : function(title, message, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type" : type,
            "mode" : mode
        });
        toastEvent.fire();
    },
    
    updateParkingLots : function(component, event, helper) {
        let action = component.get("c.updateParkingLots");    
        let draftValues = event.getParam('draftValues');
        action.setParams({
            parkingLots : JSON.stringify(draftValues)
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if (state === "SUCCESS") {
                this.showToast('Success!', "Your changes has been saved.", "success", "pester");
                component.set("v.showSpinner", false);
                helper.doInitHelper(component,event,helper,null,true);
                
                //$A.get('e.force:refreshView').fire();
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = 'Error on Updating Parking Lots'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                this.showToast('Oops!', message, "error", "pester");
                component.set("v.showSpinner", false);
            }
                else {
                    console.log("Failed with state: " + state);
                    this.showToast('Oops!', "Something's not right. Please contact the administrator for help.", "error", "pester");
                    component.set("v.showSpinner", false);
                }
        });
        
        $A.enqueueAction(action);
    },
    
    // Added by Jayson Labnao Jan082022 [CCN790,791,792-Parking Lot Table Fix]
    sortData : function(arr, columnToCompare){
        arr.sort(function(a, b){
            if ( a[columnToCompare] < b[columnToCompare] ){
                return -1;
            }
            if ( a[columnToCompare] > b[columnToCompare] ){
                return 1;
            }
            return 0;
        });
        
        return arr;
    }
    
    
    
})