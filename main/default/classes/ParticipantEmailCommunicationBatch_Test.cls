/*******************************************************************************************
* @name: ParticipantEmailCommunicationBatch_Test
* @author: Xen Reyes
* @created: 24-01-2022
* @description: [CCN1139] Test class for ParticipantEmailCommunicationBatch
*
* Changes (version)
* -------------------------------------------------------------------------------------------
*        No.   Date(dd-mm-yyy) Author         Description
*        ----  ---------    --------------------  -----------------------------
* @version   1.0   24-01-2022    Xen Reyes          Initial version.
*********************************************************************************************/
@isTest
public class ParticipantEmailCommunicationBatch_Test {

    @testSetup
    static void createData(){
       OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        
        Apex_Trigger_Switch__c switchh = new Apex_Trigger_Switch__c();
        switchh.Name = 'ParticipantTrigger';
        switchh.Active__c = true;
        insert switchh;

        Campaign__c testCampaign = new Campaign__c();
        testCampaign.Name = 'Test Campaign Name';
        insert testCampaign;
        
        Contact testContact = new Contact();
        testContact.LastName = 'Test Contact';
        testContact.Email = 'test@email.com';
        insert testContact;
        
        Journey__c testJourney = new Journey__c();
        testJourney.Name = 'Test Journey';
        testJourney.Campaign__c = testCampaign.Id;
        testJourney.Status__c = 'Approved';
        insert testJourney;
        
        EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        system.runAs( new User(Id = UserInfo.getUserId())){
        	insert e;
        }
        
        
        Compass_Setting__c setting = new Compass_Setting__c();
        setting.Name = 'Default Settings';
        setting.Email_Sender_Name__c = 'NAME';
        setting.Email_Template_Invitation_Id__c = e.Id;
        setting.Email_Template_Registration_Id__c = e.Id;
        setting.Email_Sender_Id__c = owea.Id;
        insert setting;
        
        Apex_Trigger_Switch__c apexSwitch = TestDataFactory.createTriggerSwitch('EventTrigger');
        apexSwitch.Name = 'EventTrigger';
        insert apexSwitch;
        
        Event__c testEvent = new Event__c();
        testEvent.Campaign__c = [SELECT Id FROM Campaign__c LIMIT 1].Id;
        testEvent.Journey__c = [SELECT Id FROM Journey__c LIMIT 1].Id;
        testEvent.Milestone__c = true;
        testEvent.Email_Sender_Name__c = 'TEST 123';
        testEvent.Email_Message_CC__c = 'testMail@mail.com';
        testEvent.Email_Message_BCC__c = 'testMail@mail.com';
        testEvent.Email_Sender_Id__c = owea.Id;
        insert testEvent;
        
        List<Session__c> sessionList = new List<Session__c>();
        Session__c session1 = new Session__c();
        session1.Name = 'Test Session 001';
        session1.Event__c = testEvent.Id;
        session1.Start_Date_Time__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        session1.End_Date_Time__c = DateTime.newInstance(2020, 08, 29, 10, 30, 0);
        sessionList.add(session1);
        insert sessionList;
        
        Survey__c survey = new Survey__c();
        survey.Name = 'Test';
        survey.Event__c = testEvent.Id;
        insert survey;
        
        Participant__c participantData = new Participant__c();
        participantData.Event__c = testEvent.Id;
        participantData.Member_Contact__c = testContact.Id;
        participantData.Session_Modified__c = false;
        participantData.Status__c = '';
        insert participantData;
        
        Participant__c participantData1 = new Participant__c();
        participantData1.Event__c = testEvent.Id;
        participantData1.Member_Contact__c = testContact.Id;
        participantData1.Session_Modified__c = false;
        participantData1.Status__c = '';
        insert participantData1;
    }
    
    static testMethod void runInsertInvited(){
        List<Participant__c> participantList = new List<Participant__c>();
        Participant__c newparticipantData = new Participant__c();
        newparticipantData.Event__c = [SELECT Id FROM Event__c LIMIT 1].Id;
        newparticipantData.Member_Contact__c = [SELECT Id FROM Contact LIMIT 1].Id;
        newparticipantData.Session_Modified__c = false;
        newparticipantData.Status__c = 'Invited';
        participantList.add(newparticipantData);

		Participant__c newparticipantData1 = new Participant__c();
        newparticipantData1.Event__c = [SELECT Id FROM Event__c LIMIT 1].Id;
        newparticipantData1.Member_Contact__c = [SELECT Id FROM Contact LIMIT 1].Id;
        newparticipantData1.Session_Modified__c = false;
        newparticipantData1.Status__c = 'Invited';
        participantList.add(newparticipantData1);

	    insert participantList;
   
    }
    static testMethod void runInsertRegistered(){
        List<Participant__c> participantList = new List<Participant__c>();
        Participant__c newparticipantData = new Participant__c();
        newparticipantData.Event__c = [SELECT Id FROM Event__c LIMIT 1].Id;
        newparticipantData.Member_Contact__c = [SELECT Id FROM Contact LIMIT 1].Id;
        newparticipantData.Session_Modified__c = false;
        newparticipantData.Status__c = 'Registered';
        newParticipantData.Process_from_Event_Page__c = true;
        participantList.add(newparticipantData);

		Participant__c newparticipantData1 = new Participant__c();
        newparticipantData1.Event__c = [SELECT Id FROM Event__c LIMIT 1].Id;
        newparticipantData1.Member_Contact__c = [SELECT Id FROM Contact LIMIT 1].Id;
        newparticipantData1.Session_Modified__c = false;
        newparticipantData1.Status__c = 'Registered';
        newparticipantData1.Process_from_Event_Page__c = true;
        participantList.add(newparticipantData1);

	    insert participantList;
        
    }
    static testMethod void runUpdateInvited(){
        List<Participant__c> participantList = new List<Participant__c>();
        for(Participant__c par: [SELECT Id, Status__c, Session_Modified__c FROM Participant__c]){
            System.debug('@@@@@@@ test class' + par.Status__c);
            par.Status__c = 'Invited';
            par.Session_Modified__c = true;
            participantList.add(par);
        }
        if(!participantList.isEmpty()) update participantList;
    }
    static testMethod void runUpdateRegistered(){
        List<Participant__c> participantList = new List<Participant__c>();
        for(Participant__c par: [SELECT Id, Status__c, Session_Modified__c FROM Participant__c]){
            par.Status__c = 'Registered';
            par.Process_from_Event_Page__c = true;
            par.Session_Modified__c = true;
            participantList.add(par);
        }
        if(!participantList.isEmpty()) update participantList;
    }
    
    static testMethod void runUpdateRegisteredWithSessionParticipant(){
        List<Participant__c> participantList = new List<Participant__c>();
        
        Session__c session1 = [SELECT Id FROM Session__c LIMIT 1];
        Event__c event1 = [SELECT Id, Do_Not_Send_Event_Confirmation_Email__c FROM Event__c LIMIT 1];
        Contact con1 = [SELECT Id FROM Contact LIMIT 1];
        
        event1.Do_Not_Send_Event_Confirmation_Email__c = false;
        update event1;
        
        List<Participant__c> participantInsertList = new List<Participant__c>();
        Participant__c newparticipantData = new Participant__c();
        newparticipantData.Event__c = event1.Id;
        newparticipantData.Member_Contact__c =con1.Id;
        newparticipantData.Session_Modified__c = false;
        newparticipantData.Status__c = 'Invited';
        participantInsertList.add(newparticipantData);
        
        Participant__c newparticipantData2 = new Participant__c();
        newparticipantData2.Event__c = event1.Id;
        newparticipantData2.Member_Contact__c =con1.Id;
        newparticipantData2.Session_Modified__c = false;
        newparticipantData2.Status__c = 'Invited';
        participantInsertList.add(newparticipantData2);
        
        insert participantInsertList;
        
        List<Session_Participant__c> sessionParticipantList = new List<Session_Participant__c>();
        Session_Participant__c sp = new Session_Participant__c();
        sp.Session__c = session1.Id;
		sp.Event__c = event1.Id;
		sp.Contact__c = con1.Id;
        sp.Participant__c = newparticipantData.Id;
        sp.Status__c = 'Attended';
        sp.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp);
        
        Session_Participant__c sp2 = new Session_Participant__c();
        sp2.Session__c = session1.Id;
        sp2.Event__c = event1.Id;
        sp2.Contact__c = con1.Id;
        sp2.Participant__c = newparticipantData2.Id;
        sp2.Status__c = 'Attended';
        sp2.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp2.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp2);

        insert sessionParticipantList;
        
        system.debug('sessionParticipantList '+[SELECT Id,Event__r.Do_Not_Send_Event_Confirmation_email__c, Event__c,Status__c,
                            							Member_Contact__c, Process_from_Event_Page__c, 
                                                        (SELECT Id, Status__c FROM Session_Participants__r)
                            							FROM Participant__c 
                                                        WHERE Id = :newparticipantData.Id]);

        Test.startTest();
        List<Participant__c> tobeUpdatedParticipant = new List<Participant__c>();
        for(Participant__c p : participantInsertList) {
            p.Status__c = 'Registered';
            p.Process_from_Event_Page__c = false;
            tobeUpdatedParticipant.add(p);
        }
        update tobeUpdatedParticipant;
        system.assertEquals(tobeUpdatedParticipant.size(), 2);
        Test.stopTest();

        //if(!participantList.isEmpty()) update participantList;
    }
    
    static testMethod void runUpdateRegisteredWithoutSessionParticipant(){
        List<Participant__c> participantList = new List<Participant__c>();
        
        Session__c session1 = [SELECT Id FROM Session__c LIMIT 1];
        Event__c event1 = [SELECT Id FROM Event__c LIMIT 1];
        Contact con1 = [SELECT Id FROM Contact LIMIT 1];
        
        Participant__c newparticipantData = new Participant__c();
        newparticipantData.Event__c = event1.Id;
        newparticipantData.Member_Contact__c =con1.Id;
        newparticipantData.Session_Modified__c = false;
        newparticipantData.Status__c = 'Invited';
        insert newparticipantData;
        
        List<Session_Participant__c> sessionParticipantList = new List<Session_Participant__c>();
        Session_Participant__c sp = new Session_Participant__c();
        sp.Session__c = session1.Id;
		sp.Event__c = event1.Id;
		sp.Contact__c = con1.Id;
        sp.Participant__c = newparticipantData.Id;
        sp.Status__c = 'Attended';
        sp.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp);

        //insert sessionParticipantList;

        Test.startTest();
         	Participant__c tobeUpdatedParticipant = [SELECT Id, Status__c FROM Participant__c WHERE Id =: newparticipantData.Id];
         	tobeUpdatedParticipant.Status__c = 'Registered';
        	tobeUpdatedParticipant.Process_from_Event_Page__c = true;
        	update tobeUpdatedParticipant;
        Test.stopTest();

        //if(!participantList.isEmpty()) update participantList;
    }
    
     static testMethod void returnTrigger() {
         Session__c session1 = [SELECT Id FROM Session__c LIMIT 1];
         Event__c event1 = [SELECT Id FROM Event__c LIMIT 1];
         Contact con1 = [SELECT Id FROM Contact LIMIT 1];
         
         Apex_Trigger_Switch__c aps_sp = new Apex_Trigger_Switch__c();
         aps_sp.Name = 'ParticipantTrigger';
         aps_sp.Active__c = false;
         
         
         Participant__c participantData = new Participant__c();
         participantData.Event__c = event1.Id;
         participantData.Member_Contact__c = con1.Id;
         participantData.Status__c = 'Invited';
         
         
         Test.startTest();
         insert aps_sp;
         insert participantData;
         Test.stopTest();
     }
}