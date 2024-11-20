/**
 * Created by angelorivera on 4/1/2022.
 */

trigger ParticipantMilestoneMetricTrigger on Participant_Milestone_Metric__c (after update) {
    // After Events
    if (Trigger.isAfter) {
        if(Trigger.isUpdate) {
            ParticipantMilestoneMetricTriggerHandler.handleAfterUpdate(Trigger.newMap);
        }

    }
}