/*******************************************************************************************
  * @name: ONSEmailTemplateControllerTest
  * @author: Paolo Quiambao
  * @created: 21-12-2021
  * @description: Test class to cover the ONSEmailTemplateController Apex Class
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       		No.   Date(dd-mm-yyy) 	Author         	   	  Description
  *       		----  ---------------   --------------------  -----------------------------
  * @version    1.0   21-12-2021   		Paolo Quiambao        [CCN856] Initial version.
  *********************************************************************************************/
@isTest
public class ONSettingTriggerHandlerTest {
    @testSetup 
    static void setupData() {
        Outreach_Notification__c outreachNotif = new Outreach_Notification__c(Name = 'Test', Description__c = 'Test');
        insert outreachNotif;
    }
    
	@isTest
    static void onBeforeInsert() {
        Outreach_Notification__c outreachNotif = [SELECT Id FROM Outreach_Notification__c LIMIT 1];
        EmailTemplate em = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'Event Registration Reminder' LIMIT 1];
        
        Test.startTest();
        Outreach_Notification_Setting__c ons = new Outreach_Notification_Setting__c(Name = 'Test', Description__c = 'Test', Type__c = 'Invitation Registration Reminder', Outreach_Notification__c = outreachNotif.Id, L1_Days__c = 1);
        insert ons;
        Test.stopTest();
        
        Outreach_Notification_Setting__c onsUpdated = [SELECT Id, Email_Template_Id__c FROM Outreach_Notification_Setting__c LIMIT 1];
        System.assertEquals(em.Id, onsUpdated.Email_Template_Id__c, 'Email Template is not populated correctly.');
    }
    
    @isTest
    static void onBeforeUpdate() {
        Outreach_Notification__c outreachNotif = [SELECT Id FROM Outreach_Notification__c LIMIT 1];
        EmailTemplate em = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'Event Registration Reminder' LIMIT 1];
        Outreach_Notification_Setting__c ons = new Outreach_Notification_Setting__c(Name = 'Test', Description__c = 'Test', Type__c = 'Registration Confirmation Reminder', Outreach_Notification__c = outreachNotif.Id, L1_Days__c = 1);
        insert ons;
        
        Test.startTest();
        ons.Type__c = 'Invitation Registration Reminder';
        update ons;
        Test.stopTest();
        
        Outreach_Notification_Setting__c onsUpdated = [SELECT Id, Email_Template_Id__c FROM Outreach_Notification_Setting__c LIMIT 1];
        System.assertEquals(em.Id, onsUpdated.Email_Template_Id__c, 'Email Template is not populated correctly.');
    }
}