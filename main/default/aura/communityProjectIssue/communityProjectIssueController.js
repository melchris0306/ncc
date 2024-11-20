({
    doInit : function(component, event, helper) {    
        
       //Updated by MMallorca [CCN793,794,795] Oct192021 Add sortByValue param set null on load
        //helper.doInitHelper(component, event, helper, null);
        
        // Added by JaysonLabnao [Namespace Issue Fixes] August192022
        helper.initializePrefix(component, event, helper);

    },
    
    onClick : function(component, event, helper) {
        var navbar = component.find('myNavbar');
        $A.util.toggleClass(navbar, 'responsive');
    },
    
    //Added by MMallorca [CCN793,794,795] Oct192021 for sorting
    toggleFilter : function(component, event, helper) {  
        component.set("v.isFilter", !component.get("v.isFilter"));
    },
    handleSort : function(component, event, helper) {  
        console.log('handleSort');
        var sortByValue = component.get("v.sortByValue");
        console.log('sortByValue'+sortByValue);
        
       //Updated by MMallorca [CCN793,794,795] Oct192021 Add sortByValue param
       helper.doInitHelper(component, event, helper, sortByValue);  
    },
    
    handleSubmit : function(component, event, helper){
      
        /* CCN-EVE-2074-DV XEN REYES Oct2022 */
        let allValidContactUsForm = component.find('contactUsForm').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        //sessionInput
        let sessionInput = component.find('sessionInput');
        let fieldValiditySession = sessionInput.checkValidity();
        if(!fieldValiditySession) sessionInput.showHelpMessageIfInvalid();

        //typeInput
        let typeInput = component.find('typeInput');
        let fieldValidityType = typeInput.checkValidity();
        if(!fieldValidityType) typeInput.showHelpMessageIfInvalid();

        if (allValidContactUsForm && fieldValiditySession && fieldValidityType){
            component.set("v.showSpinner", true);
            helper.submitParkingLot(component, event, helper);
        } 

    },
   
    handleSaveItems : function(component, event, helper){
        //helper.updateParkingLots(component, event, helper);
    },

   handleSessionChange : function(component, event, helper){
        let sessionId = component.find("sessionInput").get("v.value");
        let sessionList = component.get("v.sessionList");
    //value = component.find("sessionInput").get("v.value"),
    //20201230 JL bug fix#00601:Session Picklist
    ////START
    /*
        let index = sessionList.findIndex(item => item.Id == sessionId);
    	let session = index >= 0? sessionList[index]: null;
    */    
        let index = sessionList.findIndex(item => item.recordId == sessionId);
    	let session = index >= 0? sessionList[index]: null;
	////END
        component.set("v.session",session);
        component.set("v.selectedSessionId",sessionId);
    }

    
})