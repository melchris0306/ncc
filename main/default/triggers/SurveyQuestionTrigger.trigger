trigger SurveyQuestionTrigger on Survey_Question__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('SurveyQuestionTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(SurveyQuestionTriggerHandler.TriggerDisabled){
        return;
    }
    
    if(Trigger.isBefore && Trigger.isInsert){ 
        SurveyQuestionTriggerHandler.onBeforeInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }  
	
    if(Trigger.isBefore && Trigger.isUpdate){
        SurveyQuestionTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    /*
	if(Trigger.isAfter && Trigger.isInsert){
        ProjectTaskTriggerHandler.onAfterInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
	
    if(Trigger.isAfter && Trigger.isUpdate){
        ProjectTaskTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isDelete){
        ProjectTaskTriggerHandler.onAfterDelete(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isDelete){
        ProjectTaskTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isUndelete){
        ProjectTaskTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }*/
}