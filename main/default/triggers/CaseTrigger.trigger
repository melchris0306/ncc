trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('CaseTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }    
    if(Trigger.isAfter && Trigger.isUpdate){
        CaseTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
}