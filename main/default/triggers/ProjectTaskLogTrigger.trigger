/**
* @description Trigger for Object Project_Task_Log__c
* 
*           06/30/2022 - Nikki Badilla - Trigger creation
*           Trigger Handler class: ProjectTaskLogTriggerHandler
**/ 
trigger ProjectTaskLogTrigger on Project_Task_Log__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('ProjectTaskLogTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
        if(!ProjectTaskLogTriggerHandler.bPreventAI){
            ProjectTaskLogTriggerHandler.bPreventAI = true;
            ProjectTaskLogTriggerHandler.onAfterInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
        }
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        if(!ProjectTaskLogTriggerHandler.bPreventAU){
            ProjectTaskLogTriggerHandler.bPreventAU = true;
            ProjectTaskLogTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
        }
    }
    /*
    if(Trigger.isAfter && Trigger.isDelete){
        ProjectTaskLogTriggerHandler.onAfterDelete(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isDelete){
        ProjectTaskLogTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isUndelete){
        ProjectTaskLogTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        ProjectTaskLogTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isInsert){
        ProjectTaskLogTriggerHandler.onBeforeInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }  
    */
}