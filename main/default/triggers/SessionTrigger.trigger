/*******************************************************************************************
  * @name: SessionTrigger
  * @author: 
  * @created: XX-XX-XXXX
  * @description: Trigger for Session__c object
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *             No.   Date(dd-mm-yyy)   Author                Description
  *             ----  ---------------   --------------------  ---------------------------------
  * @version    1.0   XX-XX-XXXX                              Initial Creation
  *             1.1   27-08-2022        Rianno Rizarri        [CCN-EVE-1834-DV] Update to code standards
  *                                                           
  *********************************************************************************************/

trigger SessionTrigger on Session__c (before insert, before update, after update, after insert) {
    Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('SessionTrigger');
    if(switchh != null && !switchh.Active__c){
        return;
    }

    if(Trigger.isBefore && Trigger.isInsert){
        SessionTriggerHandler.onBeforeInsert(Trigger.new, Trigger.newMap);
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        SessionTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newmap,Trigger.old,Trigger.oldmap);
    }
    if(Trigger.isAfter && Trigger.isInsert){
        //Start CCN-EVE-1834-DV: Rianno Rizarri
        //Prevent recursion issue
        if(!SessionParticipantTriggerHandler.bPreventAI){
            SessionTriggerHandler.onAfterInsert(Trigger.new,Trigger.newmap,Trigger.old,Trigger.oldmap);
            SessionParticipantTriggerHandler.bPreventAI = true;
        }
        //Stop CCN-EVE-1834-DV: Rianno Rizarri
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        //Start CCN-EVE-1834-DV: Rianno Rizarri
        //Prevent recursion issue
        if(!SessionParticipantTriggerHandler.bPreventAU){
            SessionTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newmap,Trigger.old,Trigger.oldmap);
            SessionParticipantTriggerHandler.bPreventAU = true;
        }
        //Stop CCN-EVE-1834-DV: Rianno Rizarri
    }
}