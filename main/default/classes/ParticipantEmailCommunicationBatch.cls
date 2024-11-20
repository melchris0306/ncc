/*******************************************************************************************
* @name: ParticipantEmailCommunicationBatch
* @author: Xen Reyes
* @created: 24-01-2022
* @description: [CCN1139] This is batch to chunk sending out email everytime there is a event participant status change.
*
* Changes (version)
* -------------------------------------------------------------------------------------------
*        No.   Date(dd-mm-yyy) Author         Description
*        ----  ---------    --------------------  -----------------------------
* @version   1.0   24-01-2022    Xen Reyes          Initial version.
*********************************************************************************************/
public class ParticipantEmailCommunicationBatch implements Database.Batchable<sObject>{
    
    public String queryString;
    public Set<Id> participantIdsVar;
    public Set<Id> batchProcessorIdsVar;

    public ParticipantEmailCommunicationBatch(Set<Id> participantIds) {

        //CCN-1551 XEN REYES 29 April 2022
        /* participantIdsVar = participantIds;
        DescribeSObjectResult objDescribe = Participant__c.getSObjectType().getDescribe();
        List<String> fields = new List<String> (objDescribe.fields.getMap().keySet());
        queryString = 'SELECT ' + String.join(fields, ',') + ' FROM Participant__c WHERE Id IN: participantIdsVar'; */

        batchProcessorIdsVar = participantIds;
        DescribeSObjectResult objDescribe = Batch_Processor__c.getSObjectType().getDescribe();
        List<String> fields = new List<String> (objDescribe.fields.getMap().keySet());
        queryString = 'SELECT ' + String.join(fields, ',') + ' FROM Batch_Processor__c WHERE Id IN: batchProcessorIdsVar'; 
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        
        Set<Id> pptIds = new Set<Id>();

        //CCN-2304 XenReyes Nov122022
        for(Batch_Processor__c bp: (List<Batch_Processor__c>) scope) {
            if(bp.Record_Id__c != null) pptIds.add(bp.Record_Id__c);
        }

        Map<Id, Participant__c> pptMap = new Map<Id, Participant__c>([SELECT Id, Event__c, Member_Contact__c 
                                                                        FROM Participant__c 
                                                                        WHERE Id IN: pptIds
                                                                        AND Member_Contact__c != null
                                                                        AND Member_Contact__r.IsEmailBounced = false
                                                                        AND Member_Contact__r.Email != null]);

        Set<Id> eventIds = new Set<Id>();
        Map<String, List<Participant__c>> participantMap =  new Map<String, List<Participant__c>>();
        for(Batch_Processor__c bp: (List<Batch_Processor__c>) scope){
            if(!pptMap.containsKey(bp.Record_Id__c)) continue;
            Participant__c participant = pptMap.get(bp.Record_Id__c);
            if(participantMap.containsKey(bp.Parameter_1__c)){
                List<Participant__c> dataList = participantMap.get(bp.Parameter_1__c);
                dataList.add(participant);
                eventIds.add(participant.Event__c);
                participantMap.put(bp.Parameter_1__c, dataList);
            } else{
                eventIds.add(participant.Event__c);
                participantMap.put(bp.Parameter_1__c, new List<Participant__c>{participant});
            }
        }

        /* Set<Id> eventIds = new Set<Id>();
        Map<String, List<Participant__c>> participantMap =  new Map<String, List<Participant__c>>();
        for(Participant__c participant: (List<Participant__c>) scope){
            if(participantMap.containsKey(participant.Status__c)){
                List<Participant__c> dataList = participantMap.get(participant.Status__c);
                dataList.add(participant);
                eventIds.add(participant.event__c);
                participantMap.put(participant.Status__c, dataList);
            } else{
                eventIds.add(participant.event__c);
                participantMap.put(participant.Status__c, new List<Participant__c>{participant});
            }
        } */

        ParticipantTriggerUtility.sendEmailToParticipant(participantMap, eventIds);
        delete scope;
    }

    public void finish(Database.BatchableContext BC){
        
    }

}