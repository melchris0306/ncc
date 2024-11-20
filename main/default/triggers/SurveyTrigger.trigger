trigger SurveyTrigger on Survey__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    //TriggerDispatcher.Run(new SurveyTriggerHandler());
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('SurveyTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(SurveyTriggerHandler.TriggerDisabled){
        return;
    }
    
    if(Trigger.isBefore && Trigger.isInsert){ 
        SurveyTriggerHandler.onBeforeInsert(Trigger.new, Trigger.newMap);
    }  
	
    if(Trigger.isBefore && Trigger.isUpdate){
        SurveyTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.newMap ,Trigger.old,Trigger.oldMap);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        SurveyTriggerHandler.syncSurveyRichTextFields(Trigger.newMap);
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