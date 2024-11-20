trigger EventTrigger on Event__c (before insert, before update, after insert, after update) {

    Apex_Trigger_Switch__c toggle = Apex_Trigger_Switch__c.getInstance('EventTrigger');
    if(toggle != null && !toggle.Active__c){
        return;
    }
    
    CCEventTriggerHandler handler = new CCEventTriggerHandler();

	if(Trigger.isBefore){
		if(Trigger.isInsert) handler.OnBeforeInsert(Trigger.new);
		if(Trigger.isUpdate) handler.OnBeforeUpdate(Trigger.newMap, Trigger.oldMap);
	}
	
	if(Trigger.isAfter){
		if(Trigger.isInsert) handler.OnAfterInsert(Trigger.new);
		if(Trigger.isUpdate) handler.OnAfterUpdate(Trigger.newMap, Trigger.oldMap);
	}
    
}