/**
 * @description       : 
 * @author            : adavid@ulapp.co
 * @group             : 
 * @last modified on  : 05-30-2022
 * @last modified by  : adavid@ulapp.co
**/
@isTest 
public with sharing class TestFactory {
    private static Integer sobjectNumber = 1;
        
    public static String getRecordFakeId(Schema.SObjectType sObj){
      String result = String.valueOf(sobjectNumber++);
      return sObj.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
   	}
    
    // Create contact
    public static Contact createContact(String firstname, String lastname, String email){
        Contact newContact = new Contact();
        newContact.Firstname = firstname;
        newContact.Lastname = lastname;
        newContact.Email = email;
        newContact.Contact_Type__c = 'Client';
        insert newContact;
        return newContact;
    }
    
    // Create campaign
    public static Campaign createCampaign(String campaignName, String recordType){
        //Id recordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        Campaign newCampaign = new Campaign();
        newCampaign.Name = campaignName;
        //newCampaign.RecordTypeId = recordTypeId;
        newCampaign.IsActive = true;
        insert newCampaign;
        return newCampaign;
    }
    
    // Create Event
    public static Event__c createEvent(String EventName){
        Account acc = new Account(Name ='Test Acc');
       	insert acc;
        Campaign__c  campaignRec = new   Campaign__c();
        campaignRec.Account__c = acc.Id;
        campaignRec.Site_Picklist_Values__c = 'Site 1,Site 2,Site 3';
        insert campaignRec;
        
        Event__c newCampaign = new Event__c();
        newCampaign.Name = EventName;
        newCampaign.Campaign__c =campaignRec.Id;
        newCampaign.Site_Picklist_Values__c = 'Site 1,Site 2,Site 3';
        insert newCampaign;
        return newCampaign;
    }
    
    // Create Session
    public static Session__c createSession(String SessionName, String eventId){
        Session__c newCampaign = new Session__c();
        newCampaign.Name = SessionName;
        newCampaign.Event__c = eventId;
        insert newCampaign;
        return newCampaign;
    }
    
    // Create Participant
    public static Participant__c createParticipant(String campaignId, Contact cont){
        Participant__c cm = new Participant__c();
        cm.Event__c = campaignId;
        cm.Member_Contact__c = cont.Id;
        cm.Status__c = 'Invited';
        insert cm;
        return cm;
    }
    
    // Create survey
    public static Survey__c createSurvey(String campaignId, String surveyName){
        Survey__c newSurvey = new Survey__c();
        newSurvey.Event__c = campaignId;
        newSurvey.Name = surveyName;
        newSurvey.Active__c = true;
        insert newSurvey;
        return newSurvey;
    }
    
    // Create survey question
    public static Survey_Question__c createSurveyQuestion(String surveyId, String description, String type, Integer sortingOrder){
        Survey_Question__c newSQ = new Survey_Question__c();
        newSQ.Survey__c = surveyId;
        newSQ.Description__c = description;
        newSQ.Question_Type__c = type;
        newSQ.Sorting_Order__c = sortingOrder;
        insert newSQ;
        return newSQ;
    }
    
    // Create survey response
    public static Survey_Response__c createSurveyResponse(String campaignId, String surveyId, String accountId){
        Survey_Response__c newSR = new Survey_Response__c();
        newSR.Event__c = campaignId;
        newSR.Survey__c = surveyId;
        newSR.Account__c = accountId;
        insert newSR;
        return newSR;
    }
    
    // Create survey answer
    public static Survey_Answer__c createSurveyAnswer(String surveyResponseId, String question, String answer){
        Survey_Answer__c newSA = new Survey_Answer__c();
        newSA.Survey_Response__c = surveyResponseId;
        newSA.Question__c = question;
        newSA.Answer__c = answer;
        insert newSA;
        return newSA;
    }
    
    // create session participant
    public static List<Session_Participant__c> createSessionParticipants(Integer numOfRecords,String sessionId){
        List<Session_Participant__c> participants = new List<Session_Participant__c>();
        
        for(Integer i=0;i<numOfRecords;i++) {
            participants.add(new Session_Participant__c(Session__c=sessionId));
        }
        
        return participants;
    }

    // Get record type ID
    public static String getRecordTypeId(String recordTypeName, String SObjectName){
        RecordType recordType =  [SELECT Id FROM RecordType WHERE Name =: recordTypeName and SObjectType =: SObjectName LIMIT 1];
        return recordType.Id;
    }
    
    // Create content version 
    public static ContentVersion createContentVersion(String title, String description){
        ContentVersion cv = new ContentVersion();
        cv.Description = description;
        cv.Title = title;
        cv.PathOnClient = 'test';
        cv.VersionData = EncodingUtil.base64Decode('U29tZSBDb250ZW50');
        insert cv;
        return cv;
    }
    
    // Create content document link
    public static ContentDocumentLink createContentDocumentLink(String contentDocumentId, String linkedEntityId, String shareType, String visibility){
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = linkedEntityId;
        cdl.Visibility = visibility;
        cdl.ShareType = shareType;
        insert cdl;
        return cdl;
    }
    
    // Create content distribution
    public static ContentDistribution createContentDistribution(ContentVersion cv){
        ContentDistribution cd = new ContentDistribution();
        cd.Name = cv.Title;
        cd.ContentVersionId = cv.Id;
        cd.PreferencesAllowViewInBrowser= true;
        cd.PreferencesLinkLatestVersion=true;
        cd.PreferencesNotifyOnVisit=false;
        cd.PreferencesPasswordRequired=false;
        cd.PreferencesAllowOriginalDownload= true;
        insert cd;
        return cd;
    }
    
    // Create user
    public static User createInteralUser(String firstname, String lastname, String email, String profileName){
        Profile p = [SELECT Id FROM Profile WHERE Name =: profileName LIMIT 1];
        User u = new User();
        u.FirstName = firstname;
        u.LastName = lastname;
        u.Email = email;
        u.Username = email;
        u.Alias = firstname.charAt(0)+lastname;
        u.Email='standarduser@testorg.com';
        u.EmailEncodingKey='UTF-8';
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.ProfileId = p.Id;
        u.TimeZoneSidKey='America/New_York';
        insert u;
        return u;
    }
    
    // create person account
    public static Account createPersonAccount(String firstname, String lastname, String email){
        Account newPersonAccount = new Account();
        newPersonAccount.Firstname = firstname;
        newPersonAccount.Lastname = lastname;
        newPersonAccount.PersonEmail = email;
        insert newPersonAccount;
        return newPersonAccount;
    }

    // Create campaign member
    public static CampaignMember createCampaignMember(String campaignId, Contact cont){
        CampaignMember cm = new CampaignMember();
        cm.CampaignId = campaignId;
        cm.ContactId = cont.Id;
        cm.Status = 'Sent';
        insert cm;
        return cm;
    }
    
    public interface DataFactory{
        void make();
        void persist();
    }
    
    public class ParkingLotTestDataFactory implements DataFactory{
        Contact con;
        Event__c evt;
        Session__c sess;
        Parking_Lot__c pl;
        
        public void make(){
            OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
            EmailTemplate e = [SELECT ID FROM EmailTemplate WHERE DeveloperName='Closed_Parking_Lot_Email_Template' LIMIT 1];
            Compass_Setting__c setting = new Compass_Setting__c();
            setting.Name = 'Default Settings';
            setting.Email_Sender_Name__c = 'NAME';
            setting.Email_Template_Invitation_Id__c = e.Id;
            setting.Email_Template_Registration_Id__c = e.Id;
            setting.Email_Sender_Id__c = owea.Id;
            setting.Email_Template_Parking_Lot_Closed__c = e.id;
            setting.Email_Template_Parking_Lot_Open__c = e.id;
            setting.Default__c = true;
            insert setting;
            this.con = createContact('Test', 'Con', 'test@email.com');
            insert this.con;
            this.evt = createEvent('Test');
            insert this.evt;
            this.sess = createSession('Sess', this.evt.Id);
            insert this.sess;
            this.pl = createParkingLot(this.evt.Id, this.sess.Id, this.con.Id);
        }
        
        public void persist(){
            insert this.pl;
            
        }

        public Contact createContact(String firstname, String lastname, String email){
            Contact newContact = new Contact();
            newContact.Firstname = firstname;
            newContact.Lastname = lastname;
            newContact.Email = email;
            newContact.Contact_Type__c = 'Client';
            return newContact;
        }
        
        
        public Event__c createEvent(String EventName){
            Campaign__c  campaignRec = new   Campaign__c();
            Account acc = new Account(Name ='Test Acc');
       		insert acc;
            campaignRec.Account__c = acc.Id;
            insert campaignRec;
            
            Event__c newCampaign = new Event__c();
            newCampaign.Name = EventName;
            newCampaign.Campaign__c =campaignRec.Id;
            newCampaign.Event_Id__c = 'Test';
            newCampaign.Time_Zone__c = 'AEST';
            return newCampaign;
        }
        
        public Session__c createSession(String SessionName, String eventId){
            Session__c newCampaign = new Session__c();
            newCampaign.Name = SessionName;
            newCampaign.Event__c = eventId;
            newCampaign.IsActive__c = true ;
            newCampaign.Start_Date_Time__c = date.today();
            newCampaign.End_Date_Time__c = newCampaign.Start_Date_Time__c.addHours(1);
            newCampaign.Time_Zone__c = 'AEST';
            return newCampaign;
        }
        
        public Parking_Lot__c createParkingLot(String eventId, String session, String raisedById){
            Parking_Lot__c newParkingLot = new Parking_Lot__c(
                Event__c = eventId,
                Session__c = session,
                Raised_By__c = raisedById,
                Description__c = 'Question 1',
                Status__c = 'Open',
                Type__c = 'Issue'
            );
            return newParkingLot;         
        }
        
        //usage
        // TestFactory.DataFactory df = new ParkingLotTestDataFactory();
        // df.make();
        // df.persist();
    }

    public class CloneSessionTestDataFactory implements DataFactory{

        Event__c e;
        public Session__c testSessionRec;

        public void make(){

            //Account
            Account testAccount2 = new Account();
            testAccount2.Name = 'Test Account 09252021';
            testAccount2.BillingStreet = '12345 Gold Street';
            testAccount2.BillingCity = 'Melbourne';
            testAccount2.BillingPostalCode = '3055';
            testAccount2.BillingState = 'VIC';
            testAccount2.BillingCountry = 'Australia';
            insert testAccount2;

            Compass_Setting__c compassSetting = new Compass_Setting__c(Domain_Name__c = 'https://dev3-nationalcoordinationcenter.cs90.force.com/Compass', Name = 'Default Settings');
            insert compassSetting;
            
            Campaign parentEvent = createCampaign('Parent Event 2', 'Event');
            parentEvent.Location__c = testAccount2.Id;
            parentEvent.Start_Date_Time__c = DateTime.newInstance(2020, 8, 29, 8, 30, 0);
            parentEvent.End_Date_Time__c = DateTime.newInstance(2020, 8, 31, 12, 30, 0);
            update parentEvent;
            
            Campaign childSession = createCampaign('Child Session 2', 'Session');
            childSession.ParentId = parentEvent.Id;
            childSession.Start_Date_Time__c = DateTime.newInstance(2020, 8, 29, 8, 30, 0);
            childSession.End_Date_Time__c = DateTime.newInstance(2020, 8, 29, 12, 30, 0);
            update childSession;
            
            Contact attendee = createContact('Test', 'Attendee2', 'test.attendee2@gmail.com');
            CampaignMember cm = createCampaignMember(parentEvent.Id, attendee);
        
            //Event
            this.e = createEvent('Test Event');
            
            //Event Role
            Event_Role__c newEventRole = new Event_Role__c();
            newEventRole.Show_in_Event_Site__c = true;
            newEventRole.Role__c = 'Speaker';
            newEventRole.Contact__c = attendee.Id;
            newEventRole.Event__c = this.e.Id;
            newEventRole.Campaign__c = childSession.Id;
            insert newEventRole;
            
            //Session
            this.testSessionRec = new Session__c();
            this.testSessionRec.Contact__c = attendee.Id;
            this.testSessionRec.Session__C = childSession.Id;
            this.testSessionRec.Event__c = this.e.Id;
            insert this.testSessionRec;
            
            //Session Role
            Session_Role__c sessRole = new Session_Role__c();
            sessRole.Role_Title__c = 'Test Role';
            sessRole.Role_Description__c = 'Test Role';
            sessRole.Number_of_Role__c = 1;
            sessRole.Session__c = this.testSessionRec.Id;
            insert sessRole;
            
            //Internal Session Role
            Internal_Resource_Role__c intRole = new Internal_Resource_Role__c();
            intRole.Session__c = this.testSessionRec.Id;
            insert intRole;
            
        }

        public void persist(){

            //Survey
            Survey__c newSurvey1 = createSurvey(this.e.Id, 'Test Survey With Event With No Selected Fields');
            createSurveyQuestion(newSurvey1.Id, 'What is your name?', 'Text', 1);
        }

    }

}