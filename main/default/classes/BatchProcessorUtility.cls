global class BatchProcessorUtility {

    global static void insertBatchRecord(Map<String, List<String>> recordIdMap, String type, String triggerSource) {

        List<Batch_Processor__c> batchProcessorList = new List<Batch_Processor__c>();

        for (String journeyId: recordIdMap.keySet()) {

            for (String contactId: recordIdMap.get(journeyId)) {

                Batch_Processor__c batchProcessor = new Batch_Processor__c(
                    Record_Id__c = contactId,
                    Record_Id_2__c = journeyId,
                    Type__c = type,
                    Trigger_Source__c = triggerSource
                );

                batchProcessorList.add(batchProcessor);
            }
        }

        if (!batchProcessorList.isEmpty()) {
            insert batchProcessorList;
        }
    }

    //CCN-1551 XEN REYES 29 April 2022
    global static void insertBatchRecord(Set<String> recordIdSet, String type, String triggerSource,  String param1) {

        List<Batch_Processor__c> batchProcessorList = new List<Batch_Processor__c>();

        for (String recordId: recordIdSet) {

            Batch_Processor__c batchProcessor = new Batch_Processor__c(
                Record_Id__c = recordId,
                Type__c = type,
                Trigger_Source__c = triggerSource,
                Parameter_1__c = param1
            );

            batchProcessorList.add(batchProcessor);
        }

        if (!batchProcessorList.isEmpty()) {
            insert batchProcessorList;
        }
    }

}