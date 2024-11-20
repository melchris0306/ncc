/**
* @description Trigger for Journey_Participant__c Object
* @revision
*           10.09.2020 - APRivera - Initial Creation
**/

trigger JourneyParticipantTrigger on Journey_Participant__c (after insert) {

    // After Events
    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            JourneyParticipantTriggerHandler.handleAfterInsert(Trigger.newMap);
        }
    }
}