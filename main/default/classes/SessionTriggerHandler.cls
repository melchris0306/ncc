/*******************************************************************************************
  * @name: SessionTriggerHandler
  * @author: 
  * @created: XX-XX-XXXX
  * @description: Handler for all the logic of the trigger for the Session object
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       		No.   Date(dd-mm-yyy) 	Author         	   	  Description
  *       		----  ---------------   --------------------  -----------------------------
  * @version    1.0	  XX-XX-XXXX							  Initial Creation
  *             2.0   20-10-2021   		Paolo Quiambao        [CCN745] Added code to populate
  * 														  Session_Details_Start_Full__c
  *             3.0   06-12-2021   		Paolo Quiambao        [CCN981] Added syncSessionRichTextFields()
  * 														  method to sync Rich Text fields from Session
  * 														  to Session Participants
  *             4.0   24-08-2022  		Rianno Rizarri        [CCN-EVE-1834-DV] Total Participants Registered field at session start
  *                                                           Added Start_Date_Time_on_Timezone__c for getting the start datetime on
  *                                                           the session timezone converted to org default timezone.
  *             4.1   27-08-2022  		Rianno Rizarri        [CCN-EVE-1834-DV] Update to code standards
  *             4.2   27-11-2022        Xen Reyes             [CCN-LOG-2217-DV] Update Event Internal Logistics when inserting / updating Session
  *             4.3   23-05-2023        Rex David             [CCN-2534] Virtual Meeting Integration (POC: Microsoft Teams Link) 
  *********************************************************************************************/
  public with sharing class SessionTriggerHandler {

    public class MyException extends Exception {}

    //Start CCN-EVE-1834-DV: Rianno Rizarri
    public static boolean bPreventAI = false;
    public static boolean bPreventAU = false;

    public static void onBeforeInsert(List<Session__c> newSessionList, Map<Id,Session__c> newSessionMap){
        populateSessionDetails(newSessionList,null,null,null);
    }

    public static void onBeforeUpdate(List<Session__c> newSessionList, Map<Id,Session__c> newSessionMap, 
                                      List<Session__c> oldSessionList, Map<Id,Session__c> oldSessionMap){ 
        populateSessionDetails(newSessionList, newSessionMap, oldSessionList, oldSessionMap);
    }

    public static void onAfterInsert(List<Session__c> newSessionList, Map<Id,Session__c> newSessionMap, 
                                     List<Session__c> oldSessionList, Map<Id,Session__c> oldSessionMap){
        updateEventInternalLogistics(newSessionList, newSessionMap, null, null);
        processMeetingUrl(newSessionList,null);//CCN-EVE-3056-DV adavid@ulapp.co Virtual Meeting Integration 
                                         
    }
    public static void onAfterUpdate(List<Session__c> newSessionList, Map<Id,Session__c> newSessionMap, 
                                    List<Session__c> oldSessionList, Map<Id,Session__c> oldSessionMap){
        syncSessionRichTextFields(newSessionList, newSessionMap, oldSessionList, oldSessionMap);
        updateEventInternalLogistics(newSessionList, newSessionMap, oldSessionList, oldSessionMap);
        processMeetingUrl(newSessionList,oldSessionMap);//CCN-EVE-3056-DV adavid@ulapp.co Virtual Meeting Integration 
    }

    //End CCN-EVE-1834-DV: Rianno Rizarri
    public static void populateSessionDetails(List<Session__c> newList, Map<Id,Session__c > newMap,List<Session__c > oldList, Map<Id,Session__c > oldMap){
        String strTZone = String.ValueOf(userinfo.getTimeZone());
        //Start CCN-EVE-1834-DV: Rianno Rizarri
        Map<String, Org_timezone_difference__mdt> TZDiffMeta = new Map<String, Org_timezone_difference__mdt>();
        TZDiffMeta = Org_timezone_difference__mdt.getAll();
        //End CCN-EVE-1834-DV: Rianno Rizarri

        Boolean isUpdate = (oldMap != null);
        
        for(Session__c session : newList){

            //CCN-2871 Xen Reyes Apr242023
            Session__c oldSession = new Session__c();
            if(isUpdate) oldSession = oldMap.get(session.Id);
            
            String sessionName = '';
            String sessionDetailsFull = '';
            // Updated by Paolo Quiambao [CCN-745] Oct082021
            String sessionDetailsStartFull = '';
            
            //CCN-2871 Xen Reyes Apr242023 - Additional checks in filling in session details
            //CCN-3002 Xen Reyes May122023 - Include Time zone change in the checks to re-evaluate session details
            if( (!isUpdate && session.Start_Date_Time__c != null && session.End_Date_Time__c != null) || 
                (isUpdate && session.Start_Date_Time__c != null && session.End_Date_Time__c != null && session.Time_Zone__c != null &&
                (oldSession.Start_Date_Time__c != session.Start_Date_Time__c || oldSession.End_Date_Time__c != session.End_Date_Time__c || oldSession.Time_Zone__c != session.Time_Zone__c))){
                
                DateTime startDT = session.Start_Date_Time__c;
                DateTime endDT = session.End_Date_Time__c;
                sessionName = startDT.format('MMM dd, yyyy', strTZone)+ ', '
                    +startDT.format('hh:mm aaa', strTZone) + ' ' 
                    +' to '+endDT.format('MMM dd, yyyy', strTZone)+', '+endDT.format('hh:mm aaa', strTZone) + ' ' + session.Time_Zone__c;
                
                //00707 1/21/2020 - Parking Lot Email notification - JC
                sessionDetailsFull = startDT.format('MMMMM dd, yyyy', strTZone)+ ', '
                    +startDT.format('hh:mm aaa', strTZone) + ' ' 
                    +' to '+endDT.format('MMMMM dd, yyyy', strTZone)+', '+endDT.format('hh:mm aaa', strTZone) + ' ' + session.Time_Zone__c;
                session.Start_Date_Time2__c = startDT.format('MM/dd/yyyy', strTZone)+ ', ' +startDT.format('hh:mm aaa', strTZone);
                session.End_Date_Time2__c = endDT.format('MM/dd/yyyy', strTZone)+ ', ' +endDT.format('hh:mm aaa', strTZone);
                // Updated by Paolo Quiambao [CCN-745] Oct082021
                sessionDetailsStartFull = startDT.format('MMMM dd, yyyy', strTZone) + ', ' + startDT.format('hh:mm aaa', strTZone) +
                    ' to ' + endDT.format('hh:mm aaa', strTZone) + ' ' + session.Time_Zone__c;
                //Start CCN-EVE-1834-DV: Rianno Rizarri
                if(String.isNotBlank(session.Time_Zone__c) && TZDiffMeta.containsKey(session.Time_Zone__c)){
                    Decimal difference = TZDiffMeta.get(session.Time_Zone__c).Hour_Difference__c*-60;
                    session.Start_Date_Time_on_Timezone__c = startDT.addMinutes(Integer.valueOf(difference));
                }
                //End CCN-EVE-1834-DV: Rianno Rizarri

                session.Session_Details__c = sessionName;
                //00707 1/21/2020 - Parking Lot Email notification - JC
                session.Session_Details_Full__c = sessionDetailsFull;
                // Updated by Paolo Quiambao [CCN-745] Oct082021
                session.Session_Details_Start_Full__c = sessionDetailsStartFull;
            }

            // UPDATED BY JC ESPINO CCN-EVE-1191-DV MAR172022
            // Resets Send_Updated_Calendar_Invite__c when session date/time/tz details are updated
            if(isUpdate) {
                if((oldSession.Time_Zone__c != session.Time_Zone__c || 
                    // UPDATED by JC ESPINO [CCN-EVE-1360-DV] - Changed the referenced field from Meeting_URL__c to Location__c
                    oldSession.Location__c != session.Location__c || 
                    oldSession.Start_Date_Time__c != session.Start_Date_Time__c || 
                    oldSession.End_Date_Time__c != session.End_Date_Time__c) && 
                    session.Send_Updated_Calendar_Invite__c
                ){
                    session.Send_Updated_Calendar_Invite__c = false;
                }
            }
        }
    }
    
    // Updated by Paolo Quiambao [CCN-981] Dec062021
    public static void syncSessionRichTextFields(List<Session__c> newList, Map<Id,Session__c > newMap, List<Session__c > oldList, Map<Id,Session__c > oldMap) {
        Session_Participant__c participant = new Session_Participant__c();
        Set<Id> sessionsToSendCalendarUpdate = new Set<Id>();
        Set<Id> sessionsWithUpdatedMessages = new Set<Id>();

        // UPDATED BY JC ESPINO CCN-EVE-1191-DV MAR172022
        // Send updated Calendar Invites to Confirmed Participants
        for(Session__c session : newList) {
            Session__c oldSession = oldMap.get(session.Id);

            System.debug('### oldSession.Send_Updated_Calendar_Invite__c: ' + oldSession.Send_Updated_Calendar_Invite__c);
            System.debug('### session.Send_Updated_Calendar_Invite__c: ' + session.Send_Updated_Calendar_Invite__c);
            System.debug('### session.Do_Not_Send_Calendar_Invite__c: ' + session.Do_Not_Send_Calendar_Invite__c);
            if(!oldSession.Send_Updated_Calendar_Invite__c && 
                session.Send_Updated_Calendar_Invite__c && 
                !session.Do_Not_Send_Calendar_Invite__c
            ){
                sessionsToSendCalendarUpdate.add(session.Id);
            }

            if(session.Session_Attendance_Thank_You_Message__c != oldSession.Session_Attendance_Thank_You_Message__c || 
               session.Session_Catchup_Message__c != oldSession.Session_Catchup_Message__c || 
               session.Session_Catchup_Reminder_Message__c != oldSession.Session_Catchup_Reminder_Message__c || 
               session.Session_Catchup_Thank_You_Message__c != oldSession.Session_Catchup_Thank_You_Message__c 
            ) {
                sessionsWithUpdatedMessages.add(session.Id);
            }
        }

        if(!sessionsToSendCalendarUpdate.isEmpty()) {
            // List<Session_Participant__c> confirmedSessionParticpants = [SELECT Id, Name, Contact__c, Contact__r.Email, Status__c, Session__c, 
            //                                                             Event__r.Location__r.Name, Event__r.Email_Sender_Id__c, Event__r.Email_Sender_Name__c,
            //                                                             Session__r.Name, Session__r.Subtitle__c,
            //                                                             Session__r.Time_Zone__c, Session__r.Description__c, Session__r.Meeting_Info__c, Session__r.Meeting_URL__c, 
            //                                                             Session__r.Start_Date_Time__c, Session__r.End_Date_Time__c, Session__r.Do_Not_Send_Calendar_Invite__c
            //                                                             FROM Session_Participant__c WHERE Status__c = 'Confirmed' AND Session__c IN :sessionsToSendCalendarUpdate];
            // SessionParticipantTriggerUtility.sendUpdatedCalendarInvite(confirmedSessionParticpants);
            SessionParticipantTriggerUtility.sendUpdatedCalendarInvite(sessionsToSendCalendarUpdate);
        }

        List<Session_Participant__c> spToUpdate = new List<Session_Participant__c>();
        //Added checker if isUpdateable for [CCN-1148] Feb112022
        if(FlsUtils.isUpdateable(participant, new List<String>{'Session_Attendance_Thank_You_Message__c','Session_Catchup_Message__c','Session_Catchup_Reminder_Message__c','Session_Catchup_Thank_You_Message__c'})){
            system.debug('isUpdateable');
            for(Session_Participant__c sp : [SELECT Id, Session_Attendance_Thank_You_Message__c, Session_Catchup_Message__c, Session_Catchup_Reminder_Message__c, 
                                             Session_Catchup_Thank_You_Message__c, Session__r.Session_Attendance_Thank_You_Message__c, Session__r.Session_Catchup_Message__c, 
                                             Session__r.Session_Catchup_Reminder_Message__c, Session__r.Session_Catchup_Thank_You_Message__c, Session__r.Send_Updated_Calendar_Invite__c 
                                             FROM Session_Participant__c WHERE Session__c IN :sessionsWithUpdatedMessages]) {
                                                 
                                                 sp.Session_Attendance_Thank_You_Message__c = sp.Session__r.Session_Attendance_Thank_You_Message__c;
                                                 sp.Session_Catchup_Message__c = sp.Session__r.Session_Catchup_Message__c;
                                                 sp.Session_Catchup_Reminder_Message__c = sp.Session__r.Session_Catchup_Reminder_Message__c;
                                                 sp.Session_Catchup_Thank_You_Message__c = sp.Session__r.Session_Catchup_Thank_You_Message__c;
                                                 spToUpdate.add(sp);
                                             }
            update spToUpdate;
        }
    }

    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  25-11-2022   Xen Reyes            [CCN-LOG-2217-DV] Initial version.
    ******************************************************************************/
    public static void updateEventInternalLogistics(List<Session__c> newList, Map<Id,Session__c > newMap, List<Session__c > oldList, Map<Id,Session__c > oldMap) {
        
        try{
            Set<Id> eventIdToUpdate = new Set<Id>();
            for(Session__c session : newList) {
                if(session.IsActive__c && session.Event__c != null){
                    if(oldList != null) {
                        if(oldMap.get(session.Id).Meeting_URL__c != session.Meeting_URL__c) eventIdToUpdate.add(session.Event__c);
                    } else {
                        eventIdToUpdate.add(session.Event__c);
                    }
                }
            }

            Map<Id, Set<String>> eventIdSessionMeetingLocationsMap = new Map<Id, Set<String>>();
            List<Internal_Logistics__c> logisticListToUpdate = new List<Internal_Logistics__c>();
            List<Event__c> eventList = [SELECT Id, (SELECT Id, Event_Name__c FROM Internal_Logistics__r), (SELECT Id, Meeting_URL__c FROM CC_Sessions__r WHERE IsActive__c = true) FROM Event__c WHERE Id IN: eventIdToUpdate];
            
            for(Event__c e : eventList){
                Set<String> sessionMeetingLocations = new Set<String> ();
                for(Session__c s : e.CC_Sessions__r){
                    if(s.Meeting_URL__c != null) sessionMeetingLocations.add(s.Meeting_URL__c);
                }
                eventIdSessionMeetingLocationsMap.put(e.Id, sessionMeetingLocations);
            }

            for(Event__c e : eventList){
                for(Internal_Logistics__c ie : e.Internal_Logistics__r){

                    String sessionMeetingLocationsCon = '';
                    Integer numberOfSessionMeetingLocations = 0;
                    if(eventIdSessionMeetingLocationsMap.containsKey(ie.Event_Name__c)){

                        List<String> locationList = new List<String>(eventIdSessionMeetingLocationsMap.get(ie.Event_Name__c));
                        locationList.sort();
                        sessionMeetingLocationsCon = String.join(locationList, ', ');
                        numberOfSessionMeetingLocations = eventIdSessionMeetingLocationsMap.get(ie.Event_Name__c).size();

                        logisticListToUpdate.add(new Internal_Logistics__c( Id = ie.Id, 
                                                                            Session_Locations__c = sessionMeetingLocationsCon,
                                                                            Number_of_Locations__c = numberOfSessionMeetingLocations));
                    }
                }
            }
            update logisticListToUpdate;
        } catch (exception e) {
            throw new MyException(e);
        }
    }

    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  14-06-2023   Rex David            [CCN-2534] [CCN-EVE-3056-DV] Virtual Meeting Integration (Microsoft Teams Link)
    ******************************************************************************/
    public static void processMeetingUrl(List<Session__c> newList, Map<Id,Session__c> oldMap){
        
        String action = oldMap == NULL ? 'POST' : 'PATCH';
        
        Set<Id> sessionEventIds = new Set<Id>();
        List<Session__c> sessionListToProcess = new List<Session__c>();

        for(Session__c session : newList){
            if(action == 'POST'){
                if(session.Event__c != NULL) sessionEventIds.add(session.Event__c);
            }
            else if(action == 'PATCH'){
                if(session.Name != oldMap.get(session.Id).Name 
                || session.Start_Date_Time__c != oldMap.get(session.Id).Start_Date_Time__c 
                || session.End_Date_Time__c != oldMap.get(session.Id).End_Date_Time__c){
                    if(session.Event__c != NULL) sessionEventIds.add(session.Event__c);
                }
            }   
        }

        if(!sessionEventIds.isEmpty()){
            Map<Id,Event__c> eventMap = new Map<Id,Event__c> ([SELECT Id, (SELECT Id, Name, Event__c FROM CC_Sessions__r WHERE ID IN: newList) FROM Event__c WHERE Id IN: sessionEventIds AND Event_Type__c = 'Virtual' AND Virtual_Meeting_Platform__c = 'MS Teams']);
            if(!eventMap.isEmpty()){
                for(Id eventId : eventMap.keySet()){
                    for(Session__c session : eventMap.get(eventId).CC_Sessions__r){
                        sessionListToProcess.add(session);
                    }
                }
                if(!sessionListToProcess.isEmpty()) Database.executeBatch(new AzureAPIBatch(action,sessionListToProcess),10); 
            }
            System.debug(eventMap.isEmpty() ? 'Current Event Type and Virtual_Meeting_Platform__c are not supported in MS Teams integration.' : '');
        }
    }
}