trigger SurveyParticipantTrigger on Survey_Participant__c (before insert) {

    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('SurveyParticipantTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(Trigger.isBefore && Trigger.isInsert){
        SurveyParticipantTriggerHandler.onBeforeInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
}