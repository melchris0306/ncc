trigger ReleaseItemTrigger on Release_Item__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {

    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('ReleaseItemTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(Trigger.isBefore && Trigger.isInsert){
        if(!ReleaseItemTriggerHandler.bPreventBI){
            ReleaseItemTriggerHandler.bPreventBI = true;
            ReleaseItemTriggerHandler.onBeforeInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
        }
    }  
    
    if(Trigger.isBefore && Trigger.isUpdate){
        if(!ReleaseItemTriggerHandler.bPreventBU){
            ReleaseItemTriggerHandler.bPreventBU = true;
            ReleaseItemTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
        }
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
        if(!ReleaseItemTriggerHandler.bPreventAI){
            ReleaseItemTriggerHandler.bPreventAI = true;
            ReleaseItemTriggerHandler.onAfterInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
        }
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        if(!ReleaseItemTriggerHandler.bPreventAU){
            ReleaseItemTriggerHandler.bPreventAU = true;
            ReleaseItemTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
        }
    }
    
	/*
    if(Trigger.isAfter && Trigger.isDelete){
    ReleaseItemTriggerHandler.onAfterDelete(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isDelete){
    ReleaseItemTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isUndelete){
    ReleaseItemTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }*/
}