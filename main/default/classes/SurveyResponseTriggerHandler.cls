/*******************************************************************************************
  * @name: SessionTriggerHandler
  * @author: Von Pernicia
  * @created: 03-02-2022
  * @description: Handler for all the logic of the trigger for the Survey Response object
*********************************************************************************************/
public class SurveyResponseTriggerHandler {
    public static boolean bPreventAI = false;
    public static boolean bPreventAU = false;

    /*******************************************************************************************
    * @author: Von Pernicia
    * @created: 03-02-2022
    * @description: logic after insert
    *
    * Changes (version)
    * -------------------------------------------------------------------------------------------
    *             No.   Date(dd-mm-yyy)   Author                Description
    *             ----  ---------------   --------------------  ---------------------------------
    * @version    1.0   03-02-2022        Von Pernicia          [CCN-496] Consolidate list of journey upon creation of the record to update Participant Milestone Metrics
    *********************************************************************************************/
    public static void onAfterInsert(List<Survey_Response__c> newSurveryRespList){

            
        Map<String, List<String>> journeyIdMap = new Map<String, List<String>>();
       
        for (Adhoc_Journey_Assignment__c adhoc: [SELECT id, Journey__c 
                                                FROM Adhoc_Journey_Assignment__c 
                                                WHERE Event__c in (SELECT Event__c 
                                                                    FROM Survey_Response__c 
                                                                    WHERE Id in: newSurveryRespList 
                                                                    AND Contact__c != NULL 
                                                                    AND Survey__r.Milestone__c = TRUE)])

        {
            if (!journeyIdMap.containsKey(adhoc.Journey__c)) {
                List<String> contactIdList = new List<String>();
                for (Survey_Response__c participant: newSurveryRespList) {
                    contactIdList.add(participant.Contact__c);
                }
                journeyIdMap.put(adhoc.Journey__c, contactIdList);
            }
        }

        for (Adhoc_Journey_Assignment__c adhoc: [SELECT id, Journey__c 
                                                FROM Adhoc_Journey_Assignment__c 
                                                WHERE Survey__c in (SELECT Survey__c 
                                                                    FROM Survey_Response__c 
                                                                    WHERE Id in: newSurveryRespList 
                                                                    AND Contact__c != NULL 
                                                                    AND Survey__r.Milestone__c = TRUE)])

        {
            if (!journeyIdMap.containsKey(adhoc.Journey__c)) {
                List<String> contactIdList = new List<String>();
                for (Survey_Response__c participant: newSurveryRespList) {
                    contactIdList.add(participant.Contact__c);
                }
                journeyIdMap.put(adhoc.Journey__c, contactIdList);
            }
        }


        if (journeyIdMap.size() > 0) {
            BatchProcessorUtility.insertBatchRecord(journeyIdMap, 'BatchSyncParticipantMilestoneMetric','SurveyResponseTriggerHandler');
        }                          

    }
}