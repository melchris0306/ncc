({
    getEvents : function(component, event, helper) {
        let url_string = document.location.href;
        const urlParams = new URLSearchParams(url_string);
        const contactId = urlParams.get('contactId');

        const action = component.get('c.getEvents');
        action.setParams({ contactId });
        action.setCallback(this, function(response){
            const state = response.getState();
            if(state === 'SUCCESS'){
                let events = response.getReturnValue();
                // let eventsToDisplay = [];
                let missedEvents = [];
                let todaysEvents = [];
                let upcomingEvents = [];
                if(events){
                    events.forEach(function(item){                        
                        if(item.Start_Date_Time__c){
                            let eventStartDate = new Date(item.Start_Date_Time__c);
                            let formattedDate = $A.localizationService.formatDate(eventStartDate, "MMMM dd yyyy, hh:mm a");
                            item.Start_Date_Time__c = formattedDate;
                        }
                        if(item.End_Date_Time__c && item.Start_Date_Time__c){
                            const today = new Date();
                            today.setHours(0,0,0,0);
                            let eventStartDate = new Date(item.Start_Date_Time__c);
                            let eventEndDate = new Date(item.End_Date_Time__c);
                            let formattedDate = $A.localizationService.formatDate(eventEndDate, "MMMM dd yyyy, hh:mm a");
                            item.End_Date_Time__c = formattedDate;

                            eventStartDate.setHours(0,0,0,0);
                            eventEndDate.setHours(0,0,0,0);
                            if(today.valueOf() >= eventStartDate.valueOf() && today.valueOf() <= eventEndDate.valueOf()){
                                item.dateType = 'today';
                                todaysEvents.push(item);
                            }
                            else if(today.valueOf() > eventEndDate.valueOf()){
                                item.dateType = 'missed';
                                missedEvents.push(item);
                            }
                            else{
                                item.dateType = 'upcoming';
                                upcomingEvents.push(item);
                            }
                        }
                        // eventsToDisplay.push(item);
                    });

                    component.set('v.missedEvents', missedEvents);
                    component.set('v.todaysEvents', todaysEvents);
                    component.set('v.upcomingEvents', upcomingEvents);
                }
            }
            else{
                // TODO: Handle Error
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        $A.enqueueAction(action);
    },
    
    showToastError : function(message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "type" : "error",
            "message": message
        });
        toastEvent.fire();
    },

    logError : function(errors){
        if (errors) {
            if (errors[0] && errors[0].message) {
                // log the error passed in to AuraHandledException
                let errorMessage = "Error message: " + errors[0].message
                console.log(errorMessage);
                return errorMessage;
            }
            else{
                console.log("Unknown error", JSON.stringify(errors));
                return "Unknown error", JSON.stringify(errors);
            }
        } else {
        	console.log("Unknown error", JSON.stringify(errors));
            return "Unknown error", JSON.stringify(errors);
        }
	},
})