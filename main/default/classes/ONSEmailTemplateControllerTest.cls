/*******************************************************************************************
  * @name: ONSEmailTemplateControllerTest
  * @author: Paolo Quiambao
  * @created: 20-12-2021
  * @description: Test class to cover the ONSEmailTemplateController Apex Class
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       		No.   Date(dd-mm-yyy) 	Author         	   	  Description
  *       		----  ---------------   --------------------  -----------------------------
  * @version    1.0   20-12-2021   		Paolo Quiambao        [CCN856] Initial version.
  * 			2.0   28-12-2021		Paolo Quiambao		  [CCN-1062] Update test class for WF#3
  *********************************************************************************************/
@isTest
public class ONSEmailTemplateControllerTest {
    @testSetup 
    static void setupData() {
        Outreach_Notification__c outreachNotif = new Outreach_Notification__c(Name = 'Test', Description__c = 'Test');
        insert outreachNotif;
        
        List<Outreach_Notification_Setting__c> onsList = new List<Outreach_Notification_Setting__c>();
        onsList.add(new Outreach_Notification_Setting__c(Name = 'Test', Description__c = 'Test', Type__c = 'Invitation Registration Reminder', Outreach_Notification__c = outreachNotif.Id, L1_Days__c = 1));
        insert onsList;
    }
    
    @isTest
    static void getSelectedEmailTemplatesIRR_shouldReturnEmailTemplates_whenCalled() {
        Outreach_Notification_Setting__c ons = [SELECT Id FROM Outreach_Notification_Setting__c WHERE Type__c = 'Invitation Registration Reminder' LIMIT 1];
        
        Test.startTest();
        PageReference pageRef = Page.ONSEmailTemplatePage; 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', String.valueOf(ons.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ons);
        ONSEmailTemplateController con = new ONSEmailTemplateController(sc);
        List<SelectOption> selectOptionList = con.getSelectedEmailTemplates();
        Test.stopTest();
        
        System.assertNotEquals(0, selectOptionList.size(), 'No email templates were returned');
    }
    
    @isTest
    static void save_shouldPopulateEmaailTemplateId_whenCalled() {
        Outreach_Notification_Setting__c ons = [SELECT Id FROM Outreach_Notification_Setting__c LIMIT 1];
        
        Test.startTest();
        PageReference pageRef = Page.ONSEmailTemplatePage; 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', String.valueOf(ons.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ons);
        ONSEmailTemplateController con = new ONSEmailTemplateController(sc);
        con.emailTemplate = String.valueOf([SELECT Id FROM EmailTemplate WHERE Folder.Name = 'Compass' LIMIT 1].Id);
        con.save();
        Test.stopTest();
        
        Outreach_Notification_Setting__c onsUpdated = [SELECT Id, Email_Template_Id__c FROM Outreach_Notification_Setting__c LIMIT 1];
        System.assertNotEquals(null, onsUpdated.Email_Template_Id__c, 'Email Template Id is not populated.');
    }
}