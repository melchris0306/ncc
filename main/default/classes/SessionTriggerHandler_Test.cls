/*******************************************************************************************
 * @name: SessionTriggerHandler_Test
 * @author: 
 * @created: XX-XX-XXXX
 * @description: Handler for all the logic of the trigger for the Session object
 *
 * Changes (version)
 * -------------------------------------------------------------------------------------------
 *       		No.   Date(dd-mm-yyy) 	Author         	   	  Description
 *       		----  ---------------   --------------------  -----------------------------
 * @version    1.0	  XX-XX-XXXX							  Initial Creation
 *             2.0   29-10-2021   		Paolo Quiambao        [CCN745] Fix test class issues
 * 			3.0	  06-12-2021		Paolo Quiambao		  [CCN981] Update to cover changes
 * 														  for CCN981
 * 			4.0	  22-03-2022		Paolo Quiambao		  [CCN-934] Update Domain Name to Domain Name (Event Registration)
 *********************************************************************************************/
@isTest(SeeAllData = false)
public with sharing class SessionTriggerHandler_Test {

    // Updated by Paolo Quiambao [CCN-745] Oct292021
    @testSetup
    static void setup() {
        
        List < Apex_Trigger_Switch__c > atsList = new List < Apex_Trigger_Switch__c > ();
        Apex_Trigger_Switch__c aps_c = new Apex_Trigger_Switch__c();
        aps_c.Name = 'campaignTrigger';
        aps_c.Active__c = false;
        atsList.add(aps_c);

        Apex_Trigger_Switch__c aps_c2 = new Apex_Trigger_Switch__c();
        aps_c2.Name = 'SessionTrigger';
        aps_c2.Active__c = true;
        atsList.add(aps_c2);
        insert atsList;

        Contact con1 = new Contact();
        con1.FirstName = 'Test Contact';
        con1.LastName = 'Record 1';
        con1.Email = 'testemail@testemail.com';
        insert con1;

        Compass_Setting__c compSetting = new Compass_Setting__c();
        compSetting.Name = 'Default Settings';
        compSetting.Email_Sender_Id__c = '123';
        compSetting.Email_Sender_Name__c = 'NAME';
        insert compSetting;

    }

    @isTest
    static void testInsert() {
        Event__c evt = TestFactory.createEvent('Test');

        String inpputString = '2023-10-23T01:44:00.000Z';
        DateTime resultDateTime = DateTime.ValueofGmt(inpputString.replace('T', ' ')); 

        //with start and end
        List < Session__c > sessionList = new List < Session__c > ();
        Session__c newCampaign = new Session__c();
        newCampaign.Name = 'Test';
        newCampaign.Event__c = evt.Id;
        newCampaign.IsActive__c = true;
        newCampaign.Start_Date_Time__c = DateTime.Now();
        newCampaign.End_Date_Time__c = DateTime.Now().addHours(1);
        newCampaign.Time_Zone__c = 'AEST';
        sessionList.add(newCampaign);

        //with Start
        Session__c newCampaign2 = new Session__c();
        newCampaign2.Name = 'Test2';
        newCampaign2.Event__c = evt.Id;
        newCampaign2.IsActive__c = true;
        newCampaign2.Start_Date_Time__c = DateTime.Now();
        newCampaign2.End_Date_Time__c = DateTime.Now().addHours(1);
        newCampaign2.Time_Zone__c = 'AEST';
        sessionList.add(newCampaign2);

        //with End
        Session__c newCampaign3 = new Session__c();
        newCampaign3.Name = 'Test2';
        newCampaign3.Event__c = evt.Id;
        newCampaign3.IsActive__c = true;
        newCampaign3.Start_Date_Time__c = DateTime.Now();
        newCampaign3.End_Date_Time__c = DateTime.Now().addHours(1);
        newCampaign3.Time_Zone__c = 'AEST';
        sessionList.add(newCampaign3);

        //without Start and End
        Session__c newCampaign4 = new Session__c();
        newCampaign4.Name = 'Test2';
        newCampaign4.Event__c = evt.Id;
        newCampaign4.IsActive__c = true;
        newCampaign4.Start_Date_Time__c = DateTime.Now();
        newCampaign4.End_Date_Time__c = DateTime.Now().addHours(1);
        newCampaign4.Time_Zone__c = 'AEST';
        sessionList.add(newCampaign4);

        //with same start and end
        Session__c newCampaign5 = new Session__c();
        newCampaign5.Name = 'Test';
        newCampaign5.Event__c = evt.Id;
        newCampaign5.IsActive__c = true;
        newCampaign5.Start_Date_Time__c = resultDateTime;
        newCampaign5.End_Date_Time__c = resultDateTime.addHours(1);
        newCampaign5.Time_Zone__c = 'AEST';
        sessionList.add(newCampaign5);

        test.startTest();
        insert sessionList;
        test.stopTest();

        List < Session__c > results = [SELECT Id FROM Session__c];
        System.assert(!results.isEmpty());
    }

    @isTest
    static void testUpdate() {
        List < Session__c > eventList = new List < Session__c > ();
        List < Session__c > eventListUpdate = new List < Session__c > ();
        String inpputString = '2023-10-23T01:44:00.000Z';
        DateTime resultDateTime = DateTime.ValueofGmt(inpputString.replace('T', ' ')); 
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        Event__c evt = TestFactory.createEvent('Test');

        //[CCN-LOG-2217-DV] Xen Reyes 25Nov2022
        evt.Internal_Logistics_Required__c = true;
        update evt;

        for (Integer i = 0; i <= 100; i++) {
            Session__c newCampaign = new Session__c();
            newCampaign.Name = 'Test' + i;
            newCampaign.Event__c = evt.Id;
            newCampaign.IsActive__c = true;
            newCampaign.Start_Date_Time__c = resultDateTime;
            newCampaign.End_Date_Time__c = resultDateTime.addHours(1);
            newCampaign.Send_Updated_Calendar_Invite__c = false;
            newCampaign.Time_Zone__c = 'AEST';
            newCampaign.Meeting_URL__c = 'Meeting Location 1'; //[CCN-LOG-2217-DV] Xen Reyes 25Nov2022
            eventList.add(newCampaign);
        }
        insert eventList;

        // Updated by Paolo Quiambao [CCN-981] Dec062021
        List < Session_Participant__c > sessionParticipantList = new List < Session_Participant__c > ();
        Session_Participant__c sp = new Session_Participant__c();
        sp.Session__c = eventList[0].Id;
        sp.Event__c = evt.Id;
        sp.Contact__c = testContact.Id;
        sp.Status__c = 'Attended';
        sp.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp);

        insert sessionParticipantList;

        test.startTest();
        Integer i = 0;
        for (Session__c sessionRec: eventList) {
            i++;
            sessionRec.Name = 'Test Updated' + i;
            sessionRec.Start_Date_Time__c = DateTime.Now();
            sessionRec.End_Date_Time__c = DateTime.Now().addHours(1);
            sessionRec.Send_Updated_Calendar_Invite__c = true;
            sessionRec.Do_Not_Send_Calendar_Invite__c = false;
            sessionRec.Session_Catchup_Thank_You_Message__c = 'new message';
            sessionRec.Meeting_URL__c = 'Meeting Location 2'; //[CCN-LOG-2217-DV] Xen Reyes 25Nov2022
            eventListUpdate.add(sessionRec);
        }
        update eventListUpdate;

        test.stopTest();

        List < Session__c > results = [SELECT Id, Name FROM Session__c WHERE Name = 'Test Updated1'];
        System.assert(!results.isEmpty());
    }
}