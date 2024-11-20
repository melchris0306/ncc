global class SchedBatSyncParticipantMilestoneMetric implements Schedulable {

    /*******************************************************************************
     * @author       Von Pernicia
     * @date         na
     * @description  method used in updateParticipantMilestone Aura component
     * @return       strResult
     * @revision     Na         - Von Pernicia: created classs to run sync base on Batch Processor object
     *               10/08/2022 - Von Pernicia [CCN-1984]: Updated query to fix timeout issue
     *               11/11/2022 - Von Pernicia [CCN-2288]: Added "Failed" as part of the filter criteria
     *******************************************************************************/
    global void execute(SchedulableContext ctx) {
        String finalJourneyId ;
        String finalContactId ; 
        String queryString;
        Set<String> journeyIds = new Set<String>();
        Set<String> contactIds = new Set<String>();

        // Start CCN-1984: Von Pernicia
        List<AsyncApexJob> aJob= [ 
                    SELECT Id, Status, ApexClassID 
                    FROM AsyncApexJob 
                    WHERE ApexClass.Name = 'BatchSyncParticipantMilestoneMetric' AND Status not in ('Completed', 'Aborted', 'Failed')
                    ];

        if(aJob.isEmpty()) {
        
            List<Batch_Processor__c> batchList = [SELECT Id, Record_Id__c, Record_Id_2__c
            FROM Batch_Processor__c
            WHERE Type__c = 'BatchSyncParticipantMilestoneMetric'];

            for (Batch_Processor__c batch: batchList) {

                //CCN-2303 XEN REYES Nov122022
                if (!journeyIds.contains(batch.Record_Id_2__c) && batch.Record_Id_2__c != null ) {
                    if (String.isEmpty(finalJourneyId)) {
                        finalJourneyId = '\'' + batch.Record_Id_2__c + '\'';
                    } else {
                        finalJourneyId = finalJourneyId + ',' + '\'' + batch.Record_Id_2__c + '\'';
                    }
                    journeyIds.add(batch.Record_Id_2__c);
                }

                //CCN-2303 XEN REYES Nov122022
                if (!contactIds.contains(batch.Record_Id__c) && batch.Record_Id__c != null) {
                    if (String.isEmpty(finalContactId)) {
                        finalContactId = '\'' + batch.Record_Id__c + '\'';
                    } else {
                        finalContactId = finalContactId + ',' + '\'' + batch.Record_Id__c + '\'';
                    }
                    contactIds.add(batch.Record_Id__c);
                }
            }

            if (!batchList.isEmpty()) {
                
                /*queryString = 'SELECT Id, Name, Journey__r.Journey__c, Journey__r.Contact__c, MileStone__r.Related_RecordId__c, MileStone__r.Name, Milestone__c, Milestone__r.Parent__c, Contact__c, Type__c, Checkpoint__c, Sort_Order__c, Progress__c, Checkpoint_Name__c, Checkpoint_Progress__c, ' +
                        '(SELECT Id, Name, Completion_Date__c, Metric_Used__c, Milestone__c, System_Generated__c FROM Participant_Milestone_Metrics__r WHERE Completion_Date__c = NULL) ' +
                        'FROM Participant_Milestone__c  ' +
                        'WHERE Journey__r.Journey__c in (' + finalJourneyId + ') AND ' +
                        'Journey__r.Contact__c in (' + finalContactId + ') ' +
                        'ORDER BY Journey__c, Contact__c, Sort_Order__c ';*/

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
                        'Milestone__r.Checkpoint_Progress__c, ' +
                        'Milestone__r.Parent_Milestone__c ' +
                        'FROM Participant_Milestone_Metric__c ' +
                        'WHERE Milestone__r.Journey__r.Journey__c in (' + finalJourneyId + ')  ' +
                        'AND Milestone__r.Journey__r.Contact__c in (' + finalContactId + ') ' +
            			'AND Milestone__r.Is_Active__c = TRUE ' + // CCN-2429 [01-01-2023]: Added new Parameter - Von Pernicia
                        'ORDER BY Milestone__r.Journey__c, Milestone__r.Contact__c, Milestone__r.Sort_Order__c ';
                system.debug('@@ queryString' + queryString);
                BatchSyncParticipantMilestoneMetric batchObj = new BatchSyncParticipantMilestoneMetric();
                batchObj.strQuery = queryString;
                batchObj.journeyIds = journeyIds;
                batchObj.finalContactId = finalContactId; // CCN-2429 [01-01-2023]: Added new Parameter - Von Pernicia
                batchObj.batchProcessorList = batchList; 
                Id batchProcessId = Database.executeBatch(batchObj,2000);

                // delete processed records from Batch processor
                //delete batchList;
                // End CCN-1984: Von Pernicia
            }
        }
    }
}