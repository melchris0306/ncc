/*******************************************************************************************************
* Class Name      	: BatchUpdateParticipantSessions
* Description		: Batch Class to update Status field to Missed
* Author          	: RLugpatan
* Created On      	: 07/01/2022
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  	Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* RLugpatan             07/01/2022		1000				Initial version - CCN-EVE-1827-DV
******************************************************************************************************/
public class BatchUpdateParticipantSessions implements Database.Batchable<SObject>, Schedulable, Database.Stateful{

    public String strQuery = '';
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        List<String> lstStatuses = new List<String>{'Registered', 'Confirmed'};
        strQuery = 'SELECT Id, Status__c, Session__r.Start_Date_Time__c, Session__r.End_Date_Time__c, Session__r.IsActive__c FROM Session_Participant__c '+
            'WHERE Status__c IN: lstStatuses AND  Session__r.IsActive__c = TRUE ' +
            'AND (Session__r.Start_Date_Time__c = TODAY OR Session__r.End_Date_Time__c = TODAY)';
        System.debug(LoggingLevel.DEBUG, 'QUERY: ' + strQuery);
        return Database.getQueryLocator(strQuery);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        List<Session_Participant__c> lstPartipantSessions = (List<Session_Participant__c>)scope;
        List<Session_Participant__c> lstPartipantSessionsToUpdate = new List<Session_Participant__c>();
        if (!lstPartipantSessions.isEmpty()) {
            for(Session_Participant__c sp : lstPartipantSessions){
                sp.Status__c = 'Missed';
                lstPartipantSessionsToUpdate.add(sp);
            }
            try {
                Database.update(lstPartipantSessionsToUpdate);
            } catch(Exception e) {
                system.debug('Error :: '+e.getMessage());
                system.debug('Error :: '+e.getStackTraceString());
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
    }

    public void execute(SchedulableContext sc) {
        BatchUpdateParticipantSessions  batchObj = new  BatchUpdateParticipantSessions ();
        Id batchProcessId = Database.executeBatch(batchObj,100);
    }
}