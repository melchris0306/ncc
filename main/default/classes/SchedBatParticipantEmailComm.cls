global class SchedBatParticipantEmailComm implements Schedulable{

    global void execute(SchedulableContext ctx) {
        
        //CCN-1551 XEN REYES 29 April 2022
        /* Set<Id> pptIds = new Set<Id>();
        List<Batch_Processor__c> batchList = [SELECT Id, Record_Id__c
                                            FROM Batch_Processor__c
                                            WHERE Type__c = 'ParticipantEmailCommunicationBatch'];

        for (Batch_Processor__c batch: batchList) {
            pptIds.add(batch.Record_Id__c);
        }*/
        
        Map<Id, Batch_Processor__c> batchList = new Map<Id, Batch_Processor__c>([SELECT Id
                                            FROM Batch_Processor__c
                                            WHERE Type__c = 'ParticipantEmailCommunicationBatch']);

        if (!batchList.keySet().isEmpty()) {
            Database.executeBatch(new ParticipantEmailCommunicationBatch(batchList.keySet()), 20);

            // delete processed records from Batch processor 
            // delete batchList.values();
        }
    }
}