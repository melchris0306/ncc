/**
* @description Trigger for Milestone__c Object
* @revision
*           10.09.2020 - APRivera - Initial Creation
**/

trigger MilestoneTrigger on Milestone__c (after insert, after update, before update, before delete) {

    // Before Events
    if (Trigger.isBefore) {
        if(Trigger.isDelete){
            MilestoneTriggerHandler.handleBeforeDelete(Trigger.oldMap);
        }else if(Trigger.isUpdate){
            MilestoneTriggerHandler.handleBeforeUpdate(Trigger.newMap);
        }
    }

    // After Events
    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            MilestoneTriggerHandler.handleAfterInsert(Trigger.newMap);
        }else if(Trigger.isUpdate){
            MilestoneTriggerHandler.handleAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}