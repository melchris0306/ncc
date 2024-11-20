trigger SurveyResponseTrigger on Survey_Response__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('SurveyResponseTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
       
        if(!SurveyResponseTriggerHandler.bPreventAI){
            SurveyResponseTriggerHandler.onAfterInsert(Trigger.new);
            SurveyResponseTriggerHandler.bPreventAI = true;
        }
    }
}