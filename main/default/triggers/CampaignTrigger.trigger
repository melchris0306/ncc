/*******************************************************************************************
  * @name: CampaignTrigger
  * @author: Minh
  * @created: 23-10-2021
  * @description: Campaign__c Trigger
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *            No.  Date(dd-mm-yyy) Author                Description
  *           ----  ---------       --------------------  -----------------------------
  * @version   1.0  23-10-2021       Minh                 Initial version.
  *********************************************************************************************/
 
trigger CampaignTrigger on Campaign__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){

    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('CampaignTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }
    
    if (trigger.isBefore && trigger.isInsert)
        CampaignTriggerHandler.onBeforeInsert( trigger.new, trigger.newMap, trigger.old, trigger.oldMap );
        
    if (trigger.isBefore && trigger.isUpdate )
        CampaignTriggerHandler.onBeforeUpdate( trigger.new, trigger.newMap, trigger.old, trigger.oldMap );
        
    if (trigger.isBefore && trigger.isDelete )
        CampaignTriggerHandler.onBeforeDelete( trigger.new, trigger.newMap, trigger.old, trigger.oldMap );
    
    if (trigger.isAfter && trigger.isInsert)
        CampaignTriggerHandler.onAfterInsert( trigger.new, trigger.newMap, trigger.old, trigger.oldMap );
        
    if (trigger.isAfter && trigger.isUpdate )
        CampaignTriggerHandler.onAfterUpdate( trigger.new, trigger.newMap, trigger.old, trigger.oldMap );
        
    if (trigger.isAfter && trigger.isDelete )
        CampaignTriggerHandler.onAfterDelete( trigger.new, trigger.newMap, trigger.old, trigger.oldMap );
        
    if (trigger.isAfter && trigger.isUnDelete )
        CampaignTriggerHandler.onAfterUndelete( trigger.new, trigger.newMap, trigger.old, trigger.oldMap );    
    
}