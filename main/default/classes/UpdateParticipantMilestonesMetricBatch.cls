/*******************************************************************************
     * @author       Von Pernicia
     * @date         09/11/2023
     * @description  This will handle updating participant milestone metrics if more than 10k in a list
     * @revision     09/11/2023 - [CCN-3442] Von Pernicia: initial creation
*******************************************************************************/

global class UpdateParticipantMilestonesMetricBatch implements Database.Batchable<Participant_Milestone_Metric__c>, Database.Stateful {

    
    global String finalJourneyId;
    global List<Participant_Milestone_Metric__c> participantMilestoneMetricsList;

    global Iterable<Participant_Milestone_Metric__c> start(Database.BatchableContext BC)
    {   

        return participantMilestoneMetricsList;
    }

    global void execute(Database.BatchableContext BC, List<Participant_Milestone_Metric__c> participantMilestoneMetricsRecs)
    {

        Database.update(participantMilestoneMetricsRecs);
    }

    global void finish(Database.BatchableContext bc){
        
        UpdateCheckpointProgressQueueable checkpointProgressQueueable = new UpdateCheckpointProgressQueueable(finalJourneyId);
        Id jobPsa = System.enqueueJob(checkpointProgressQueueable);
    }

}