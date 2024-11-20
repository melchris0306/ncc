/******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyyy)          Author                      Description
    *           ----  -----------------    -------------------       -----------------------------
    * @version   1.0  23-06-2022             Von Pernicia            [CCN-EVE-2390-DV] Intial Version. scheduler and batch job to send Event Delivery Confirmation
    ******************************************************************************/ 
global with sharing class BatchEventDeliveryConfirmation implements Database.Batchable<SObject>, Schedulable, Database.Stateful{

    public String strQuery;
    public String emailTemplateId;
    public Set<String> resourceIdList;
    public List<Batch_Processor__c> batchProcessorList = new List<Batch_Processor__c>();

    global void execute(SchedulableContext sc) {

        String finalResourceId ; 
        String queryString;
        Set<String> resourceIds = new Set<String>();
        
        
        List<Batch_Processor__c> batchList = [SELECT Id, Record_Id__c
        FROM Batch_Processor__c
        WHERE Type__c = 'BatchEventDeliveryConfirmation'];

        for (Batch_Processor__c batch: batchList) {

           
            if (!resourceIds.contains(batch.Record_Id__c) && batch.Record_Id__c != null) {
                if (String.isEmpty(finalResourceId)) {
                    finalResourceId = '\'' + batch.Record_Id__c + '\'';
                } else {
                    finalResourceId = finalResourceId + ',' + '\'' + batch.Record_Id__c + '\'';
                }
                resourceIds.add(batch.Record_Id__c);
            }
        }

        if (!batchList.isEmpty()) {
           
            queryString = ' SELECT Id, Contact__r.email, Event__r.Email_Sender_Id__c, Event__r.Do_Not_Send_Resource_Confirmation_Email__c ' +
            'FROM Internal_Resource__c ' +
            'WHERE Id in (' + finalResourceId + ')  ';
            
            system.debug('@@ queryString' + queryString);
            BatchEventDeliveryConfirmation batchObj = new BatchEventDeliveryConfirmation();
            batchObj.strQuery = queryString;
            batchObj.batchProcessorList = batchList;            
            Id batchProcessId = Database.executeBatch(batchObj,2000);
        }
    }
   
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        try {

            this.emailTemplateId = '';
         
            this.emailTemplateId = [SELECT Id 
                                    FROM EmailTemplate 
                                    WHERE DeveloperName = 'Event_Session_Delivery_Confirmation'].Id;

            return Database.getQueryLocator(this.strQuery);
        }catch(Exception e) {
            return null;
        }
    }

    global void execute(Database.BatchableContext BC, List<SObject> sessionRecord){
       
        List<Internal_Resource__c> irsList = (List<Internal_Resource__c>)sessionRecord;
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>(); 
        List<String> emailTo;
        for(Internal_Resource__c ir: irsList){
            if(!ir.Event__r.Do_Not_Send_Resource_Confirmation_Email__c){
                emailTo = new List<String>{ ir.Contact__r.email };

                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(this.emailTemplateId, null, ir.Id);
                message.setOrgWideEmailAddressId(ir.Event__r.Email_Sender_Id__c);
                message.setToAddresses(emailTo);
                message.setUseSignature(false); 
                message.setSaveAsActivity(false);

                emails.add(message);
            }
          
        }
       
        Messaging.sendEmail(emails);
    }

    global void finish(Database.BatchableContext BC) {
        
        if (!this.batchProcessorList.isEmpty()) {
            delete this.batchProcessorList;
        }
    }
}