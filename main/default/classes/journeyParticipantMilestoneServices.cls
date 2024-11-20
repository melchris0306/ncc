public without sharing class journeyParticipantMilestoneServices {
    /*******************************************************************************
     * @author       Minh Ma
     * @date         03/28/2021
     * @description  method used in updateParticipantMilestone Aura component
     * @return       strResult
     * @revision     03/28/2021 - Minh Ma - Created
     *               05/04/2021 - Kyzer Buhay - Updated - Commented hard coded contact Id in query line 59-61 Method: getParticipantMilestone
     *               14/01/2022 - Dino Brinas - Migrated the logic to BatchSyncParticipantMilestoneMetric to handle large data
     *               19/01/2022 - APR - Fixed Query to exclude completed metrics
     *               10/08/2022 - Von Pernicia [CCN-1984]: Updated query to fix timeout issue
     *               11/11/2022 - Von Pernicia [CCN-2288]: Added "Failed" as part of the filter criteria
     *******************************************************************************/

    /*********** Auto Populating Jouney Participant Milestone Mectrics ***********/
    @AuraEnabled
    public static String updateParticipantMilestoneMetrics(Id jIds) {
        String strResult = 'running';
        String finalJourneyId ;
        String queryString;
        Set<Id> listJIDs = new Set<Id>();
        listJIDs.add(jIds);
        finalJourneyId = String.valueof(jIds);

        List<AsyncApexJob> aJob= [
                    SELECT Id, Status, ApexClassID 
                    FROM AsyncApexJob 
                    WHERE ApexClass.Name = 'BatchSyncParticipantMilestoneMetric' AND Status not in ('Completed', 'Aborted', 'Failed')
                    ];

        if(aJob.isEmpty()) {
            queryString = ' SELECT Id, Name, Completion_Date__c, Metric_Used__c, Milestone__c, System_Generated__c, ' +
            'Milestone__r.Name, ' +
            'Milestone__r.Journey__c, ' +
            'Milestone__r.Journey__r.Journey__c, ' +
            'Milestone__r.MileStone__r.Related_RecordId__c, ' +
            'Milestone__r.MileStone__r.Name, ' +
            'Milestone__r.Milestone__c, ' +
            'Milestone__r.Milestone__r.Parent__c, ' +
            'Milestone__r.Contact__c, ' +
            'Milestone__r.Type__c, ' +
            'Milestone__r.Checkpoint__c, ' +
            'Milestone__r.Sort_Order__c, ' +
            'Milestone__r.Progress__c, ' +
            'Milestone__r.Checkpoint_Name__c, ' +
            'Milestone__r.Checkpoint_Progress__c ' +
            'FROM Participant_Milestone_Metric__c ' +
            'WHERE Milestone__r.Journey__r.Journey__c =  \'' + String.valueOf(jIds) + '\' ' +
            'AND Milestone__r.Is_Active__c = TRUE ' +
            'ORDER BY Milestone__r.Journey__c, Milestone__r.Contact__c, Milestone__r.Sort_Order__c ';
            

            BatchSyncParticipantMilestoneMetric batchObj = new BatchSyncParticipantMilestoneMetric();
            batchObj.strQuery = queryString;
            batchObj.journeyId = finalJourneyId;
            Id batchProcessId = Database.executeBatch(batchObj,2000);
            strResult = '';
        }
        return strResult;

    }
}