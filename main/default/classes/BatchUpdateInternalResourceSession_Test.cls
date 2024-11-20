/*******************************************************************************************************
* Class Name        : BatchUpdateInternalResourceSession_Test
* Description       : Test class for BatchUpdateInternalResourceSession
* Author            : DomGabutin
* Created On        : 06/16/2023
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* RLugpatan             06/16/2023      1000                Initial version - CCN-EVE-3064-DV
******************************************************************************************************/
@isTest
public class BatchUpdateInternalResourceSession_Test {
    @testSetup static void setup() {
        User adminUser = TestFactory.createInteralUser('first','last','admin@compass.test.com','System Administrator');
        
        System.runAs(adminUser) {
            EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
            insert e;
            
            Compass_Setting__c compSetting = new Compass_Setting__c();
            compSetting.Name = 'Default Settings';
            compSetting.Email_Sender_Id__c = '123';
            compSetting.Email_Sender_Name__c = 'NAME';
            compSetting.Email_Template_Invitation_Id__c = e.Id;
            compSetting.Email_Template_Registration_Id__c = e.Id;
            insert compSetting;
            
            //Contact
            Contact contactRecord = new Contact();
            contactRecord.FirstName = 'Test Contact';
            contactRecord.LastName = 'Record 1';
            contactRecord.Email = 'testemail@testemail.com';
            insert contactRecord;
            
            Account account = new Account();
            account.name = 'Test Acc';
            insert account;
            
            //Campaign  
            Campaign__c campaignRecord = new Campaign__c();
            campaignRecord.Name = 'Test Campaign';
            campaignRecord.Account__c = account.Id;
            insert campaignRecord;
            
            OrgWideEmailAddress owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress /*WHERE DisplayName = 'National Coordination Center'*/ LIMIT 1];
            
            //Event
            Event__c eventRecord = new Event__c();
            eventRecord.Name = 'Test Event';
            eventRecord.Campaign__c = campaignRecord.Id;
            eventRecord.Email_Sender_Id__c = owea.Id;
            eventRecord.Email_Sender_Name__c = owea.DisplayName;
            insert eventRecord;
            
            //Session
            Session__c sessionRecord = new Session__c();
            sessionRecord.IsActive__c = TRUE;
            sessionRecord.Name = 'Test Session';
            sessionRecord.Event__c = eventRecord.Id;
            sessionRecord.Start_Date_Time__c = System.now();
            sessionRecord.End_Date_Time__c = System.now().addHours(2);
            sessionRecord.Time_Zone__c = 'PST';
            insert sessionRecord;
            
            
            //Session Participant
            Session_Participant__c sp = new Session_Participant__c();
            sp.Session__c = sessionRecord.Id;
            sp.Event__c = eventRecord.Id;
            sp.Contact__c = contactRecord.Id;
            sp.Status__c = 'Registered';
            sp.Invitation_Date__c = System.today();
            sp.Registration_Date__c = System.today();
            insert sp;
            
            //Internal Resource
            Internal_Resource__c ir = new Internal_Resource__c();
            ir.Contact__c = contactRecord.Id;
            ir.Event__c = eventRecord.Id;
            insert ir;
            
            //Internal Resource Participants
            Internal_Resource_Session__c irs = new Internal_Resource_Session__c();
            irs.Contact__c = contactRecord.Id;
            irs.Session__c = sessionRecord.Id;
            irs.Event__c = eventRecord.Id;
            irs.Resource_Session_Status__c = 'Registered';
            irs.Resource__c = ir.Id;
            insert irs;
        }
    }
    
    @isTest
    static void testUpdateMissedStatuses() {
        Test.StartTest();
		BatchUpdateInternalResourceSession testsche = new BatchUpdateInternalResourceSession();
		String sch = '0 30 23 * * ?';
		system.schedule('BatchUpdateInternalResourceSession', sch, testsche );
		Test.stopTest();
    }

}