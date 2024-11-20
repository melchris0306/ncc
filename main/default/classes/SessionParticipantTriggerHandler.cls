/*******************************************************************************************
  * @name: SessionTriggerHandler
  * @author: 
  * @created: XX-XX-XXXX
  * @description: Handler for all the logic of the trigger for the Session object
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *             No.   Date(dd-mm-yyy)   Author                Description
  *             ----  ---------------   --------------------  ---------------------------------
  * @version    1.0   XX-XX-XXXX                              Initial Creation
  *             2.0   06-12-2021        Paolo Quiambao        [CCN981] Added code to sync Rich Text
  *                                                           from Session
  *             3.0   28-01-2022        DinoBrinas            [CCN1153] Fix the recursive issue
  *       4.0   23-03-2022    Paolo Quiambao      [CCN934] Replace Domain Name with Domain Name (Event Registration)
  *       5.0    25-04-2022    Paolo Quiambao      [CCN-EVE-1219-DV] Add automation for Confirmed Date and Declined Date
  * @version    4.0  17-08-2022   JC Espino            [CCN-EVE-1726-DV] Added criteria of when to send Calendar Invite
  *********************************************************************************************/
  public class SessionParticipantTriggerHandler{
    // @author: [CCN-1153] Updated by dinoBrinas
    // @description: This is used to avoid the recursive on the apex trigger.
    // @date: Jan282022
    public static boolean bPreventAI = false;
    public static boolean bPreventAU = false;
    public static boolean isFromAttendancePage = false; //CCN-1028 XR 27 May 2022
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  ??           ??                   Initial version.
    * @version   2.0  29-01-2022   VonPernicia          [CCN-496] Added new method "updateParticipantMilestoneMetrics" to call to update Participant Milestone Metics
    * @version   3.0  07-07-2022   Rianno Rizarri       [CCN-EVE-1834-DV] Added new method SessionParticipantTriggerUtility.countSessionPartipants to call the method
    * @version   4.0  17-08-2022   JC Espino            [CCN-EVE-1726-DV] Added criteria of when to send Calendar Invite
    * @version   6.0  12-01-2022   Von Pernicia         [CCN-2466] Remove logic that creates records in Batch_Processor__c
    ******************************************************************************/
    public static void onAfterInsert(List<Session_Participant__c> newSessionParticipantList, Map<Id,Session_Participant__c> newSessionParticipantMap, 
                                     List<Session_Participant__c> oldSessionParticipantList, Map<Id,Session_Participant__c> oldSessionParticipantMap){
        //Start CCN-EVE-1834-DV: Rianno Rizarri
		SessionParticipantTriggerUtility.countSessionPartipants(newSessionParticipantList);
        //End CCN-EVE-1834-DV: Rianno Rizarri
        Set<Id> participantIdSet = new Set<Id>();
		//Gabriel Delvin *08-10-2023* CCN-EVE-3426-DV
		SessionParticipantTriggerUtility.updateContactTitleRank(newSessionParticipantList);
        // Start CCN-2466 Von Pernicia: Removed logic
        //List<Session_Participant__c> updateParticipantMilestoneList = new List<Session_Participant__c>();
        // End CCN-2466 Von Pernicia: Removed logic                                

        List<Participant__c> participantsToUpdate = new List<Participant__c>();
        // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV]
        Map<Id, List<Session_Participant__c>> eventToParticipantsMap = new Map<Id, List<Session_Participant__c>>();
        Map<Id,Session_Participant__c> participantsToReceiveCalendarInvite = new Map<Id,Session_Participant__c>();

        for(Session_Participant__c sessionParticipant: newSessionParticipantList){
            if(sessionParticipant.Status__c == 'Confirmed'){
                // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV] - Added mechanism to check Event field Session_Calendar_Invite_Delivery__c

                if(!eventToParticipantsMap.containsKey(sessionParticipant.Event__c)) {
                    eventToParticipantsMap.put(sessionParticipant.Event__c, new List<Session_Participant__c>());
                }
                eventToParticipantsMap.get(sessionParticipant.Event__c).add(sessionParticipant);
                // END [CCN-EVE-1726-DV]
            }

            // Start CCN-2466 Von Pernicia: Removed logic
            /*if(!String.isEmpty(String.valueOf(sessionParticipant.Registration_Date__c)) &&  ( sessionParticipant.Status__c == 'Registered' || sessionParticipant.Status__c == 'Invited')) {
                updateParticipantMilestoneList.add(sessionParticipant);
            }*/
            // End CCN-2466 Von Pernicia: Removed logic

            // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV] - Added special case to send Calendar Invite during registration
            if(sessionParticipant.Status__c == 'Registered' && sessionParticipant.Event_Invite_Delivery_Option__c == 'Send on session registration') {
                participantsToReceiveCalendarInvite.put(sessionParticipant.Id, sessionParticipant);
            }
            // END [CCN-EVE-1726-DV]

            participantIdSet.add(sessionParticipant.Participant__c);
        }

        // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV] - Added special case to send Calendar Invite during registration
        if(!participantsToReceiveCalendarInvite.isEmpty()) {
            SessionParticipantTriggerUtility.sendCalendarInvite(participantsToReceiveCalendarInvite.values());
        }

        if(!eventToParticipantsMap.isEmpty()) {
            sendInvites(eventToParticipantsMap);
        }
        
        /* CCN-EVE-2500-DV XEN REYES 30Jan2023 */
        /* Map<Id, Participant__c> participantList = new Map<Id, Participant__c>();
        if(FlsUtils.isAccessible('Participant__c', new List<String>{'Status__c', 'Event__c', 'Member_Contact__c'})){
            //Send Emails to Participant                                 
            participantList = new Map<Id, Participant__c>([SELECT Id, Status__c, Event__r.Do_Not_Send_Event_Confirmation_email__c, 
                                                           Event__c, Member_Contact__c, Member_Contact__r.Email, Process_from_Event_Page__c,
                                                           (SELECT Id, Status__c, Participant__c FROM Session_Participants__r)
                                                           FROM Participant__c WHERE Id IN: participantIdSet]); 
        }*/

        //CCN-1551 XEN REYES 29 April 2022
        /* List<Participant__c> participantInvited = new List<Participant__c>();
        Map<String, List<Participant__c>> participantMap =  new Map<String, List<Participant__c>>();
        Set<Id> eventIds = new Set<Id>();
        for(Participant__c participant: participantList.values()){
            if(!participant.Event__r.Do_Not_Send_Event_Confirmation_email__c &&
               participant.Status__c == UtilityConstant.PARTICIPANT_STATUS_REGISTERED){
                if(participantMap.containsKey(UtilityConstant.PARTICIPANT_STATUS_REGISTERED)){
                    List<Participant__c> dataList = participantMap.get(UtilityConstant.PARTICIPANT_STATUS_REGISTERED);
                    dataList.add(participant);
                    eventIds.add(participant.Event__c);
                    participantMap.put(UtilityConstant.PARTICIPANT_STATUS_REGISTERED, dataList);
                }
                else{
                    List<Participant__c> dataList = new List<Participant__c>();
                    dataList.add(participant);
                    eventIds.add(participant.Event__c);
                    participantMap.put(UtilityConstant.PARTICIPANT_STATUS_REGISTERED, dataList);
                }
            }
        }
        
        if(!participantMap.isEmpty()){
            system.debug('debug CCN-1414');
            SessionParticipantTriggerUtility.sendEmailToParticipant(participantMap, eventIds);
        } */
        
        /* CCN-EVE-2500-DV XEN REYES 30Jan2023 */
        if(participantIdSet.size() > 0){
             SessionParticipantTriggerUtility.updateParentParticipantStatus(newSessionParticipantMap, participantIdSet);
        } 
        
        // Start CCN-2466 Von Pernicia: Removed logic
        /*if (updateParticipantMilestoneList.size() > 0) {
            SessionParticipantTriggerUtility.updateParticipantMilestoneMetrics(updateParticipantMilestoneList);
        }
        */
        // End CCN-2466 Von Pernicia: Removed logic
        
        //CCN-1551 XEN REYES 29 April 2022, CCN-1028 XR 27 May 2022
        if(!participantIdSet.isEmpty() && !isFromAttendancePage){
            Set<String> participantIdSetStr = (Set<String>) JSON.deserialize(JSON.serialize(participantIdSet), Set<String>.class);
            Set<String> pptIdsExisting = new Set<String>();
            for(Batch_Processor__c bb : [SELECT Id, Record_Id__c, Parameter_1__c, Type__c FROM Batch_Processor__c 
                                            WHERE Record_Id__c IN: participantIdSetStr 
                                            AND Type__c = 'ParticipantEmailCommunicationBatch'
                                            AND Trigger_Source__c = 'ParticipantTriggerHandler'
                                            AND Parameter_1__c =: UtilityConstant.PARTICIPANT_STATUS_REGISTERED]){
                pptIdsExisting.add(bb.Record_Id__c);
            }

            if(!pptIdsExisting.isEmpty()) participantIdSetStr.removeAll(pptIdsExisting);
            if(!participantIdSetStr.isEmpty()) BatchProcessorUtility.insertBatchRecord(participantIdSetStr,'ParticipantEmailCommunicationBatch','ParticipantTriggerHandler',UtilityConstant.PARTICIPANT_STATUS_REGISTERED);
        }

        /* for(Participant__c participant : [SELECT Id, Send_Event_Registration_Notification__c FROM Participant__c WHERE Id IN :participantIdSet]) {
            participant.Send_Event_Registration_Notification__c = true;
            participantsToUpdate.add(participant);
            System.debug('$$$$ participant.Send_Event_Registration_Notification__c: ' + participant.Send_Event_Registration_Notification__c);
        }

        System.debug('$$$$ participantsToUpdate: ' + participantsToUpdate);
        
        // update participantsToUpdate;
        List<Database.SaveResult> updRes = Database.update(participantsToUpdate);
        System.debug('$$$$ updRes: ' + updRes);

        // System.assert(false); */
                                                                         
    }
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  ??           ??                   Initial version.
    * @version   2.0  29-01-2022   VonPernicia          [CCN-496] Added new method "updateParticipantMilestoneMetrics" to call to update Participant Milestone Metics
    *            3.0  23-03-2022   Paolo Quiambao       [CCN934] Replace Domain Name with Domain Name (Event Registration)
    *            4.0  26-06-2022   Von Pernicia         [CCN-EVE-1719-DV] This will pull all canceled session partcipant record to create and send canceled email notification.
    *            5.0  07-07-2022   Rianno Rizarri       [CCN-EVE-1834-DV] Added new method SessionParticipantTriggerUtility.countSessionPartipants to call the method
    * @version   6.0  17-08-2022   JC Espino            [CCN-EVE-1726-DV] Added criteria of when to send Calendar Invite
    * @version   6.0  12-01-2022   Von Pernicia         [CCN-2466] Remove logic that creates records in Batch_Processor__c
    ******************************************************************************/
    public static void onAfterUpdate(List<Session_Participant__c> newSessionParticipantList, Map<Id,Session_Participant__c> newSessionParticipantMap, 
                                     List<Session_Participant__c> oldSessionParticipantList, Map<Id,Session_Participant__c> oldSessionParticipantMap){
            //Start CCN-EVE-1834-DV: Rianno Rizarri
			SessionParticipantTriggerUtility.countSessionPartipants(newSessionParticipantList);
            //End CCN-EVE-1834-DV: Rianno Rizarri
            Set<Id> participantIdSet = new Set<Id>();
			//Gabriel Delvin *08-10-2023* CCN-EVE-3426-DV
            SessionParticipantTriggerUtility.updateContactTitleRank(newSessionParticipantList);
            // Start CCN-2466 Von Pernicia: Removed logic
            //List<Session_Participant__c> updateParticipantMilestoneList = new List<Session_Participant__c>();
            // End CCN-2466 Von Pernicia: Removed logic

            List<Session_Participant__c> sessPartEmailCanceledRec = new List<Session_Participant__c>();
            // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV]
            Map<Id, List<Session_Participant__c>> eventToParticipantsMap = new Map<Id, List<Session_Participant__c>>();

            for(Session_Participant__c sessionParticipant: newSessionParticipantList){
                if(sessionParticipant.Status__c != oldSessionParticipantMap.get(sessionParticipant.Id).Status__c && sessionParticipant.Status__c == 'Confirmed'){
                    // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV] - Added mechanism to check Event field Session_Calendar_Invite_Delivery__c

                    if(!eventToParticipantsMap.containsKey(sessionParticipant.Event__c)) {
                        eventToParticipantsMap.put(sessionParticipant.Event__c, new List<Session_Participant__c>());
                    }
                    eventToParticipantsMap.get(sessionParticipant.Event__c).add(sessionParticipant);        
                    // END [CCN-EVE-1726-DV]
                }
                
                // Start CCN-2466 Von Pernicia: Removed logic
                /*if(sessionParticipant.Status__c != oldSessionParticipantMap.get(sessionParticipant.Id).Status__c && sessionParticipant.Status__c == 'Attended'){
                    updateParticipantMilestoneList.add(sessionParticipant);
                }*/
                // End CCN-2466 Von Pernicia: Removed logic

                // Start CCN-EVE-1719-DV: Von 
                if(sessionParticipant.Status__c != oldSessionParticipantMap.get(sessionParticipant.Id).Status__c && sessionParticipant.Status__c == 'Canceled'){
                    sessPartEmailCanceledRec.add(sessionParticipant);
                }
                // End CCN-EVE-1719-DV: Von 
                
                participantIdSet.add(sessionParticipant.Participant__c);
            }
                                         
            // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV] - gets participants with the correct event settings to send calendar invite
            if(!eventToParticipantsMap.isEmpty()) {
                sendInvites(eventToParticipantsMap);
            }

            // Start CCN-EVE-1719-DV: Von 
            if(!sessPartEmailCanceledRec.isEmpty()){
                SessionParticipantTriggerUtility.sendCalendarCancelation(sessPartEmailCanceledRec);
            }
            // End CCN-EVE-1719-DV: Von
            
            /* CCN-EVE-2500-DV XEN REYES 30Jan2023 */
            /* Map<Id, Participant__c> participantList = new Map<Id, Participant__c>();
            if(FlsUtils.isAccessible('Participant__c', new List<String>{'Status__c', 'Event__c', 'Member_Contact__c'})){                             
                participantList = new Map<Id, Participant__c>([SELECT Id, Status__c, Event__r.Do_Not_Send_Event_Confirmation_email__c, 
                                                               Event__c, Member_Contact__c, Member_Contact__r.Email, Process_from_Event_Page__c,
                                                               (SELECT Id, Status__c, Participant__c FROM Session_Participants__r)
                                                               FROM Participant__c WHERE Id IN: participantIdSet]); 
            } */
            
            /* CCN-EVE-2500-DV XEN REYES 30Jan2023 */
            if(participantIdSet.size() > 0){
                 SessionParticipantTriggerUtility.updateParentParticipantStatus(newSessionParticipantMap, participantIdSet);
            }          
            
            // Start CCN-2466 Von Pernicia: Removed logic
            /*if (updateParticipantMilestoneList.size() > 0) {
                SessionParticipantTriggerUtility.updateParticipantMilestoneMetrics(updateParticipantMilestoneList);
            }*/
            // End CCN-2466 Von Pernicia: Removed logic
            /* Commented out just for deployment, will remove comment after
            //ADDED BY FRANCIS BAGTAS Feb 09 2022 to Log Interaction Record
            List<InteractionTriggerHandler.InteractionWrapper> InteractionWrapperList = new List<InteractionTriggerHandler.InteractionWrapper>();
            InteractionTriggerHandler.InteractionWrapper wrappInteraction;
            for(Session_Participant__c sessionParticipant : [SELECT Id,Event__r.Campaign__c,Event__c,Session__c,Contact__c,Status__c FROM Session_Participant__c WHERE ID IN: newSessionParticipantMap.keySet()]){// Query the Session Participant Object and related/lookup object information
               // If Status field is updated Log Interaction as Session Interaction
                if(sessionParticipant.Status__c != oldSessionParticipantMap.get(sessionParticipant.Id).Status__c){
                  wrappInteraction = new InteractionTriggerHandler.InteractionWrapper();
                    wrappInteraction.recordTypeName = 'Session Interaction';
              wrappInteraction.campaignId = sessionParticipant.Event__r.Campaign__c;
              wrappInteraction.eventId = sessionParticipant.Event__c;
              wrappInteraction.sessionId = sessionParticipant.Session__c;
              wrappInteraction.contactId = sessionParticipant.Contact__c;
                    wrappInteraction.status = sessionParticipant.Status__c;
                    
                    InteractionWrapperList.add(wrappInteraction);
                }
            }
            InteractionTriggerHandler.createInteractionRecord(InteractionWrapperList);
      */
    }
    
    
    public static void onBeforeInsert(List<Session_Participant__c> newSessionParticipantList, Map<Id,Session_Participant__c> newSessionParticipantMap, 
                                      List<Session_Participant__c> oldSessionParticipantList, Map<Id,Session_Participant__c> oldSessionParticipantMap){
            
            // Updated by Paolo Quiambao [CCN-934] Mar232021
            //Compass_Setting__c compassSetting = [SELECT Id, Domain_Name_Event_Registration__c FROM Compass_Setting__c WHERE Name = 'Default Settings' LIMIT 1];
            
      //This is the old logic for 934, to be removed. Brought back so we can test 1191
            Compass_Setting__c compassSetting = [SELECT Id, Domain_Name__c FROM Compass_Setting__c WHERE Name = 'Default Settings' LIMIT 1];

            Set<Id> sessionIdSet = new Set<Id>();
            Map<Id, Session__c> sessionMap = new Map<Id, Session__c>();
            
            for(Session_Participant__c sessionParticipant : newSessionParticipantList) {
                // Updated by Paolo Quiambao [CCN-934] Mar232021
                //sessionParticipant.Domain_Name__c = compassSetting.Domain_Name_Event_Registration__c;

        //This is the old logic for 934, to be removed. Brought back so we can test 1191
                sessionParticipant.Domain_Name__c = compassSetting.Domain_Name__c;
                sessionIdSet.add(sessionParticipant.Session__c);
            }
                                          
            for(Session__c session : [SELECT Id, Session_Attendance_Thank_You_Message__c, Session_Catchup_Message__c, Session_Catchup_Reminder_Message__c, Session_Catchup_Thank_You_Message__c FROM Session__c WHERE Id IN :sessionIdSet]) {
                sessionMap.put(session.Id, session);                                              
            }
                    
            // Updated by Paolo Quiambao [CCN-981] Dec062021
            for(Session_Participant__c sessionParticipant : newSessionParticipantList) {
                sessionParticipant.Session_Attendance_Thank_You_Message__c = sessionMap.get(sessionParticipant.Session__c).Session_Attendance_Thank_You_Message__c;
                sessionParticipant.Session_Catchup_Message__c = sessionMap.get(sessionParticipant.Session__c).Session_Catchup_Message__c;
                sessionParticipant.Session_Catchup_Reminder_Message__c = sessionMap.get(sessionParticipant.Session__c).Session_Catchup_Reminder_Message__c;
                sessionParticipant.Session_Catchup_Thank_You_Message__c = sessionMap.get(sessionParticipant.Session__c).Session_Catchup_Thank_You_Message__c;
                
                // Updated by Paolo Quiambao [CCN-EVE-1219-DV] Apr252022
                if(sessionParticipant.Status__c == 'Confirmed') {
                    sessionParticipant.Confirmed_Date__c = System.now();
                }
                else if(sessionParticipant.Status__c == 'Declined') {
                    sessionParticipant.Declined_Date__c = System.now();
                }

                // UPDATED BY JC Espino [CCN-1038] MAY 24 2022
                if(sessionParticipant.Status__c == 'Attended') {
                    sessionParticipant.Attendance_Date__c = System.now();
                }
            }
    }
    
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  ??           ??                   Initial version.
    * @version   2.0  17-06-2022   VonPernicia          [CCN-EVE-1773-DV] Added new condition if status to populate Canceled Date if status is set to canceled
    ******************************************************************************/
    public static void onBeforeUpdate(List<Session_Participant__c> newSessionParticipantList, Map<Id,Session_Participant__c> newSessionParticipantMap, 
                                      List<Session_Participant__c> oldSessionParticipantList, Map<Id,Session_Participant__c> oldSessionParticipantMap){
        
        // Updated by Paolo Quiambao [CCN-EVE-1219-DV] Apr252022
        for(Session_Participant__c sessionParticipant : newSessionParticipantList) {
            if(oldSessionParticipantMap.get(sessionParticipant.Id).Status__c != sessionParticipant.Status__c && sessionParticipant.Status__c == 'Confirmed' && sessionParticipant.Confirmed_Date__c == null) {
                sessionParticipant.Confirmed_Date__c = System.now();
            }
            else if(oldSessionParticipantMap.get(sessionParticipant.Id).Status__c != sessionParticipant.Status__c && sessionParticipant.Status__c == 'Declined' && sessionParticipant.Declined_Date__c == null) {
                sessionParticipant.Declined_Date__c = System.now();
            }

            // UPDATED BY JC Espino [CCN-1038] MAY 24 2022
            if(sessionParticipant.Attendance_Date__c == null && 
                (oldSessionParticipantMap.get(sessionParticipant.Id).Status__c != 'Attended' && sessionParticipant.Status__c == 'Attended')) {
                sessionParticipant.Attendance_Date__c = System.now();
            }

            // CCN-EVE-1773-DV: Von Pernicia
            if(sessionParticipant.Canceled_Date__c == null && 
                (oldSessionParticipantMap.get(sessionParticipant.Id).Status__c != 'Canceled' && sessionParticipant.Status__c == 'Canceled')) {
                sessionParticipant.Canceled_Date__c = System.now();
            }
        }
    }
    
    /*public static void onBeforeDelete(List<Session_Participant__c> newSessionParticipantList, Map<Id,Session_Participant__c> newSessionParticipantMap, 
                                      List<Session_Participant__c> oldSessionParticipantList, Map<Id,Session_Participant__c> oldSessionParticipantMap){
    }  
    public static void onAfterUndelete(List<Session_Participant__c> newSessionParticipantList, Map<Id,Session_Participant__c> newSessionParticipantMap, 
                                       List<Session_Participant__c> oldSessionParticipantList, Map<Id,Session_Participant__c> oldSessionParticipantMap){
    }  
    */
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    * @version   1.0  07-07-2022   Rianno Rizarri       Initial version. [CCN-EVE-1834-DV] Added new method SessionParticipantTriggerUtility.countSessionPartipants to call the method
    ******************************************************************************/
      public static void onAfterDelete(List<Session_Participant__c> newSessionParticipantList, Map<Id,Session_Participant__c> newSessionParticipantMap,
                                       List<Session_Participant__c> oldSessionParticipantList, Map<Id,Session_Participant__c> oldSessionParticipantMap){
                                           //Start CCN-EVE-1834-DV: Rianno Rizarri
                                           SessionParticipantTriggerUtility.countSessionPartipants(newSessionParticipantList);
                                           //End CCN-EVE-1834-DV: Rianno Rizarri
    }

    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    * @version   1.0  17-08-2022      JC Espino         Initial version. [CCN-EVE-1726-DV] New method to send calendar invites on Session Confirmation
    ******************************************************************************/
    public static void sendInvites(Map<Id, List<Session_Participant__c>> participantsMap) {
        List<Session_Participant__c> sessPartEmailRec = new List<Session_Participant__c>();
        Map<Id, Event__c> eventsMap = new Map<Id, Event__c>([SELECT Id, Session_Calendar_Invite_Delivery__c FROM Event__c WHERE Id IN :participantsMap.keySet() AND Session_Calendar_Invite_Delivery__c = 'Send on session confirmation']);

        for(Id eventId : eventsMap.keySet()) {
            sessPartEmailRec.addAll(participantsMap.get(eventId));
        }

        if(!sessPartEmailRec.isEmpty()){
            SessionParticipantTriggerUtility.sendCalendarInvite(sessPartEmailRec);
        }
    }
}