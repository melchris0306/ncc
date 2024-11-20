({
    doInit : function(component, event, helper){
        helper.getNavigatorDetails(component, event, helper);
    },

    liveCallClick : function(component, event, helper) {
        component.set('v.isLiveCallOpen', true);
    },

    closeLiveCall : function(component, event, helper){
        component.set('v.isLiveCallOpen', false);
    },
    
    scheduleCall : function(component, event, helper) {
        component.set('v.isScheduleCallOpen', true);
    },
    closeScheduleCall : function(component, event, helper){
        component.set('v.isScheduleCallOpen', false);
    },
})