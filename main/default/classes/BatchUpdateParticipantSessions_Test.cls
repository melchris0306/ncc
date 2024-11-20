/*******************************************************************************************************
* Class Name        : BatchUpdateParticipantSessions_Test
* Description       : Test class for BatchUpdateParticipantSessions
* Author            : RLugpatan
* Created On        : 07/01/2022
* Modification Log  :
* -----------------------------------------------------------------------------------------------------
* Developer             Date            Modification ID     Description
* -----------------------------------------------------------------------------------------------------
* RLugpatan             07/01/2022      1000                Initial version - CCN-EVE-1827-DV
******************************************************************************************************/
@isTest
public class BatchUpdateParticipantSessions_Test {
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
            
            //Campaign  
            Campaign__c campaignRecord = new Campaign__c();
            campaignRecord.Name = 'Test Campaign';
            insert campaignRecord;
            
            OrgWideEmailAddress owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Edera' LIMIT 1];
            
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
            sessionRecord.Start_Date_Time__c = System.today();
            sessionRecord.End_Date_Time__c = System.today() + 1;            
            sessionRecord.Time_Zone__c = 'EDT'; 
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
        }
    }
    
    @isTest
    static void testUpdateMissedStatuses() {
        //BatchUpdateParticipantSessions  batchObj = new  BatchUpdateParticipantSessions ();
        //Id batchProcessId = Database.executeBatch(batchObj,100);
        Test.StartTest();
		BatchUpdateParticipantSessions testsche = new BatchUpdateParticipantSessions();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
    }
    
}