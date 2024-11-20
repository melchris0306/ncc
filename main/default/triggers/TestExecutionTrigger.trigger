trigger TestExecutionTrigger on Test_Execution__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('TestExecutionTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(Trigger.isBefore && Trigger.isInsert){ 
        TestExecutionTriggerHandler.onBeforeInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }  
    
}