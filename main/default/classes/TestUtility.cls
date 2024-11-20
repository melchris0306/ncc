@isTest
public class TestUtility {
    
    public static Apex_Trigger_Switch__c createApexTriggerSwitch(String name, Boolean active){
        Apex_Trigger_Switch__c switchh = new Apex_Trigger_Switch__c();
        switchh.Name = name;
        switchh.Active__c = active;
        return switchh;
    }
    
    public static UserRole createUserRole(String name, String developerName){
        UserRole userRole = new UserRole(DeveloperName = developerName, Name = name);
        return userRole;
    }
    
    public static User createUser(Id userRoleId){
        User user = new User();
        user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        user.FirstName = 'First Name';
        user.LastName = 'Last Name';
        user.Email = 'firstname@alastname.com';
        user.Username = 'firstname@alastname.com' + System.currentTimeMillis();
        user.CompanyName = 'Company Name';
        user.Title = 'Title';
        user.Alias = 'FNLN';
        user.TimeZoneSidKey = 'America/New_York';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.LocaleSidKey = 'en_US';
        user.UserRoleId = userRoleId;
        return user;
    }
    
    public static Campaign__c createCampaign(String campaignName){
        Campaign__c campaign = new Campaign__c(Name = campaignName);
        return campaign;
    }
    
    public static Event__c createEvent(String eventName, Id campaignId, Datetime startDate, Datetime endDate){
        Event__c event = new Event__c();
        event.Name = eventName;                                                                           
        event.Campaign__c = campaignId;
        event.Event_Page_URL__c = 'https://dev3-nationalcoordinationcenter.cs90.force.com/Compass/s/events?id=TlGlcDDuY8B';
        event.Event_Id__c = 'TlGlcDDuY8B';                                                                             
        event.Milestone__c = false;                                                                                  
        event.Status__c = 'Planned';                                                                                   
        event.IsActive__c = false;                                                                                  
        event.Do_Not_Send_Event_Confirmation_email__c = false;                                                        
        event.Personalized_Event_Page_Login_Button__c = false;                                                         
        event.Event_Pages__c = 'Home';                                                                  
        event.Issue_Tracker_Page_Title__c = 'Issue Tracker';                                              
        event.Home_Page_Title__c = 'Home';                                      
        event.Survey_Page_Title__c = 'Survey';                                                                             
        event.Sessions_Page_Title__c = 'Sessions';                                                                           
        event.Contact_Us_Page_Title__c = 'Contact Us';                                                                      
        event.Materials_Page_Title__c = 'Materials';                                                                        
        event.Learn_More_Page_Title__c = 'Learn More';                                                                      
        event.Parking_Lot_Page_Title__c = 'Parking Lot';                                                                    
        event.Start_Date_Time__c = startDate;                                           
        event.End_Date_Time__c = endDate;                                           
        event.Time_Zone__c = 'HAST';                                     
        event.Email_Sender_Name__c = 'National Coordination Center';
        return event;
    }
    
    public static Session__c createSession(String sessionName, Id eventId, Id sessionLocationId, Datetime startDate, Datetime endDate){
        Session__c session = new Session__c();
        session.Name = sessionName;
        session.IsActive__c = true;                                          
        session.Event__c = eventId;                                       
        session.Milestone__c = false;                                      
        session.Start_Date_Time__c = startDate;
        session.End_Date_Time__c = endDate;
        session.Session_Details__c = 'Sep 03, 2021, 08:00 AM to 04:00 PM AFT';
        session.Time_Zone__c = 'AFT';
        session.Do_Not_Send_Calendar_Invite__c = false;                    
        session.Session_Location__c = sessionLocationId;
        return session;
    }
    
    public static Session_Role__c createSessionRole(String title, Id sessionId){
        Session_Role__c sessionRole = new Session_Role__c();
        sessionRole.Role_Title__c = title;
        sessionRole.Session__c = sessionId;
        sessionRole.Number_of_Role__c = 2;
        return sessionRole;
    }
    
    public static Session_Participant__c createSessionParticipant(Id eventId, Id sessionId, Datetime invitationDate, Datetime registrationDate){
        Session_Participant__c sessionParticipant = new Session_Participant__c();
        sessionParticipant.Status__c = 'Registered';                                    
        sessionParticipant.Invitation_Date__c = invitationDate;  
        sessionParticipant.Session__c = sessionId;                              
        sessionParticipant.Registration_Date__c = registrationDate;
        sessionParticipant.Event__c = eventId;                                       
        sessionParticipant.Sent_Calendar_Invite__c = false;     
        return sessionParticipant;
    }
    
    public static Session_Location__c createSessionLocation(String locationName){
        Session_Location__c sessionLocation = new Session_Location__c(Name = locationName);
        return sessionLocation;
    }
    
    public static Parking_Lot__c createParkingLot(Id eventId, Id sessionId){
        Parking_Lot__c parkingLot = new Parking_Lot__c();
        parkingLot.Event__c = eventId;       
        parkingLot.Session__c = sessionId;    
        parkingLot.Type__c = 'Issue';          
        parkingLot.Category__c = 'Feedback';        
        parkingLot.Description__c = 'Description';  
        parkingLot.Resolution_Answer__c = 'Answer';   
        parkingLot.Show_In_Status_Report__c = true; 
        parkingLot.Status__c = 'Open';
        return parkingLot;
    }
    Public static Account createAccRec(String accName){
        Account accRec = new Account();
        Id recordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        accRec.RecordTypeId = recordTypeId;
        accRec.Name = accName;
            
        return accRec;
    }
    Public static Contact createConRec(String conLastName, String AccId){
        Contact conRec = new Contact();
        conRec.LastName = 'TestUSer';
        conRec.AccountId = AccId;
        
        return conRec;
    }
    
    Public static Contact_Availability__c createConAvailabilityRec(String conId){
        Contact_Availability__c conAva = new Contact_Availability__c();
        conAva.Contact__c = conId;
        conAva.Start_Date_Time__c = System.now();
        conAva.End_Date_Time__c = System.now().addHours(1);
        conAva.Time_Zone__c = 'AKDT';
        
        return conAva;
    }
    /*Start - Gabriel Delavin - added as part of CON-SFVV-663-DV Test class*/
    Public static TeleMeet__c createTeleMeet(String conId){
        TeleMeet__c teleMeet = new TeleMeet__c();
        teleMeet.Contact__c = conId;
        teleMeet.Resource_Contact__c = conId;
        teleMeet.Start_Date_Time__c = System.now();
        teleMeet.End_Date_Time__c = System.now().addHours(1);
        teleMeet.Time_Zone__c = 'AKDT';
        
        return teleMeet;
    }
    /*End - Gabriel Delavin - added as part of CON-SFVV-663-DV Test class*/
}