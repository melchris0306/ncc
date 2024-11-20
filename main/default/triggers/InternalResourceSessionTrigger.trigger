/******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyyy)          Author                      Description
    *           ----  -----------------    -------------------       -----------------------------
    * @version   1.0  20-06-2022                   JC Espino        [CCN-EVE-3072-DV] Intial Version. Trigger for Internal Resource Session Object.
    * @version   1.0  23-06-2022             Von Pernicia           [CCN-EVE-2390-DV] Added condition for isBefore
    ******************************************************************************/
trigger InternalResourceSessionTrigger on Internal_Resource_Session__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
	Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('InternalResourceSessionTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }

    if(Trigger.isAfter){
        if(!InternalResourceSessionTriggerHandler.bPreventAU && Trigger.isUpdate){
            InternalResourceSessionTriggerHandler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
            InternalResourceSessionTriggerHandler.bPreventAU = true;
        }

        if(!InternalResourceSessionTriggerHandler.bPreventAI && Trigger.isInsert){
            InternalResourceSessionTriggerHandler.onAfterInsert(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
            InternalResourceSessionTriggerHandler.bPreventAI = true;
        }
    }


    if(Trigger.isBefore){
        if(!InternalResourceSessionTriggerHandler.bPreventAU && Trigger.isUpdate){
            InternalResourceSessionTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
            InternalResourceSessionTriggerHandler.bPreventBU = true;
        }

        if(!InternalResourceSessionTriggerHandler.bPreventAI && Trigger.isInsert){
            InternalResourceSessionTriggerHandler.onBeforeInsert(Trigger.new, Trigger.newMap);
            InternalResourceSessionTriggerHandler.bPreventBI = true;
        }
    }
}