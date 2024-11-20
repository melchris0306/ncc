/*******************************************************************************************
* @name: BatchParticipantSendEmail
* @author: DinoBrinas
* @created: 01-02-2022
* @description: [CCN1153] This is batch to Send the Email
*
* Changes (version)
* -------------------------------------------------------------------------------------------
*           No.   Date(dd-mm-yyy)   Author                   Description
*           ----  ---------         --------------------    -----------------------------
* @version   1.0  01-02-2022        DinoBrinas               Initial version.
*********************************************************************************************/
global class BatchParticipantSendEmail implements Database.Batchable<SObject>, Database.Stateful{
    public String strQuery;
    public Map<Id, Event__c> eventsMap;
    public Map<Id, OrgWideEmailAddress> owea;
    public Compass_Setting__c compS;
    public Id eventRegistrationTemplate;
    public Set<Id> setParticipantIdstemp;
    public List<Participant__c> listParticipantRecords_UpdateSendEmailCheckbox = new List<Participant__c>();
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        try {
            Set<Id> setParticipantIds = this.setParticipantIdstemp;
            return Database.getQueryLocator(strQuery);
        }catch(Exception e) {
            return null;
        }
    }

    global void execute(Database.BatchableContext BC, List<SObject> objParticipantRecords){
        system.debug('REGISTERED!!!!! ');
        List<Participant__c> listParticipantRecords = (List<Participant__c>)objParticipantRecords;
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>(); 
        for(Participant__c participant: listParticipantRecords){
            if(!(this.eventsMap.get(participant.Event__c).Do_Not_Send_Event_Confirmation_email__c)){
                String emailTemplateId = this.compS.Email_Template_Registration_Id__c != null ? this.compS.Email_Template_Registration_Id__c : this.eventRegistrationTemplate;
                String emailSenderId = this.eventsMap.get(participant.Event__c).Email_Sender_Id__c;
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setOrgWideEmailAddressId(this.eventsMap.get(participant.Event__c).Email_Sender_Id__c);
                message.setSaveAsActivity(false);
                message.setWhatId(participant.Id);
                message.setTemplateId(emailTemplateId);
                message.setTargetObjectId(participant.Member_Contact__c);
                emails.add(message);
            }
            participant.Send_Event_Registration_Notification__c = false;
            listParticipantRecords_UpdateSendEmailCheckbox.add(participant);
        }
        Messaging.sendEmail(emails);
        
    }
    global void finish(Database.BatchableContext BC) {
        if(listParticipantRecords_UpdateSendEmailCheckbox <> null){
            update this.listParticipantRecords_UpdateSendEmailCheckbox;
        }
    }
}