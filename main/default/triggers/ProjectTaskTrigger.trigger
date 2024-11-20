/**
* @description Trigger for Object Project_Task__c
* 
*           05/12/2021 - Kyzer Buhay - Trigger creation
*           Trigger Handler class: ProjectTaskTriggerHandler
**/ 
trigger ProjectTaskTrigger on Project_Task__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('ProjectTaskTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(Trigger.isBefore && Trigger.isInsert){ 
        // Added by DinoBrinas Nov052021
        // @description: This is to prevent the recursive of the trigger
        if(!ProjectTaskTriggerHandler.bPreventBI){
            ProjectTaskTriggerHandler.bPreventBI = true;
            ProjectTaskTriggerHandler.onBeforeInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
        }
    }  
    
    if(Trigger.isBefore && Trigger.isUpdate){
        // Added by DinoBrinas Nov052021
        // @description: This is to prevent the recursive of the trigger
        if(!ProjectTaskTriggerHandler.bPreventBU){
            ProjectTaskTriggerHandler.bPreventBU = true;
            ProjectTaskTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
        }
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
        // Added by DinoBrinas Nov052021
        // @description: This is to prevent the recursive of the trigger
        if(!ProjectTaskTriggerHandler.bPreventAI){
            ProjectTaskTriggerHandler.bPreventAI = true;
            ProjectTaskTriggerHandler.onAfterInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
        }
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        // Added by DinoBrinas Nov052021
        // @description: This is to prevent the recursive of the trigger
        if(!ProjectTaskTriggerHandler.bPreventAU){
            ProjectTaskTriggerHandler.bPreventAU = true;
            ProjectTaskTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
        }
    }
    
    // UPDATED BY JC ESPINO [CAPM-PMG-579-DV] MAY192023 - added afterDelete process
    if(Trigger.isAfter && Trigger.isDelete){
        ProjectTaskTriggerHandler.onAfterDelete(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    /*
    if(Trigger.isBefore && Trigger.isDelete){
        ProjectTaskTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isUndelete){
        ProjectTaskTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }*/
}