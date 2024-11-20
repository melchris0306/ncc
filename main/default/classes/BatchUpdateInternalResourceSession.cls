/*******************************************************************************************************
* Class Name      	: BatchUpdateInternalResourceSession
* Description		: Batch Class to update Status field to Missed
* Author          	: DomGabutin
* Created On      	: 06/14/2023
* Modification Log	:
* -----------------------------------------------------------------------------------------------------
* Developer			  	Date			Modification ID		Description
* -----------------------------------------------------------------------------------------------------
* DomGabutin             06/14/2023			1000			Initial version - CCN-EVE-3064-DV
******************************************************************************************************/
public class BatchUpdateInternalResourceSession implements Database.Batchable<SObject>, Schedulable, Database.Stateful{
    
    public String strQuery = '';
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        List<String> lstStatuses = new List<String>{'Registered', 'Confirmed'};
            
        strQuery = 'SELECT Id, Resource_Session_Status__c, Session__r.Start_Date_Time__c, Session__r.End_Date_Time__c, Session__r.IsActive__c FROM Internal_Resource_Session__c '+
        'WHERE Resource_Session_Status__c IN: lstStatuses AND  Session__r.IsActive__c = TRUE ' +
        'AND (Session__r.Start_Date_Time__c = TODAY OR Session__r.End_Date_Time__c = TODAY)';
        
        System.debug(LoggingLevel.DEBUG, 'QUERY: ' + strQuery);
        
        return Database.getQueryLocator(strQuery);        
    }
    public void execute(Database.BatchableContext BC, List<SObject> scope){
        List<Internal_Resource_Session__c> lstInternalResourceSessions = (List<Internal_Resource_Session__c>)scope;
        List<Internal_Resource_Session__c> lstInternalResourceSessionsToUpdate = new List<Internal_Resource_Session__c>();
        system.debug('DOMS lstInternalResourceSessions ::: ' + lstInternalResourceSessions);
        if (!lstInternalResourceSessions.isEmpty()) {
            for(Internal_Resource_Session__c irs : lstInternalResourceSessions){
                irs.Resource_Session_Status__c = 'Missed';
                lstInternalResourceSessionsToUpdate.add(irs);
            }
            try {
                Database.update(lstInternalResourceSessionsToUpdate);
            } catch(Exception e) {
                
            }
        }
        
    }
    public void finish(Database.BatchableContext BC) {
    }

    public void execute(SchedulableContext sc) {
        BatchUpdateInternalResourceSession  batchObj = new  BatchUpdateInternalResourceSession ();
        Id batchProcessId = Database.executeBatch(batchObj,100);
    }

}