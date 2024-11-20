/*******************************************************************************************
  * @name: ONSEmailSenderControllerTest
  * @author: Paolo Quiambao
  * @created: 20-12-2021
  * @description: Test class to cover the ONSEmailSenderController Apex Class
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       		No.   Date(dd-mm-yyy) 	Author         	   	  Description
  *       		----  ---------------   --------------------  -----------------------------
  * @version    1.0   20-1-2021   		Paolo Quiambao        [CCN856] Initial version.
  *********************************************************************************************/
@isTest
public class ONSEmailSenderControllerTest {
    @testSetup 
    static void setupData() {
        Outreach_Notification__c outreachNotif = new Outreach_Notification__c(Name = 'Test', Description__c = 'Test');
        insert outreachNotif;
        
        Outreach_Notification_Setting__c ons = new Outreach_Notification_Setting__c(Name = 'Test', Description__c = 'Test', Type__c = 'Invitation Registration Reminder', Outreach_Notification__c = outreachNotif.Id, L1_Days__c = 1);
        insert ons;
    }
    
    @isTest
    static void getSelectedEmailTemplates_shouldReturnOrgWideAddresses_whenCalled() {
        Outreach_Notification_Setting__c ons = [SELECT Id FROM Outreach_Notification_Setting__c LIMIT 1];
        
        Test.startTest();
        PageReference pageRef = Page.ONSEmailSenderPage; 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', String.valueOf(ons.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ons);
        ONSEmailSenderController con = new ONSEmailSenderController(sc);
        List<SelectOption> selectOptionList = con.getSelectedOrgWideAddress();
        Test.stopTest();
        
        System.assertNotEquals(0, selectOptionList.size(), 'No Org Wide Addresses were returned');
    }
    
    @isTest
    static void save_shouldPopulateEmailSenderId_whenCalled() {
        Outreach_Notification_Setting__c ons = [SELECT Id FROM Outreach_Notification_Setting__c LIMIT 1];
        
        Test.startTest();
        PageReference pageRef = Page.ONSEmailSenderPage; 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', String.valueOf(ons.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ons);
        ONSEmailSenderController con = new ONSEmailSenderController(sc);
        con.orgWideAddress = String.valueOf([SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1].Id);
        con.save();
        Test.stopTest();
        
        Outreach_Notification_Setting__c onsUpdated = [SELECT Id, Email_Sender_Id__c FROM Outreach_Notification_Setting__c LIMIT 1];
        System.assertNotEquals(null, onsUpdated.Email_Sender_Id__c, 'Email Sender Id is not populated.');
    }
    
    @isTest
    static void testSaveWithException() {
        Outreach_Notification_Setting__c ons = [SELECT Id, Email_Sender_Id__c FROM Outreach_Notification_Setting__c LIMIT 1];
        
        Test.startTest();
        PageReference pageRef = Page.ONSEmailSenderPage; 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', String.valueOf(ons.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ons);
        ONSEmailSenderController con = new ONSEmailSenderController(sc);
        con.orgWideAddress = String.valueOf([SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1].Id);
        delete ons;
        con.save();
        Test.stopTest();
        
        System.assertEquals(null, ons.Email_Sender_Id__c, 'Method did not have an exception.');
    }
}