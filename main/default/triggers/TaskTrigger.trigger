trigger TaskTrigger on Task (before insert, before update, after insert, after update) {
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('TaskTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    new TaskTriggerHandler().execute();
}