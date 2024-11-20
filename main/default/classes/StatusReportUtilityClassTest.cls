@Istest
public class StatusReportUtilityClassTest {
    
    @IsTest
    static void testAccess(){
        
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert r;
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = r.Id
        );
        Insert u;
        
        User u1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = r.Id
        );
        Insert u1;
        
        User u2 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = r.Id
        );
        Insert u2;
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            
            Session_Location__c SessionLocationobj = new Session_Location__c(
                Name = 'New session location9/3'
            );
            insert SessionLocationobj;
            
            Session_Location__c SessionLocationobj1 = new Session_Location__c(
                Name = 'New session location9/3'
            );
            insert SessionLocationobj1;
            
            
            Session_Location__c SessionLocationobj2 = new Session_Location__c(
                Name = 'New session location9/3'
            );
            insert SessionLocationobj2;
            
            Campaign__c Campaignobj = new Campaign__c(
                Name = 'Wave Tripler'// Campaign Name
            );
            insert Campaignobj;
                    
            Compass_Setting__c comp = TestDataFactory.createCSData(1);
            insert comp;
            
            Event__c Eventobj = new Event__c(
                Name = 'Test New Event9/3',                                                                                  
                Campaign__c = Campaignobj.Id,
                Event_Page_URL__c = 'https://dev3-nationalcoordinationcenter.cs90.force.com/Compass/s/events?id=TlGlcDDuY8B',
                Event_Id__c = 'TlGlcDDuY8B',                                                                                 
                Milestone__c = false,                                                                                        
                Status__c = 'Planned',                                                                                       
                IsActive__c = false,                                                                                        
                Do_Not_Send_Event_Confirmation_email__c = false,                                                            
                Personalized_Event_Page_Login_Button__c = false,                                                            
                Event_Pages__c = 'Home',                                                                                       
                Issue_Tracker_Page_Title__c = 'Issue Tracker',                                                                 
                Home_Page_Title__c = 'Home',                                                                                   
                Survey_Page_Title__c = 'Survey',                                                                               
                Sessions_Page_Title__c = 'Sessions',                                                                           
                Contact_Us_Page_Title__c = 'Contact Us',                                                                       
                Materials_Page_Title__c = 'Materials',                                                                         
                Learn_More_Page_Title__c = 'Learn More',                                                                       
                Parking_Lot_Page_Title__c = 'Parking Lot',                                                                     
                Start_Date_Time__c = system.now(),                                                 
                End_Date_Time__c = system.now().addHours(1),                                                  
                Time_Zone__c = 'EDT',                                                 
                Email_Sender_Name__c = 'National Coordination Center'                                                         
            );
            insert Eventobj;
            
            Event__c Eventobj1 = new Event__c(
                Name = 'Test New Event9/31',                                                                                  
                Campaign__c = Campaignobj.Id,
                Event_Page_URL__c = 'https://dev3-nationalcoordinationcenter.cs90.force.com/Compass/s/events?id=TlGlcDDuY8B',
                Event_Id__c = 'TlGlcDDuY8B',                                                                                 
                Milestone__c = false,                                                                                        
                Status__c = 'Planned',                                                                                       
                IsActive__c = false,                                                                                        
                Do_Not_Send_Event_Confirmation_email__c = false,                                                            
                Personalized_Event_Page_Login_Button__c = false,                                                            
                Event_Pages__c = 'Home',                                                                                       
                Issue_Tracker_Page_Title__c = 'Issue Tracker',                                                                 
                Home_Page_Title__c = 'Home',                                                                                   
                Survey_Page_Title__c = 'Survey',                                                                               
                Sessions_Page_Title__c = 'Sessions',                                                                           
                Contact_Us_Page_Title__c = 'Contact Us',                                                                       
                Materials_Page_Title__c = 'Materials',                                                                         
                Learn_More_Page_Title__c = 'Learn More',                                                                       
                Parking_Lot_Page_Title__c = 'Parking Lot',                                                                     
                Start_Date_Time__c = system.now(),                                                 
                End_Date_Time__c = system.now().addHours(1),                                                  
                Time_Zone__c = 'EDT',                                                 
                Email_Sender_Name__c = 'National Coordination Center'                                                         
            );
            insert Eventobj1;
            
            Session__c Sessionobj = new Session__c(
                Name = 'C_Orthopedic Clinic to Outpatient Physical Therapy',   
                IsActive__c = true,                                           
                Event__c = Eventobj.Id,                                        
                Milestone__c = false,                                          
                Start_Date_Time__c = system.now(), 
                End_Date_Time__c = system.now().AddHours(23),   
                Session_Details__c = 'Aug 26, 2021, 01:15 PM to 02:45 PM EDT',
                Time_Zone__c = 'EDT', 
                Do_Not_Send_Calendar_Invite__c = false,                        
                Session_Location__c = SessionLocationobj.Id                              
            );
            insert Sessionobj;
            
            Session__c session2 = TestUtility.createSession('C_Orthopedic Clinic to Outpatient Physical Therapy',Eventobj1.Id,SessionLocationobj2.Id, datetime.newInstance(2021,9,4,8,0,0), datetime.newInstance(2021,9,4,16,0,0));
            insert session2;
            
            EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
            system.runAs( new User(Id = UserInfo.getUserId())){
                insert e;
            }
            
            
            OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
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
            
            Session_Role__c SessionRolesobj = new Session_Role__c(
                Number_of_Role__c = 2,                 
                Role_Title__c = 'Super User Facilitator',
                Session__c =   Sessionobj.Id
            );
            insert SessionRolesobj;
            
            Session_Participant__c SessionParticipantobj = new Session_Participant__c(
                Status__c = 'Registered',                                       
                Invitation_Date__c = system.now(),  
                Session__c = Sessionobj.Id,                                       
                Registration_Date__c = system.now(),
                Event__c = Eventobj.Id,                                         
                Sent_Calendar_Invite__c = false                                
            );
            insert SessionParticipantobj;
            
            Parking_Lot__c ParkingLotobj = new Parking_Lot__c(
                Event__c = Eventobj.id,          
                Session__c = Sessionobj.id,        
                Type__c = 'Issue',               
                Category__c = 'Feedback',        
                Description__c = 'Description',  
                Resolution_Answer__c = 'Answer',   
                Show_In_Status_Report__c = true,  
                Status__c = 'Open'                
            );
            insert ParkingLotobj;
            
            Status_Report__c sobj = new Status_Report__c(
                Name = 'Mock Go-Live Daily Status', 
                Team_Name__c = 'Facilitator Support',
                Event_Location__c = 'Event Location',
                Facilitator_Name1__c = u1.id,
                Report_Date__c = system.today(),
                Facilitator_Name2__c = u2.Id, 
                Event__c = Eventobj.Id,               
                Facilitator_Name3__c = u.Id, 
                Session_Location__c = SessionLocationobj.Id,
                Facilitator_Name4__c = UserInfo.getUserId(),       
                General_Update_Content__c = 'The scenario ',
                Parking_Lots__c = 'Q. DescriptionA. Answer',
                What_s_Working_Content__c = 'The scenario follows',
                Session_Attendance_2__c = 'Test Session9/3 — 0 attended of 1 registered,',
                What_s_Not_Working_Content__c = 'The scenario follows a ',
                Status__c = 'Draft',                               
                is_Approved_by_Project_Team__c = false,            
                Due_Date__c = system.now(),                        
                Is_Approved_by_Technical_Editing__c = false,       
                Timezone1__c = 'Eastern Standard Time',            
                Is_Approved_by_QA__c = false                       
            );
            insert sobj;
            update sobj;
            
            Status_Report__c sobj1 = new Status_Report__c(
                Name = 'Mock Go-Live Daily Status', 
                Team_Name__c = 'Facilitator Support',
                Event_Location__c = 'Event Location',
                Facilitator_Name1__c = u1.id,
                Report_Date__c = system.today(),
                Facilitator_Name2__c = u2.Id, 
                Event__c = Eventobj.Id,               
                Facilitator_Name3__c = u.Id, 
                //Session_Location__c = SessionLocationobj.Id,
                Facilitator_Name4__c = UserInfo.getUserId(),       
                General_Update_Content__c = 'The scenario ', 
                Parking_Lots__c = 'Q. DescriptionA. Answer',
                What_s_Working_Content__c = 'The scenario follows',
                Session_Attendance_2__c = 'Test Session9/3 — 0 attended of 1 registered,',
                What_s_Not_Working_Content__c = 'The scenario follows a ',
                Status__c = 'Draft',                               
                is_Approved_by_Project_Team__c = false,            
                Due_Date__c = system.now(),                        
                Is_Approved_by_Technical_Editing__c = false,       
                Timezone1__c = 'Eastern Standard Time',            
                Is_Approved_by_QA__c = false                       
            );
            insert sobj1;
            update sobj1;
            
            
            Status_Report__c sobj2 = new Status_Report__c(
                Name = 'Mock Go-Live Daily Status', 
                Team_Name__c = 'Facilitator Support',
                Event_Location__c = 'Event Location',
                Facilitator_Name1__c = u1.id,
                Report_Date__c = system.today(),
                Facilitator_Name2__c = u2.Id, 
                Event__c = Eventobj1.Id,               
                Facilitator_Name3__c = u.Id, 
                Session_Location__c = SessionLocationobj2.Id,
                Facilitator_Name4__c = UserInfo.getUserId(),       
                General_Update_Content__c = 'The scenario ',
                Parking_Lots__c = 'Q. DescriptionA. Answer',
                What_s_Working_Content__c = 'The scenario follows',
                Session_Attendance_2__c = 'Test Session9/3 — 0 attended of 1 registered,',
                What_s_Not_Working_Content__c = 'The scenario follows a ',
                Status__c = 'Draft',                               
                is_Approved_by_Project_Team__c = false,            
                Due_Date__c = system.now(),                        
                Is_Approved_by_Technical_Editing__c = false,       
                Timezone1__c = 'Eastern Standard Time',            
                Is_Approved_by_QA__c = false                       
            );
            insert sobj2;                
            
        }
    }
}