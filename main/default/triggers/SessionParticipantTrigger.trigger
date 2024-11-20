trigger SessionParticipantTrigger on Session_Participant__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('SessionParticipantTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
        // @author: [CCN-1153] Updated by dinoBrinas
        // @description: This is used to avoid the recursive on the apex trigger.
        // @date: Jan282022
        if(!SessionParticipantTriggerHandler.bPreventAI){
            SessionParticipantTriggerHandler.onAfterInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
            SessionParticipantTriggerHandler.bPreventAI = true;
        }

        // Start CCN-2466 Von Pernicia: Added logic to create BatchProcessor Records
        SessionParticipantTriggerUtility.onAfterInsertSessionParticipant(Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        // @author: [CCN-1153] Updated by dinoBrinas
        // @description: This is used to avoid the recursive on the apex trigger.
        // @date: Jan282022
        if(!SessionParticipantTriggerHandler.bPreventAU){
            SessionParticipantTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
            SessionParticipantTriggerHandler.bPreventAU = true;
        }

        // Start CCN-2466 Von Pernicia: Added logic to create BatchProcessor Records
        SessionParticipantTriggerUtility.onAfterUpdateSessionParticipant(Trigger.new, Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isInsert){
        SessionParticipantTriggerHandler.onBeforeInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        SessionParticipantTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    /*
    if(Trigger.isBefore && Trigger.isInsert){
        SessionParticipantTriggerHandler.onBeforeInsert(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        SessionParticipantTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isBefore && Trigger.isDelete){
        SessionParticipantTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isDelete){
        SessionParticipantTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isUndelete){
        SessionParticipantTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }*/
}

/*trigger SessionParticipantTrigger on Session_Participant__c (after update, after insert) {
    Apex_Trigger_Switch__c sessionPartSwitch = Apex_Trigger_Switch__c.getInstance('SessionParticipantTrigger');
    
    if(sessionPartSwitch.Active__c){
        if(Trigger.isAfter && Trigger.isInsert){
            SessionParticipantTriggerHandler.sendCalendarInvite(Trigger.new,Trigger.newmap, Trigger.old,trigger.oldmap);
        }
    }
}

*/