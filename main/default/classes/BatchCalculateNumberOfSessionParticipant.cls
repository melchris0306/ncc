/******************************************************************************    
* Changes (version)
*            No.  Date(dd-mm-yyy) Author            Description
*           ----  ---------   --------------------  -----------------------------
* @version   1.0  07-29-2022   Rianno Rizarri       [CCN-EVE-1834-DV] This batch class will be used 1 time to calculate the number of participant per session.
*													This is due to the change of calculation of number of confirmed/registered participants
******************************************************************************/
public class BatchCalculateNumberOfSessionParticipant implements Database.Batchable<sObject>{
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        //Query registered and confirmed participant
        return Database.getQueryLocator([SELECT Id FROM Session__c WHERE Confirmed_Participants__c > 0 OR Registered_Participants__c > 0]);
    }
    
    public void execute(Database.BatchableContext BC, List<Session__c> sessionList){
        Set<Id> sessionIds = new Set<Id>();
        for(Session__c sesh : sessionList){
            sessionIds.add(sesh.Id);
        }
        List<Session__c> sessionWithParticipant = new List<Session__c>();
        //session is queried again with participant on execute to prevent 'INVALID_QUERY_LOCATOR' in Batch Apex
        //https://help.salesforce.com/s/articleView?id=000323582&type=1
        sessionWithParticipant = [SELECT Id, 
                                  (SELECT ID, Session_Start_Date__c, Registration_Date__c, Confirmed_Date__c FROM Session_Participants__r 
                                   WHERE Status__c IN('Registered', 'Confirmed'))
                                  FROM Session__c WHERE ID IN: sessionIds AND (Confirmed_Participants__c > 0 OR Registered_Participants__c > 0)];
        List<Session__c> sessionToUpdate = new List<Session__c>();
        for(Session__c sesh : sessionWithParticipant){
            //commented out due to FATAL_ERROR System.QueryException: Aggregate query has too many rows for direct assignment, use FOR loop
            //https://help.salesforce.com/s/articleView?id=000323566&type=1
            //if(sesh.Session_Participants__r.size() > 0){
            //if(sesh.Session_Participants__r != null){
            Integer participantNumber = 0;
            for(Session_Participant__c seshPart : sesh.Session_Participants__r){
                //Count only participants that are confirmed or registered before the start date.
                if(seshPart.Confirmed_Date__c <= seshPart.Session_Start_Date__c || seshPart.Registration_Date__c <= seshPart.Session_Start_Date__c){
                    participantNumber++;
                }
            }
            Session__c newSesh = new Session__c();
            newSesh.Id = Sesh.Id;
            newSesh.Total_Participants_Registered_New__c = participantNumber;
            if(participantNumber> 0){
                sessionToUpdate.add(newSesh);                
            }
        }
        if(sessionToUpdate.size() > 0){
            Update sessionToUpdate;
        }
        
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}