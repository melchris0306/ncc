({
    doInit : function(component, event, helper) {
        try{
            helper.setDefaultMonthDate(component);
            helper.getEvents(component, helper);
        }
        catch(e){
            console.error(e.message);
        }
    },

    handlePrevious : function(component, event, helper){
        helper.updateMonthDate(component, helper, -1);
    },

    handleNext : function(component, event, helper){
        helper.updateMonthDate(component,  helper, 1);
    },

})