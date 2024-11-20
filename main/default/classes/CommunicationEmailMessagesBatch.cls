/*******************************************************************************************
* @name: CommunicationEmailMessagesBatch
* @author: Xen Reyes
* @created: 15-01-2022
* @description: [CCN1122] This is batch to chunk sending out email via the communication object
*
* Changes (version)
* -------------------------------------------------------------------------------------------
*        No.   Date(dd-mm-yyy) Author         Description
*        ----  ---------    --------------------  -----------------------------
* @version   1.0   15-01-2022    Xen Reyes          Initial version.
*********************************************************************************************/
public class CommunicationEmailMessagesBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    public String queryString;
    public Communication__c communicationRec;
    public String communicationRecId;
    public String communicationOrgWideEmail;
    public String errors = '';
    public Integer counter = 1;
    
    public CommunicationEmailMessagesBatch(Communication__c cons_communicationRec, String cons_communicationOrgWideEmail) {

        communicationRec = cons_communicationRec;
        communicationRecId = cons_communicationRec.Id;
        communicationOrgWideEmail = cons_communicationOrgWideEmail;

        DescribeSObjectResult objDescribe = Communication_Recipient__c.getSObjectType().getDescribe();
        List<String> fields = new List<String> (objDescribe.fields.getMap().keySet());
        
        //CCN-1004 Xen Reyes January 25, 2022
        queryString = 'SELECT ' + String.join(fields, ',') + ' FROM Communication_Recipient__c WHERE Send_as__c = \'To\' AND CC_Communication__c =: communicationRecId';
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){

        DescribeSObjectResult objDescribe = Communication__c.getSObjectType().getDescribe();
        List<String> fields = new List<String> (objDescribe.fields.getMap().keySet());
        String commsQueryString = 'SELECT ' + String.join(fields, ',') + ' FROM Communication__c WHERE Id =: communicationRecId';
        List<Communication__c> comsList = Database.query(commsQueryString);

        errors += CommunicationEmail_Controller.executeEmail(comsList[0], (List<Communication_Recipient__c>) scope, communicationOrgWideEmail, counter);
        counter++;
    }

    public void finish(Database.BatchableContext BC){
        
    }

}