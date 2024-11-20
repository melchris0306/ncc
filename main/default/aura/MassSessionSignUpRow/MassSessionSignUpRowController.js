({
    doInit : function(component, event, helper) {

        //XEN REYES March 5, 2023 CCN-EVE-2631-DV
        helper.getRankOptions(component, event, helper);
        //helper.doInitHelper(component, event, helper);
    },
    
    handleRankChange : function(component, event, helper) {
        
        //XEN REYES March 5, 2023 CCN-EVE-2631-DV
        /* var selectedRankId = event.getSource().get("v.value");
        var rankOptions = component.get("v.optionsRank"); */

        let rank =  event.getSource().get("v.value");
        const rankArray = rank.split("|");

        let sessionPart = component.get("v.sessionPart");
        //Mel Mallorca CCN-EVE-3304-DV
        sessionPart.Rank = (rankArray[0] == '----' ? '' : rankArray[0]);
        sessionPart.BranchOfService = (rankArray.length >= 2 ? rankArray[1] : 'Other');
        
        console.log('sessionPart'+JSON.stringify(sessionPart));
        
        helper.handleFireEvent(component, event, helper);
    },
    
    handleFirstNameChange : function(component, event, helper) {
        helper.handleFireEvent(component, event, helper);
    },
    
    handleLastNameChange : function(component, event, helper) {
        helper.handleFireEvent(component, event, helper);
    },
    
    handleEmailChange : function(component, event, helper) {
        helper.handleFireEvent(component, event, helper);
    },

    handleRemove : function(component, event, helper) {
        helper.handleRemoveHelper(component, event, helper);
    },
})