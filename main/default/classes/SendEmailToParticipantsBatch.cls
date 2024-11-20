public class SendEmailToParticipantsBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    public String queryString;
    public final Id eventId;
    public final String status;
    public final String templateName;
    public Boolean reachedLimit = false;
    List<Id> processedList = new List<Id>();
    
    public SendEmailToParticipantsBatch(Id eventIdParam, String statusParam, String templateParam, List<Id> processedListParam){
        status = statusParam;
        eventId = eventIdParam;
        templateName = templateParam;
        processedList = processedListParam;
        
        System.debug(processedList);
        System.debug(eventId);
        System.debug(status);
        System.debug(templateName);
        
        if(!processedList.isEmpty() && processedList != null){
            if(status == 'None'){

                //CCN-1101 Xen Reyes Jan. 6, 2022
                /* queryString = 'Select Id, Status__c, Member_Contact__c, Member_Contact__r.Email, Event__c, Event__r.Email_Sender_Id__c FROM Participant__c WHERE Member_Contact__c != null AND ' +
                    'Member_Contact__r.Email != null AND Status__c != null AND Event__c =: eventId AND ID NOT IN: processedList LIMIT 5000'; */
                queryString = 'Select Id, Status__c, Member_Contact__c, Member_Contact__r.Email, Event__c, Event__r.Email_Sender_Id__c FROM Participant__c WHERE Member_Contact__c != null AND ' +
                    'Member_Contact__r.Email != null AND Status__c = null AND Event__c =: eventId AND ID NOT IN: processedList LIMIT 5000';    
            
            } else if(status == 'All'){ //CCN-1104 Xen Reyes Jan. 6, 2022
                queryString = 'Select Id, Status__c, Member_Contact__c, Member_Contact__r.Email, Event__c, Event__r.Email_Sender_Id__c FROM Participant__c WHERE Member_Contact__c != null AND ' +
                    'Member_Contact__r.Email != null AND Event__c =: eventId AND ID NOT IN: processedList LIMIT 5000';

            } else{
                queryString = 'Select Id, Status__c, Member_Contact__c, Member_Contact__r.Email, Event__c, Event__r.Email_Sender_Id__c FROM Participant__c WHERE Member_Contact__c != null AND ' +
                    'Member_Contact__r.Email != null AND Status__c != null AND Event__c =: eventId AND Status__c =: status AND ID NOT IN: processedList LIMIT 5000';
            }
        }else{
            if(status == 'None'){

                //CCN-1101 Xen Reyes Jan. 6, 2022
                /* queryString = 'Select Id, Status__c, Member_Contact__c, Member_Contact__r.Email, Event__c, Event__r.Email_Sender_Id__c FROM Participant__c WHERE Member_Contact__c != null AND ' +
                    'Member_Contact__r.Email != null AND Status__c != null AND Event__c =: eventId LIMIT 5000'; */

                queryString = 'Select Id, Status__c, Member_Contact__c, Member_Contact__r.Email, Event__c, Event__r.Email_Sender_Id__c FROM Participant__c WHERE Member_Contact__c != null AND ' +
                    'Member_Contact__r.Email != null AND Status__c = null AND Event__c =: eventId LIMIT 5000';
            
            } else if(status == 'All'){ //CCN-1104 Xen Reyes Jan. 6, 2022
                queryString = 'Select Id, Status__c, Member_Contact__c, Member_Contact__r.Email, Event__c, Event__r.Email_Sender_Id__c FROM Participant__c WHERE Member_Contact__c != null AND ' +
                    'Member_Contact__r.Email != null AND Event__c =: eventId LIMIT 5000';

            } else{
                queryString = 'Select Id, Status__c, Member_Contact__c, Member_Contact__r.Email, Event__c, Event__r.Email_Sender_Id__c FROM Participant__c WHERE Member_Contact__c != null AND ' +
                    'Member_Contact__r.Email != null AND Status__c != null AND Event__c =: eventId AND Status__c =: status LIMIT 5000';
            }
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        Boolean reachedLimitIn = false;
        //If scope is not empty
        if(!scope.isEmpty()){            
            // Create a master list to store the emails that we will send
            List<Messaging.SingleEmailMessage> masterListMails = new List<Messaging.SingleEmailMessage>();
            
            //Get Email template
            EmailTemplate emailTemp = [SELECT Id FROM EmailTemplate WHERE Name =: templateName LIMIT 1];
            Map<Id, OrgWideEmailAddress> orgWideEmail = new Map<Id, OrgWideEmailAddress>([SELECT Id,Address,DisplayName FROM OrgWideEmailAddress]);
            
            Map<Id, emailMessage> emToInsertMap = new Map<Id, emailMessage>();
            
            for(Participant__c partRec : (List<Participant__c>)scope){
                String emailSenderId = partRec.Event__r.Email_Sender_Id__c;
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
                
                /* Set list of peoples who should recieve an email
                List<String> sendTo = new List<String>();
                sendTo.add(partRec.Member_Contact__r.Email);*/
                
                email.setOrgWideEmailAddressId(orgWideEmail.get(emailSenderId).Id);
                email.setSaveAsActivity(false);
                email.setWhatId(partRec.Id);  
                email.setTemplateId(emailTemp.Id);
                //email.setSubject('Event Invitation Reminder');
                email.setTargetObjectId(partRec.Member_Contact__c);
                //email.setSenderDisplayName('Official Nitish Account');
                
                // Add your email address into the master list
                masterListMails.add(email);
                
                // if EnhancedEmail Perm is enabled, create an EmailMessage object
                EmailMessage emailMessage = new EmailMessage();
                emailMessage.status = '3'; // email was sent
                emailMessage.fromAddress = orgWideEmail.get(emailSenderId).Address; // from address
                emailMessage.subject = 'Event Invitation Reminder'; // email subject
                emailMessage.FromName = orgWideEmail.get(emailSenderId).DisplayName;
                // Contact, Lead or User Ids of recipients
                String[] toIds = new String[]{partRec.Member_Contact__c}; 
                emailMessage.toIds = toIds;
                // additional recipients who don’t have a corresponding contact, lead or user id in the Salesforce org (optional)
                emailMessage.toAddress = partRec.Member_Contact__r.Email;
                //emailMessage.istracked = true;
                emToInsertMap.put(partRec.Member_Contact__c,emailMessage);
            }
            
            try {
                Messaging.reserveSingleEmailCapacity(emToInsertMap.size());
            }catch (Exception e) {
                reachedLimit = true;
                reachedLimitIn = true;
            }
            
            if(!reachedLimitIn){
                System.debug('Emails: ' + masterListMails);
                System.debug('Original Part: ' + (List<Participant__c>)scope);
                
                //List<Task> taskToInsert = new List<Task>();
                
                //Set Contacts/Participants as processed before sending email
                for(Participant__c partRecord : (List<Participant__c>)scope){
                	processedList.add(partRecord.Id);
                }
                
                // Sends mass emails
                String emailErrorReport;
                Messaging.SendEmailError[] errors;
                Messaging.SendEmailResult[] results = Messaging.sendEmail(masterListMails,false);

                for( Messaging.SendEmailResult currentResult : results ) {
                    errors = currentResult.getErrors();
                    if( null != errors ) {
                        for( Messaging.SendEmailError currentError : errors ) {
                            emToInsertMap.remove(currentError.getTargetObjectId());
                        }
                    }
                }

                if(!emToInsertMap.isEmpty()){
                    insert emToInsertMap.values();
                    List<EmailMessageRelation> emrToInsert = new List<EmailMessageRelation>();
                    for(Id contactId : emToInsertMap.keySet()){
                        EmailMessageRelation emRec = new EmailMessageRelation();
                        emRec.EmailMessageId = emToInsertMap.get(contactId).Id;
                        emRec.RelationId = contactId;
                        emRec.RelationType = 'ToAddress';
                        emrToInsert.add(emRec);
                    }
                    if(!emrToInsert.isEmpty()){
                        insert emrToInsert;
                    }
                }
                
                //reachedLimit = true;
                if(Test.isRunningTest()){
                    reachedLimit = true;
                }
            }else{
                //Reschedule Batch or Do Nothing then resched on final
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){
        if(reachedLimit){
            SendEmailToParticipantsBatch batchClass = new SendEmailToParticipantsBatch(eventId,status,templateName,processedList);
            
            Datetime nowDate = DateTime.now();
            Time myTime = Time.newInstance(1, 1, 0, 0);
            DateTime dt = DateTime.newInstance(nowDate.date()+1, myTime);
            
            Long dt1Long = nowDate.getTime();
            Long dt2Long = dt.getTime();
            Long milliseconds = dt2Long - dt1Long;
            Long seconds = milliseconds / 1000;
            Long minutes = seconds / 60;
            
            System.debug('Next Sched: ' + nowDate.addMinutes(Integer.valueOf(minutes)));
            System.debug('Processed: ' + processedList);
            
            String cronID = System.scheduleBatch(batchClass, 'Re-Send Email to Participant: ' + Datetime.now(), Integer.valueOf(minutes), 100);
            //String cronID = System.scheduleBatch(batchClass, 'Re-Send Email to Participant: ' + Datetime.now(), 2, 1);
        }
    }
}