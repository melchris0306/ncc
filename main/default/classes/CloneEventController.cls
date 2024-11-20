/*******************************************************************************************
* @name: CloneEventController
* @author: Mel Mallorca
* @created: 28-09-2021
* @description: Class for Cloning Event
*
* Changes (version)
* -------------------------------------------------------------------------------------------
*       No.  Date(dd-mm-yyy) Author         Description
*       ----  ---------   --------------------  -----------------------------
* @version   1.0  28-09-2021   Mel Mallorca    [CCN-499] Initial version.
* @version   2.0  14-10-2021   Mel Mallorca    [CCN-844] Cloning of Events Enhancement
*            3.0  18-08-2022   Xen Reyes       [CCN-EVE-2067-DV] - Changed references of Sign_Up_Instructions__c to Sign_Up_Instructions_2__c due to field deprecation.
*            4.0  12-09-2022   Xen Reyes       [CCN-2125] - Append 'Copy' at the end of the survey name
                                                          - Added "Description__c" field as part of the query in surveyQuestions
             4.1  11-14-2023   Rex David       [CCN-EVE-3565-DV] - Added support for Virtual Meeting Integration
*********************************************************************************************/

public with sharing class CloneEventController {
    
    //Start CCN-2125 Xen Reyes
    public static final String COPY = ' Copy';
    //End CCN-2125 Xen Reyes

    @AuraEnabled
    public static String cloneEventRecord(Id eventId){
        String returnMsg;
        try{
            // Updated by MMallorca [CCN-844] Oct142021 
            Event__c event = [Select Id, Name, Event_Type__c, Virtual_Meeting_Platform__c, Registration_Message__c, Registration_Tag_Line__c, IsActive__c, Campaign__c, Campaign_Logo_URL__c, Compass_Setting__c, Confirmation_Ending_Message__c, Confirmation_Welcome_Message__c, Contact_Us_Message__c, Contact_Us_Page_Title__c, Contact_Us_Tag_Line__c, Contact_Us_User__c, Description__c, Do_Not_Send_Event_Confirmation_email__c, Email_Logo_URL__c, Email_Message_BCC__c, Email_Message_CC__c, Email_Sender_Id__c, Email_Sender_Name__c, End_Date_Time__c, Event_Id__c, Event_Name_Len__c, Event_Pages__c, Event_Page_URL__c, Event_Register_Page_URL__c, Hero_Image_URL__c, Home_Page_Title__c, Invite_Additional_Message__c, Invite_Ending_Message__c, Invite_Welcome_Message__c, Issue_Tracker_Page_Title__c, Journey__c, Learn_More_Page_Title__c, Location__c, Materials_Page_Title__c, Meeting_URL__c, Milestone__c, Parking_Lot_Message__c, Parking_Lot_Page_Title__c, Parking_Lot_Tag_Line__c, Parking_Lot_User__c, Personalized_Event_Page_Login_Button__c, Re_Generate_URL__c, Registration_Fields_JSON__c, Sessions_Calendar_Page_URL__c, Sessions_Page_Title__c, Sessions_with_General_Materials__c, Start_Date_Time__c, Status__c, 
            Subtitle__c, 
            Survey_Page_Title__c, Time_Zone__c, Registration_Reminder_Welcome_Message__c, Registration_Reminder_Additional_Message__c, Registration_Reminder_Ending_Message__c,Confirmation_Reminder_Welcome_Message__c, Confirmation_Reminder_Ending_Message__c 
                              From Event__c 
                              Where Id =: eventId];
            
            Event__c clonedEvent = event.clone(false, true, false, false);  
            clonedEvent.Name = clonedEvent.Name+' Copy';
            //Database.insert(clonedEvent, false);
            insert clonedEvent;
            if(clonedEvent.Id != null){
                
                // Updated by MMallorca [CCN-844] Oct142021
                //Event Role
                List<Event_Role__c> eventRoles = [Select Id, Name, Campaign__c, Contact__c, Event__c, Role__c, Show_in_Event_Site__c
                                                  From Event_Role__c
                                                  Where Event__c =: event.Id];
                
                List<Event_Role__c> newEventRoles = new List<Event_Role__c>();
                for(Event_Role__c s: eventRoles){
                    Event_Role__c eventRole = new Event_Role__c();
                    eventRole = s.clone(false, true, false, false);
                    eventRole.Event__c = clonedEvent.Id;
                    newEventRoles.add(eventRole);
                }
                Database.insert(newEventRoles, false); 
                
                //Session

                //Start CCN-EVE-2067-DV Xen Reyes
                List<Session__c> sessions = [Select Id, Name, IsActive__c, Contact__c, ContactId__c, Description__c, Do_Not_Send_Calendar_Invite__c, End_Date__c, End_Date_Time__c, Event__c, Event_Id__c, Location__c, Meeting_Info__c, Meeting_URL__c, Milestone__c, Propose_End_Date_Time__c, Propose_Start_Date_Time__c, Session__c, Session_Date__c, Session_Details__c, Session_Details_Full__c, Session_Location__c, Sign_Up_Instructions_2__c, Start_Date_2__c, Start_Date_Time_2__c, Start_Date_Time__c, Start_Date_Time2__c, Status__c, 
                Subtitle__c, 
                Time_Zone__c, User_Time_Zone__c, Virtual_Meeting_URL__c
                                             From Session__c
                                             Where Event__c =: event.Id];
                //Start CCN-EVE-2067-DV Xen Reyes
                
                CCEventTriggerHandler cc = new CCEventTriggerHandler();
                
                Set<Id> sessionIds = new Set<Id>();
                List<Session__c> newSessions = new List<Session__c>();
                
                Map<String, String> sessionsMap = new Map<String, String>();
                
                for(Session__c s: sessions){
                    sessionIds.add(s.Id);
                    Session__c session = new Session__c();
                    session = s.clone(false, true, false, false);
                    session.Meeting_Info__c = null;
                    session.Meeting_URL__c = null;
                    session.Event__c = clonedEvent.Id; 
                    //Start CCN-3133 defaulting Status to Planned and set propose start/end date time to blank - GabDelavin - 06/28/2023
                    session.Status__c = 'Planned';
                    session.Propose_Start_Date_Time__c = null;
                    session.Propose_End_Date_Time__c = null;
                    //End CCN-3133 defaulting Status to Planned and set propose start/end date time to blank - GabDelavin - 06/28/2023
                    session.Session_Id__c = cc.getToken();
                    newSessions.add(session);
                    sessionsMap.put(s.Id, session.Session_Id__c);
                }
                Database.insert(newSessions, false);
                
                Map<String, String> newSessionsMap = new Map<String, String>();
                for(Session__c s: newSessions){
                    newSessionsMap.put(s.Session_Id__c, s.Id);
                }
                
                //Session Roles
                List<Session_Role__c> sessionRoles = [Select Id, Name, Number_of_Role__c, Role_Description__c, Role_Title__c, Session__c
                                                      From Session_Role__c
                                                      Where Session__c IN: sessionIds];
                
                List<Session_Role__c> newSessionRoles = new List<Session_Role__c>();
                for(Session_Role__c s: sessionRoles){
                    Session_Role__c sessionRole = new Session_Role__c();
                    sessionRole = s.clone(false, true, false, false);
                    sessionRole.Session__c = (newSessionsMap.get(sessionsMap.get(s.Session__c)));
                    newSessionRoles.add(sessionRole);
                }
                Database.insert(newSessionRoles, false); 
                
                /*Start- Added by Gab as part of CCN-EVE-3295-DV to clone Internal Resource if Session is Cloned 7/21/2023*/
                List<Internal_Resource_Role__c> internalRolesList = [Select Id, Session__c, Internal_Resource_Number_of_Role__c, Internal_Resource_Role_Description__c, Internal_Resource_Role_Title__c from Internal_Resource_Role__c where Session__c IN: sessionIds];
                List<Internal_Resource_Role__c> newInternalRoles = new List<Internal_Resource_Role__c>();
                If(internalRolesList.Size()>0){
                    for(Internal_Resource_Role__c s: internalRolesList){
                        Internal_Resource_Role__c InternalRole = new Internal_Resource_Role__c();
                        InternalRole = s.clone(false, true, false, false);
                        InternalRole.Session__c = (newSessionsMap.get(sessionsMap.get(s.Session__c)));
                        newInternalRoles.add(InternalRole);
                    }
                   Database.insert(newInternalRoles, false);  
                }
                /*End- Added by Gab as part of CCN-EVE-3295-DV to clone Internal Resource if Session is Cloned 7/21/2023*/
                //Survey
                List<Survey__c> surveys = [Select Id, Name, Survey_Campaign__c, Campaign_Formula__c, Campaign_Logo_URL__c, Campaign_Name__c, Description__c, Disclaimer__c, Journey_Milestone_End_Date__c, Event__c, Event_Id__c, Event_Name__c, Journey__c, Journey_Name__c, Logo_Image_Id__c, Milestone__c, Standalone_Survey_URL__c, Journey_Milestone_Start_Date__c, Survey_Code__c, Survey_Fields_JSON__c, Survey_Logo__c, Survey_Logo_URL__c, Survey_Id__c
                                           From Survey__c
                                           Where Event__c =: eventId];
                
                Set<Id> surveyIds = new Set<Id>();
                List<Survey__c> newSurveys = new List<Survey__c>();
                
                Map<String, String> surveysMap = new Map<String, String>();
                
                for(Survey__c s: surveys){
                    surveyIds.add(s.Id);
                    Survey__c survey = new Survey__c();
                    survey = s.clone(false, true, false, false);
                    survey.Survey_Id__c = cc.getToken();
                    survey.Event__c = clonedEvent.Id;

                    //Start CCN-2125 Xen Reyes
                    survey.Name = s.Name + COPY;
                    //Start CCN-2125 Xen Reyes

                    newSurveys.add(survey);
                    surveysMap.put(s.Id, survey.Survey_Id__c);
                }
                Database.insert(newSurveys, false);
                
                Map<String, String> newSurveysMap = new Map<String, String>();
                for(Survey__c s: newSurveys){
                    newSurveysMap.put(s.Survey_Id__c, s.Id);
                }
                
                //Survey Questions

                //Start CCN-2125 Xen Reyes
                List<Survey_Question__c> surveyQuestions = [Select Id, Name, Description__c, Max_Value__c, Min_Value__c, Options__c, Question_Category__c, Question_Type__c, Report_Category__c, Required_Question__c, Sorting_Order__c, Step__c, Survey__c
                                                      From Survey_Question__c
                                                      Where Survey__c IN: surveyIds];
                //End CCN-2125 Xen Reyes
                
                List<Survey_Question__c> newSurveyQuestions = new List<Survey_Question__c>();
                for(Survey_Question__c s: surveyQuestions){
                    Survey_Question__c surveyQuestion = new Survey_Question__c();
                    surveyQuestion = s.clone(false, true, false, false);
                    surveyQuestion.Survey__c = (newSurveysMap.get(surveysMap.get(s.Survey__c)));
                    newSurveyQuestions.add(surveyQuestion);
                }
                Database.insert(newSurveyQuestions, false); 
                
                
                
                returnMsg = clonedEvent.Id;
            }
        }
        catch(Exception ex){
            system.debug('CloneEventController Error>>> '+ex.getMessage()+ex.getLineNumber());
            returnMsg = 'Error>>>'+ex.getMessage();
        }
        
        return returnMsg;
    }
}