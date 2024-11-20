/*******************************************************************************************
  * @name: CommunicationRecipientTriggerHandler
  * @author: Von Pernicia
  * @created: 03-02-2022
  * @description: Handler for all the logic of the trigger for the Communication Recipient object
*********************************************************************************************/
public class CommunicationRecipientTriggerHandler {

    public static boolean bPreventAI = false;
    public static boolean bPreventAU = false;

    /*******************************************************************************************
    * @author: Von Pernicia
    * @created: 03-02-2022
    * @description: logic after update
    *
    * Changes (version)
    * -------------------------------------------------------------------------------------------
    *             No.   Date(dd-mm-yyy)   Author                Description
    *             ----  ---------------   --------------------  ---------------------------------
    * @version    1.0   03-02-2022        Von Pernicia          [CCN-496] Consolidate list of journey upon populating Date Sent field to update Participant Milestone Metrics
     *********************************************************************************************/
    public static void onAfterUpdate(List<Communication_Recipient__c> newCommRecipientList, Map<Id,Communication_Recipient__c> newCommRecipientMap, 
                                     List<Communication_Recipient__c> oldCommRecipientList, Map<Id,Communication_Recipient__c> oldCommRecipientMap){

        List<Id> comRecList = new List<Id>();

        for (Communication_Recipient__c cr: newCommRecipientList) {
            comRecList.add(cr.id);
        }

        Map<String, List<String>> journeyIdMap = new Map<String, List<String>> ();
        for (Communication_Recipient__c cr: [SELECT id, Contact__c, CC_Communication__c, CC_Communication__r.Journey__c, Date_Sent__c
                                        FROM Communication_Recipient__c 
                                        WHERE id in: comRecList 
                                        AND Contact__c != NULL
                                        AND CC_Communication__r.Milestone__c = TRUE
                                        AND CC_Communication__r.Journey__c <> NULL
                                        AND Send_as__c = 'To']) //XEN REYES Mar 14, 2022 CCN-1004
        {
            if (newCommRecipientMap.get(cr.id).Date_Sent__c <> oldCommRecipientMap.get(cr.id).Date_Sent__c) {

                if (!journeyIdMap.containsKey(cr.CC_Communication__r.Journey__c)) {

                    List<String> contactIdList = new List<String>{ cr.Contact__c };
                    journeyIdMap.put(cr.CC_Communication__r.Journey__c, contactIdList);
                }
            }
        }
     
        if (journeyIdMap.size() > 0) {
            BatchProcessorUtility.insertBatchRecord(journeyIdMap, 'BatchSyncParticipantMilestoneMetric','CommunicationRecipientTriggerHandler');
        }  
        
       
        
    }
        
    
}