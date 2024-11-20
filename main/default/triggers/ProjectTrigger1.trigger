/**
* @description Trigger for Object Project__c
* 
*           05/27/2021 - Christian Doctolero - Trigger creation
*           Trigger Handler class: ProjectTriggerHandler1
**/ 
trigger ProjectTrigger1 on Project__c (before insert, before update){
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('ProjectTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(Trigger.isBefore && Trigger.isInsert){ 
        System.debug('SHOCK REACTS');
        ProjectTriggerHandler1.onBeforeInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }  
    
    if(Trigger.isBefore && Trigger.isUpdate){
        System.debug('TriggerContext');
        ProjectTriggerHandler1.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
	/*
    if(Trigger.isAfter && Trigger.isInsert){
        ProjectTriggerHandler1.onAfterInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        ProjectTriggerHandler1.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isDelete){
        ProjectTriggerHandler1.onAfterDelete(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isDelete){
        ProjectTriggerHandler1.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isUndelete){
        ProjectTriggerHandler1.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }*/
}