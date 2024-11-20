trigger ContactTrigger on Contact (before insert, before update) {
    if (Trigger.isBefore) {
        if(Trigger.isInsert) {
            ContactTriggerHandler.setUpNavigatorFields(trigger.new); 
        }  
        if(Trigger.isUpdate) {
            ContactTriggerHandler.setUpNavigatorFields(trigger.newMap, trigger.oldMap); 
        }   
    }
}