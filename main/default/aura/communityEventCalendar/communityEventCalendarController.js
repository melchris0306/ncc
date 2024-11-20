({
    scriptsLoaded : function(component, event, helper) {
        helper.getEvents(component, event, helper, true);
        console.log('calendarButtons'+JSON.stringify(component.get("v.calendarButtons")));
    },
    
    refreshPage : function(component, event, helper){
        component.set('v.loaded',true);
        var delay=1500; // 1.5 seconds delay
        setTimeout(function() {
			$A.get('e.force:refreshView').fire();
    	}, delay);
        component.set('v.loaded',false);
    },

    /* Start CCN-EVE-3580-DV: Von Pernicia*/

    toggleFilter : function(component, event, helper){

        let isShowCard = component.get("v.isShowCard");
        let filterCard = component.find("filterCard");

        if (isShowCard) {
            component.set("v.isShowCard", false);
            $A.util.addClass(filterCard, "slds-hide")
        } else {
            component.set("v.isShowCard", true);
            $A.util.removeClass(filterCard, "slds-hide")
        }
    },

    onClickSelectedSession : function(component, event, helper){

        helper.selectedSession(component, event, helper);
    },

    onClickClearSelectedSession : function(component, event, helper) { 
        component.set("v.isShowCalendar", false);
        helper.clearSelectedSession(component, event, helper);    
        component.set("v.isShowCalendar", true);    
    },

    onChangeSearch : function(component, event, helper){
        helper.search(component, event, helper);
    },

    onClickApplyFilter : function(component, event, helper) {
        component.set("v.isShowCalendar", false);
        
        let filterCard = component.find("filterCard");
		$A.util.addClass(filterCard, "slds-hide");
        helper.applyFilter(component, event, helper);
        component.set("v.isShowCalendar", true);
    }
    /* End CCN-EVE-3580-DV: Von Pernicia*/
})