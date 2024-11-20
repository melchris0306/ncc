/**
 * @description       : [CCN-EVE-1244-DV] CloneSessionController
 * @author            : adavid@ulapp.co
 * @group             : 
 * @last modified on  : 06-29-2022
 * @last modified by  : adavid@ulapp.co
 * @version     1.0     29-03-2022  Aaron David [CCN-EVE-1244-DV] Initial version.
 *              2.0     18-08-2022  Xen Reyes   [CCN-EVE-2067-DV] - Changed references of Sign_Up_Instructions__c to Sign_Up_Instructions_2__c due to field deprecation.
**/

public with sharing class CloneSessionController {

    /**
    * @description cloneSessionRecord [CCN-EVE-1244-DV]
    *   Clone Session record with its related Session Roles
    * @author adavid@ulapp.co | 03-29-2022 
    * @param sessionId 
    * @return String 
    **/
    @AuraEnabled
    public static String cloneSessionRecord(Id sessionId){
        String returnMsg;
        List<Session_Role__c> newSessionRoles = new List<Session_Role__c>();
		List<Internal_Resource_Role__c> newInternalRoles = new List<Internal_Resource_Role__c>();
        try{
            //Session

            //Start CCN-EVE-2067-DV Xen Reyes
            Session__c sessionCurrent = [Select Id, Name, IsActive__c, Contact__c, ContactId__c, Description__c, Do_Not_Send_Calendar_Invite__c, End_Date__c, End_Date_Time__c, Event__c, Event_Id__c, Location__c, Meeting_Info__c, Meeting_URL__c, Milestone__c, Propose_End_Date_Time__c, Propose_Start_Date_Time__c, Session__c, Session_Date__c, Session_Details__c, Session_Details_Full__c, Session_Location__c, Sign_Up_Instructions_2__c, Start_Date_2__c, Start_Date_Time_2__c, Start_Date_Time__c, Start_Date_Time2__c, Status__c, Subtitle__c, Time_Zone__c, User_Time_Zone__c, Virtual_Meeting_URL__c
            From Session__c
            Where Id =: sessionId LIMIT 1];
            //End CCN-EVE-2067-DV Xen Reyes

            CCEventTriggerHandler cc = new CCEventTriggerHandler();
            Session__c clonedSession = sessionCurrent.clone(false, true, false, false);  
            clonedSession.Name = clonedSession.Name+' Copy';
            //Start CCN-3213 defaulting Status to Planned and set propose start/end date time to blank - GabDelavin - 07/03/2023
             clonedSession.Status__c = 'Planned';
             clonedSession.Propose_Start_Date_Time__c = null;
             clonedSession.Propose_End_Date_Time__c = null;
             //End CCN-3213 defaulting Status to Planned and set propose start/end date time to blank - GabDelavin - 07/03/2023
            clonedSession.Session_Id__c = cc.getToken();

            Database.SaveResult srSession = Database.insert(clonedSession, false);

            // Iterate through each returned result
            
            if (srSession.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                //Session Roles
                List<Session_Role__c> sessionRoles = [Select Id, Name, Number_of_Role__c, Role_Description__c, Role_Title__c, Session__c
                From Session_Role__c
                Where Session__c =: sessionId];

                for(Session_Role__c s: sessionRoles){
                    Session_Role__c sessionRole = new Session_Role__c();
                    sessionRole = s.clone(false, true, false, false);
                    sessionRole.Session__c = clonedSession.Id;
                    newSessionRoles.add(sessionRole);
                }

                if(newSessionRoles.size() > 0){
                    Database.SaveResult[] srSessionRoles = Database.insert(newSessionRoles, false);
                    // Iterate through each returned result
                    for (Database.SaveResult sr : srSessionRoles) {
                        if (sr.isSuccess()) {
                            // Operation was successful, so get the ID of the record that was processed
                        }
                        else {
                            // Operation failed, so get all errors                
                            for(Database.Error err : sr.getErrors()) {
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            }
                        }
                    }
                }
               /*Start- Added by Gab as part of CCN-EVE-3295-DV to clone Internal Resource if Session is Cloned 7/21/2023*/ 
                List<Internal_Resource_Role__c> internalRolesList = [Select Id, Session__c, Internal_Resource_Number_of_Role__c, Internal_Resource_Role_Description__c, Internal_Resource_Role_Title__c from Internal_Resource_Role__c where Session__c =: sessionId];
                If(internalRolesList.Size()>0){
                    for(Internal_Resource_Role__c s: internalRolesList){
                        Internal_Resource_Role__c InternalRole = new Internal_Resource_Role__c();
                        InternalRole = s.clone(false, true, false, false);
                        InternalRole.Session__c = clonedSession.Id;
                        newInternalRoles.add(InternalRole);
                    } 
                }
                
                if(newInternalRoles.size() > 0){
                    Database.SaveResult[] srInternalRoles = Database.insert(newInternalRoles, false);
                    // Iterate through each returned result
                    for (Database.SaveResult sr : srInternalRoles) {
                        if (sr.isSuccess()) {
                            // Operation was successful, so get the ID of the record that was processed
                        }
                        else {
                            // Operation failed, so get all errors                
                            for(Database.Error err : sr.getErrors()) {
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            }
                        }
                    }
                }
            /*End- Added by Gab as part of CCN-EVE-3295-DV to clone Internal Resource if Session is Cloned 7/21/2023*/ 
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : srSession.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }
           
            returnMsg = clonedSession.Id;

        }
        catch(Exception ex){
            system.debug('CloneSessionController Error>>> '+ex.getMessage()+ex.getLineNumber());
            returnMsg = 'Error>>>'+ex.getMessage();
        }

        return returnMsg;
    }
}