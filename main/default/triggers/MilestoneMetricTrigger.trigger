/**
* @description Trigger for Milestone_Metric__c Object
* @revision
*           19.03.2021 - APRivera - Initial Creation
**/

trigger MilestoneMetricTrigger on Milestone_Metric__c (before insert, after insert, after update, after delete) {

    // After Events
    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            MilestoneMetricTriggerHandler.handleAfterInsert(Trigger.newMap);
        }else if(Trigger.isDelete){
            MilestoneMetricTriggerHandler.handleAfterDelete(Trigger.oldMap);
        }

    }

}