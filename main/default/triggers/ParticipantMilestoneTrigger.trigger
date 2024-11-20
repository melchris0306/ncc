/**
* @description Trigger for Milestone__c Object
* @revision
*           10.09.2020 - APRivera - Initial Creation
**/

trigger ParticipantMilestoneTrigger on Participant_Milestone__c (after insert) {
    // After Events
    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            ParticipantMilestoneTriggerHandler.handleAfterInsert(Trigger.newMap);
        }
    }
}