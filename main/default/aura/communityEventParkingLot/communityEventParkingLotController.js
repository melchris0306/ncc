({
    /*******************************************************************************************
  * @name: toggleFilter
  * @author: Mel Mallorca
  * @created: 21-10-2021
  * @description: Toggle Filter when Sort Button is clicked
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       No.  Date(dd-mm-yyy) Author         Description
  *       ----  ---------   --------------------  -----------------------------
  * @version   1.0  21-10-2021   Mel Mallorca    [CCN790,791,792] Initial version.
  *********************************************************************************************/
    toggleFilter : function(component, event, helper) {  
        component.set("v.isFilter", !component.get("v.isFilter"));
    },
      
    /*******************************************************************************************
  * @name: handleSort
  * @author: Mel Mallorca
  * @created: 21-10-2021
  * @description: Sort Functionality
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       No.  Date(dd-mm-yyy) Author         Description
  *       ----  ---------   --------------------  -----------------------------
  * @version   1.0  21-10-2021   Mel Mallorca    [CCN790,791,792] Initial version.
  *********************************************************************************************/  
    handleSort : function(component, event, helper) {  
    
        // Updated by Jayson Labnao Jan082022 [CCN790,791,792-Parking Lot Table Fix]
        // console.log('handleSort');
        let sortByValue = component.get("v.sortByValue");
        // console.log('sortByValue'+sortByValue);
        
        // helper.doInitHelper(component, event, helper, sortByValue, false);  

        let parkingLots = component.get('v.parkingLots');
        let sortedArr = helper.sortData(parkingLots, sortByValue);
        if(sortedArr.length){
            component.set('v.parkingLots', sortedArr);
        }
    },
    
    doInit : function(component, event, helper) {
        helper.initializePrefix(component, event, helper);   
    },
    
    onClick : function(component, event, helper) {
        var navbar = component.find('myNavbar');
        $A.util.toggleClass(navbar, 'responsive');
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
        helper.updateParkingLots(component, event, helper);
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