trigger CommunicationRecipientTrigger on Communication_Recipient__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('CommunicationRecipientTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
       
        if(!CommunicationRecipientTriggerHandler.bPreventAI){
            CommunicationRecipientTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
            CommunicationRecipientTriggerHandler.bPreventAI = true;
        }
    }
    
}