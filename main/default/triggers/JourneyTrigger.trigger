trigger JourneyTrigger on Journey__c (after insert) {

    if(Trigger.isInsert){
        if(Trigger.isAfter){
            JourneyTriggerHandler.populateJourneyURL(Trigger.new);
        }
        
    }
}