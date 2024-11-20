/*******************************************************************************
 * @author       Paolo Quiambao
 * @date         01.09.2021
 * @description  Batch class - sends Journey Outreach Reminder emails
 * @revision     01.09.2021 - Paolo Quiambao - Created
 * 				 16.12.2021 - Paolo Quiambao - [CCN-878] Add email sending for WF#2
 * 				 28.12.2021 - Paolo Quiambao - [CCN-1062] Add email sending for WF#3
 *******************************************************************************/
public class OutreachNotificationHistoryBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Updated by Paolo Quiambao [CCN-878] Dec172021
		String query = 'SELECT Id, Outreach_Notification_Setting__c, Notification_Type__c, Contact__c, Related_To__c, Schedule__c, Timezone__c, Outreach_Notification__c, Processed__c, Related_To_Id__c, Outreach_Notification_Setting__r.Email_Template_Id__c, Outreach_Notification_Setting__r.Email_Sender_Id__c FROM Outreach_Notification_History__c WHERE Schedule__c != null AND Processed__c = false LIMIT ' + Limits.getLimitQueryRows();
        
        try {
            return Database.getQueryLocator(query);
        }
        catch(Exception e) {
            return null;
        }
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> setOfRelatedIds = new Set<Id>();
        Set<Id> setOfRelatedIdsToSP = new Set<Id>();
        Set<Id> setOfRelatedIdsToSurvey = new Set<Id>();
        List<Outreach_Notification_History__c> onhList = (List<Outreach_Notification_History__c>)scope;
        List<Outreach_Notification_History__c> onhToUpdate = new List<Outreach_Notification_History__c>();
        List<Messaging.SingleEmailMessage> mailsToSend = new List<Messaging.SingleEmailMessage>();
        Map<String, Id> relatedIdToWhatIdMap = new Map<String, Id>();
        
        if(!onhList.isEmpty()) {
            for(Outreach_Notification_History__c onh : onhList) {
                if(Date.newInstance(onh.Schedule__c.year(), onh.Schedule__c.month(), onh.Schedule__c.day()) <= Date.Today()) {
                    // Updated by Paolo Quiambao [CCN-878] Dec162021
                    if(onh.Notification_Type__c.containsIgnoreCase('Session')) {
                        setOfRelatedIdsToSP.add(onh.Related_To_Id__c);
                    }
                    
                    // Updated by Paolo Quiambao [CCN-1062] Dec282021
                    else if(onh.Notification_Type__c.containsIgnoreCase('Survey')) {
                        setOfRelatedIdsToSurvey.add(onh.Related_To_Id__c);
                        system.debug('SURVEY SET ID>>>>     ' + onh);
                    }
                    else {
                        setOfRelatedIds.add(onh.Related_To_Id__c);
                    }
                }
            }
            
            for(Participant__c participant : [SELECT Id, Event__c, Member_Contact__c FROM Participant__c WHERE Event__c IN :setOfRelatedIds OR Event__c IN :setOfRelatedIdsToSurvey]) { 
                relatedIdToWhatIdMap.put(participant.Event__c + '|' + participant.Member_Contact__c, participant.Id);
            }
            
            for(Session_Participant__c sp : [SELECT Id, Session__c, Participant__c, Contact__c FROM Session_Participant__c WHERE Session__c IN :setOfRelatedIds OR Session__c IN: setOfRelatedIdsToSP]) { 
                // Updated by Paolo Quiambao [CCN-878] Dec162021
                if(setOfRelatedIdsToSP.contains(sp.Session__c)) {
                    relatedIdToWhatIdMap.put(sp.Session__c + '|' + sp.Contact__c, sp.Id);
                }
                else {
					relatedIdToWhatIdMap.put(sp.Session__c + '|' + sp.Contact__c, sp.Participant__c);
                }
            }
            
            // Updated by Paolo Quiambao [CCN-1062] Jan092022
            for(Survey_Participant__c surveyParticipant : [SELECT Id, Participant__c, Survey__c, Survey__r.Event__c FROM Survey_Participant__c WHERE Survey__c IN :setOfRelatedIdsToSurvey]) {
                relatedIdToWhatIdMap.put(surveyParticipant.Survey__c + '|' + surveyParticipant.Participant__c, surveyParticipant.Id);
                system.debug('SURVEY ID>>>>     ' + surveyParticipant.Survey__c);
                system.debug('CONTACT>>>>     ' + surveyParticipant.Participant__c);
                system.debug('SP>>>>>      ' + surveyParticipant.Id);
            }
            
            for(Outreach_Notification_History__c onh : onhList) {
                if(Date.newInstance(onh.Schedule__c.year(), onh.Schedule__c.month(), onh.Schedule__c.day()) <= Date.Today() && onh.Outreach_Notification_Setting__r.Email_Sender_Id__c != null && onh.Outreach_Notification_Setting__r.Email_Template_Id__c != null) {                    
                    system.debug('INSIDE ONH FOR LOOP>>>>    ' + onh);
                    system.debug('MAP GET>>>    ' + relatedIdToWhatIdMap.get(onh.Related_To_Id__c + '|' + onh.Contact__c));
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.setOrgWideEmailAddressId(onh.Outreach_Notification_Setting__r.Email_Sender_Id__c);
                    message.setSaveAsActivity(false);
                    message.setWhatId(relatedIdToWhatIdMap.get(onh.Related_To_Id__c + '|' + onh.Contact__c));
                    message.setTemplateId(onh.Outreach_Notification_Setting__r.Email_Template_Id__c);
                    message.setTargetObjectId(onh.Contact__c);
                    mailsToSend.add(message);
                    
                    onh.Processed__c = true;
                    onhToUpdate.add(onh);
                }
            }
            if(!Test.isRunningTest()){
                Messaging.sendEmail(mailsToSend);
                update onhToUpdate;
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }
}