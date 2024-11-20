public class SessionParticipantTriggerUtility {

    public static Map < String, String > objFieldMap {
        get;
        set;
    }

    /******************************************************************************    
     * Changes (version)
     *            No.  Date(dd-mm-yyy) Author            Description
     *           ----  ---------   --------------------  -----------------------------
     * @version   1.0  07-07-2022   Rianno Rizarri       [CCN-EVE-1834-DV] This method gets the session ids and then passed to a future method.
     * @version   1.1  08-02-2022   Rianno Rizarri		[CCN-EVE-1834-DV] Check if running on asynchronous context and run the method needed for the current system context.
     * 																		This prevent this following error: 'Future method cannot be called from a future or batch method'.
     * @version   1.2  17-08-2022   JC Espino            [CCN-EVE-1726-DV] Added criteria of when to send Calendar Invite
     * @version   1.3  11-29-2023   Rexie David          [CCN-EVE-3566-DV] Meeting Reminder Enhancement
     ******************************************************************************/
    public static void countSessionPartipants(List < Session_Participant__c > newList) {
        Set < Id > SessionIds = new Set < Id > ();
        for (Session_Participant__c seshPart: newList) {
            SessionIds.add(seshPart.Session__c);
        }
        Datetime timeOnTransaction = System.now();

        //Checking if running on asynchronous context
        if (System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled()) {
            countSessionParticipant(SessionIds, timeOnTransaction);
        } else {
            //Run on future context if running on synchronous
            countSessionParticipantFuture(SessionIds, timeOnTransaction);
        }
    }

    /******************************************************************************    
     * Changes (version)
     *            No.  Date(dd-mm-yyy) Author            Description
     *           ----  ---------   --------------------  -----------------------------
     * @version   1.0  08-02-2022   Rianno Rizarri       [CCN-EVE-1834-DV] Call the method on a future context since the process is quite heavy.
     * 													We used the transaction time during the trigger since the future method would happen asynchronously and will run in a later date.
     ******************************************************************************/
    @future
    public static void countSessionParticipantFuture(Set < Id > SessionIds, Datetime timeOnTransaction) {
        countSessionParticipant(SessionIds, timeOnTransaction);
    }
    /******************************************************************************    
     * Changes (version)
     *            No.  Date(dd-mm-yyy) Author            Description
     *           ----  ---------   --------------------  -----------------------------
     * @version   1.0  07-07-2022   Rianno Rizarri       [CCN-EVE-1834-DV] This method counts the Registered and Confirmed Session participants. 
     *                                                   This will only count on sessions that has not started; henced we added the start time filter.
     * @version   1.1  07-18-2022   Rianno Rizarri       [CCN-EVE-1834-DV] Updated query to the correct criteria.
     * @version   1.2  08-02-2022   Rianno Rizarri       [CCN-EVE-1834-DV] Remove future context.
     ******************************************************************************/
    public static void countSessionParticipant(Set < Id > SessionIds, Datetime timeOnTransaction) {
        List < Session__c > sessionList = new List < Session__c > ();
        sessionList = [SELECT Id, (SELECT ID FROM Session_Participants__r WHERE Status__c IN('Registered', 'Confirmed'))
            //Start CCN-EVE-1834-DV 1.1: Rianno Rizarri
            FROM Session__c WHERE ID IN: SessionIds AND Start_Date_Time_on_Timezone__c >=: timeOnTransaction
        ];
        //End CCN-EVE-1834-DV 1.1: Rianno Rizarri
        List < Session__c > sessionToUpdate = new List < Session__c > ();
        for (Session__c sesh: sessionList) {
            Session__c newSesh = new Session__c();
            newSesh.Id = Sesh.Id;
            newSesh.Total_Participants_Registered_New__c = sesh.Session_Participants__r.size();
            sessionToUpdate.add(newSesh);
        }
        Update sessionToUpdate;
    }

    /******************************************************************************
    * @author       ??
    * @date         ??
    * @description  This will send calendar invite
    * @param        newList

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy)    Author               Description
    *           ----  ---------         --------------------  -----------------------------
    * @version   1.0  ??                ??                    ??
    * @version   1.1  10-08-2022        JC Espino             [CCN-1973] - Added Exception logging for sending emails to catch emailing errors
    ******************************************************************************/
    public static void sendCalendarInvite(List < Session_Participant__c > newList) {
        /*Map<String, String> SFTimezone = new Map<String, String>();
        SFTimezone.put('AKDT', 'America/Anchorage');
        SFTimezone.put('AST', 'America/Anchorage');
        SFTimezone.put('CDT', 'America/Chicago');
        SFTimezone.put('CST', 'America/Mexico_City');
        SFTimezone.put('EDT', 'America/New_York');
        SFTimezone.put('EST', 'America/New_York');
        SFTimezone.put('GT', 'Pacific/Gambier');
        SFTimezone.put('HADT', 'America/Adak');
        SFTimezone.put('HAST', 'Pacific/Honolulu');
        SFTimezone.put('MT', 'Pacific/Marquesas');
        SFTimezone.put('MPDT', 'America/Mazatlan');
        SFTimezone.put('MPST', 'America/Mazatlan');
        SFTimezone.put('MDT', 'America/Denver');
        SFTimezone.put('MST', 'America/Denver');
        SFTimezone.put('PDT', 'America/Los_Angeles');
        SFTimezone.put('PST', 'America/Los_Angeles');
        SFTimezone.put('PT', 'Pacific/Pitcairn');*/

        // UPDATED by JC ESPINO [CCN-EVE-1360-DV] - Changed the referenced field from Meeting_URL__c to Location__c
        // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV]- updated query to select only those who haven't received a calendar invite yet
        List < Session_Participant__c > sessionList = [SELECT Id, Name, Contact__c, Contact__r.Email, Status__c,
            Event__r.Location__r.Name, Event__r.Email_Sender_Id__c, Event__r.Email_Sender_Name__c,
            Session__r.Name, Session__r.Subtitle__c,
            Session__r.Time_Zone__c, Session__r.Description__c, Session__r.Meeting_Info__c, Session__r.Meeting_URL__c, Session__r.Location__c,
            Session__r.Start_Date_Time__c, Session__r.End_Date_Time__c, Session__r.Do_Not_Send_Calendar_Invite__c, Event__r.Session_Calendar_Invite_Delivery__c, Sent_Calendar_Invite__c, Event_Invite_Delivery_Option__c
            FROM Session_Participant__c
            WHERE Id IN: newList AND
            Sent_Calendar_Invite__c = false
        ];

        // UPDATED BY JC ESPINO CCN-EVE-1191-DV MAR172022
        // Rewrote email creation as another method to be able to reuse
        List < Messaging.SingleEmailMessage > emails = new List < Messaging.SingleEmailMessage > ();
        if (sessionList.isEmpty()) {
            return;
        }

        emails.addAll(createEmails(sessionList));

        for (Session_Participant__c newSession: sessionList) {
            newSession.Sent_Calendar_Invite__c = (!newSession.Session__r.Do_Not_Send_Calendar_Invite__c &&
                ((newSession.Status__c == 'Confirmed' ||
                        (newSession.Status__c == 'Registered' && newSession.Event_Invite_Delivery_Option__c == 'Send on session registration')) &&
                    newSession.Contact__c != null &&
                    newSession.Contact__r.Email != null));
        }

        update sessionList;

        // UPDATED BY JC ESPINO CCN-1973 AUG102022
        // Added Exception logging for sending emails
        List < Messaging.SendEmailResult > sendEmailResults = new List < Messaging.SendEmailResult > ();
        try {
            sendEmailResults = Messaging.sendEmail(emails);
        } catch (System.EmailException e) {
            UTIL_LoggingService.logHandledException(e);
        }
    }

    /******************************************************************************
    * @author       Von Pernicia
    * @date         23-06-2022
    * @description  This will pull cancelled session participant records
    * @param        participants

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy)    Author               Description
    *           ----  ---------         --------------------  -----------------------------
    * @version   1.0  23-06-2022        Von Pernicia          [CCN-EVE-1719-DV] Initial version: This will pull canceled session participant records.
    ******************************************************************************/
    public static void sendCalendarCancelation(List < Session_Participant__c > newList) {

        List < Session_Participant__c > sessionList = [SELECT Id, Name, Contact__c, Contact__r.Email, Status__c,
            Event__r.Location__r.Name, Event__r.Email_Sender_Id__c, Event__r.Email_Sender_Name__c,
            Session__r.Name, Session__r.Subtitle__c,
            Session__r.Time_Zone__c, Session__r.Description__c, Session__r.Meeting_Info__c, Session__r.Meeting_URL__c, Session__r.Location__c,
            Session__r.Start_Date_Time__c, Session__r.End_Date_Time__c, Session__r.Do_Not_Send_Calendar_Invite__c
            FROM Session_Participant__c
            WHERE Id IN: newList AND Session__r.Do_Not_Send_Calendar_Invite__c = false
        ];

        List < Messaging.SingleEmailMessage > emails = new List < Messaging.SingleEmailMessage > ();
        if (sessionList.isEmpty()) {
            return;
        }

        emails.addAll(createEmails(sessionList));
        Messaging.SendEmailResult[] er = Messaging.sendEmail(emails);
    }


    /*******************************************************************************
     * @author       Kyzer Buhay
     * @date         06.01.2021
     * @description  Send emails to Participants after insert of Session Participants. 
     *******************************************************************************/
    public static void sendEmailToParticipant(Map < String, List < Participant__c >> participantMap, Set < Id > eventIds) {
        /*Map<Id, Event__c> eventsMap = new Map<Id, Event__c>([SELECT Id, Email_Sender_Id__c, Email_Sender_Name__c, Email_Message_CC__c, 
                                                             Email_Message_BCC__c FROM Event__c WHERE Id =: eventIds]);
        
        Map<Id, OrgWideEmailAddress> owea = new Map<Id, OrgWideEmailAddress>([SELECT Id FROM OrgWideEmailAddress]);
        Compass_Setting__c compS = [SELECT Id, Name, Email_Template_Invitation_Id__c, Email_Template_Registration_Id__c 
                                    FROM Compass_Setting__c WHERE Name = 'Default Settings']; 
               
        if(participantMap.containsKey(UtilityConstant.PARTICIPANT_STATUS_RESPONDED)){
            Id eventRegistrationTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName =: UtilityConstant.EMAIL_TEMPLATE_CONFIRMATION_NAME].Id;
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>(); 
            
            for(Participant__c participant: participantMap.get(UtilityConstant.PARTICIPANT_STATUS_RESPONDED)){
                String emailTemplateId = compS.Email_Template_Registration_Id__c != null ? compS.Email_Template_Registration_Id__c : eventRegistrationTemplate;
                String emailSenderId = eventsMap.get(participant.Event__c).Email_Sender_Id__c;
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setOrgWideEmailAddressId(eventsMap.get(participant.Event__c).Email_Sender_Id__c);
                message.setSaveAsActivity(false);
                message.setWhatId(participant.Id);
                message.setTemplateId(emailTemplateId);
                message.setTargetObjectId(participant.Member_Contact__c);
                emails.add(message);
            }
            Messaging.sendEmail(emails); 
        }*/
    }


    /*******************************************************************************
     * @author       Kyzer Buhay
     * @date         06.14.2021
     * @description  Update Parent Participant Record Status
     * @Params       Session Participant Record List, Participant Record Map
     * 
     * Changes (version)
     *            No.  Date(dd-mm-yyy) Author            Description
     *           ----  ---------       --------------------  -----------------------------
     * @version   1.0  14-06-2021      Kyzer Buhay          Initial version.
     * @version   2.0  17-06-2022      Von Pernicia         [CCN-EVE-1773-DV] - Updated status value from Cancelled to Canceled
     * @version   3.0  30-01-2023      Xen Reyes            [CCN-EVE-2500-DV] - Updated criteria, refactor method
     *******************************************************************************/
    public static void updateParentParticipantStatus(Map<Id,Session_Participant__c> newSessionParticipantMap, Set<Id> participantIdSet) {

        /* CCN-EVE-2500-DV XEN REYES 30Jan2023 */

        /* Map < String, List < Session_Participant__c >> participantSessionStatusMap = new Map < String, List < Session_Participant__c >> ();
        for (Participant__c participantRec: participantsMap.values()) {
            List < Session_Participant__c > sessParticipantList = new List < Session_Participant__c > ();
            for (Session_Participant__c sessParticipant: participantRec.Session_Participants__r) {
                if (participantSessionStatusMap.containsKey(sessParticipant.Participant__c + '|' + sessParticipant.Status__c)) {
                    List < Session_Participant__c > tempoSessionPartContainer = participantSessionStatusMap.get(sessParticipant.Participant__c + '|' + sessParticipant.Status__c);
                    tempoSessionPartContainer.add(sessParticipant);
                    participantSessionStatusMap.put(sessParticipant.Participant__c + '|' + sessParticipant.Status__c, tempoSessionPartContainer);
                } else {
                    participantSessionStatusMap.put(sessParticipant.Participant__c + '|' + sessParticipant.Status__c, new List < Session_Participant__c > {
                        sessParticipant
                    });
                }
            }
        }

        Map < Id, Participant__c > participantsToUpdateMap = new Map < Id, Participant__c > ();
        for (Session_Participant__c sessionParticipant: sessionParticipants) {

            // Added by DinoBtinas [CCN1153] - Feb012022
            // This is to  fix the issue on the sessionParticipant.Participant__c is nulling during the proccess
            if (sessionParticipant.Participant__c < > null) {
                Participant__c participantRec = participantsMap.get(sessionParticipant.Participant__c);
                if ((   participantSessionStatusMap.get(sessionParticipant.Participant__c + '|' + sessionParticipant.Status__c) != null &&
                        participantSessionStatusMap.get(sessionParticipant.Participant__c + '|' + sessionParticipant.Status__c).size() == participantsMap.get(sessionParticipant.Participant__c).Session_Participants__r.size()) ||
                        participantsMap.get(sessionParticipant.Participant__c).Session_Participants__r.size() == 0) {

                        if (sessionParticipant.Status__c == 'Registered' &&
                            participantsMap.get(sessionParticipant.Participant__c).Status__c != 'Registered') {
                            participantRec.Status__c = 'Registered';
                            participantRec.Process_from_Event_Page__c = false;
                        } else if (sessionParticipant.Status__c == 'Attended' &&
                            participantsMap.get(sessionParticipant.Participant__c).Status__c != 'Attended') {
                            participantRec.Status__c = 'Attended';
                        } else if (sessionParticipant.Status__c == 'Canceled' && // CCN-EVE-1773-DV
                            participantsMap.get(sessionParticipant.Participant__c).Status__c != 'Canceled') { // CCN-EVE-1773-DV
                            participantRec.Status__c = 'Canceled'; // CCN-EVE-1773-DV
                        }
                } else {
                    participantRec.Status__c = 'In Progress';
                }
                participantsToUpdateMap.put(participantRec.Id, participantRec);
            }
        } */
        
        ElevatedContext elevClass = new ElevatedContext();
        Map<Id, Participant__c> participantsMap = elevClass.getParticipantRecords(participantIdSet);
        
        List<Participant__c> participantsToUpdateList = new List<Participant__c>();

        //Collect all session participants per Participant from the queried records
        Map<Id, List<Session_Participant__c>> participantRecSessionParticipantListMap = new Map<Id, List<Session_Participant__c>>();
        for(Participant__c participantRec: participantsMap.values()) {
            if(!participantRec.Session_Participants__r.isEmpty()) participantRecSessionParticipantListMap.put(participantRec.Id, participantRec.Session_Participants__r);
        }

        //Combine all session participants newMap to the initial list and replace the queried records with the newMap records (latest)
        Map<Id, Set<String>> participantIdStatusSet = new Map<Id, Set<String>>();
        for(Session_Participant__c sp : newSessionParticipantMap.values()){
            if(sp.Participant__c == null) continue;
            if(participantRecSessionParticipantListMap.containsKey(sp.Participant__c)){
                List<Session_Participant__c> listSessionParticipant = participantRecSessionParticipantListMap.get(sp.Participant__c);
                for(Integer i = 0; i <= listSessionParticipant.size() - 1; i++){
                    Session_Participant__c spFin = listSessionParticipant[i];
                    if(spFin.Id == sp.Id) spFin = sp;
                    if(participantIdStatusSet.containsKey(spFin.Participant__c)){
                        participantIdStatusSet.get(spFin.Participant__c).add(spFin.Status__c);
                    } else {
                        participantIdStatusSet.put(spFin.Participant__c, new Set<String>{spFin.Status__c});
                    }
                }
            } else {
                //First session participant in an existing participant
                participantRecSessionParticipantListMap.put(sp.Participant__c, new List<Session_Participant__c>{sp});
                if(participantIdStatusSet.containsKey(sp.Participant__c)){
                    participantIdStatusSet.put(sp.Participant__c, new Set<String>{sp.Status__c});
                } else {
                    participantIdStatusSet.get(sp.Participant__c).add(sp.Status__c);
                }
            }
        }

        System.debug('participantIdStatusSet: ' + participantIdStatusSet);

        //Evaluate the map of lists Session participant status based on the order of criteria, get the set of status value strings on each then evaluate
        for(Id participantId : participantIdStatusSet.keySet()){
            Participant__c updateRec = new Participant__c(Id = participantId);
            if(participantIdStatusSet.get(participantId).contains('Attended')) updateRec.Status__c = 'Attended';
            else if(participantIdStatusSet.get(participantId).contains('Catchup')) updateRec.Status__c = 'Catch-up';
            else if(participantIdStatusSet.get(participantId).contains('Confirmed')) updateRec.Status__c = 'Confirmed';
            else if(participantIdStatusSet.get(participantId).contains('Registered')) updateRec.Status__c = 'Registered';
            else if(participantIdStatusSet.get(participantId).contains('Missed')) updateRec.Status__c = 'Missed';
            else if(participantIdStatusSet.get(participantId).contains('Declined')) updateRec.Status__c = 'Declined';
            else if(participantIdStatusSet.get(participantId).contains('Canceled') && participantIdStatusSet.get(participantId).size() == 1) updateRec.Status__c = 'Canceled';
            participantsToUpdateList.add(updateRec);
        }

        if (participantsToUpdateList.size() > 0) {
            elevClass.updateParticipants(participantsToUpdateList);
        }
    }

    /******************************************************************************
    * @author       Von Pernicia
    * @date         12-01-2023
    * @description  Created new method to bypass trigger recursive
    * @param        sessionParticipants

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy)    Author               Description
    *           ----  ---------         --------------------  -----------------------------
    * @version   1.0  12-01-2023        Von Pernicia          [CCN-2466] Created new method to bypass trigger recursive .
                 1.0  16-01-2023        Xen Reyes             [CCN-2488] Added criteria to create batch processor record for inserted session participant
    ******************************************************************************/
    public static void onAfterInsertSessionParticipant(List < Session_Participant__c > newSessionParticipantList) {

        List < Session_Participant__c > updateParticipantMilestoneList = new List < Session_Participant__c > ();

        for (Session_Participant__c sessionParticipant: newSessionParticipantList) {

            if (
                (!String.isEmpty(String.valueOf(sessionParticipant.Registration_Date__c)) && (sessionParticipant.Status__c == 'Registered' || sessionParticipant.Status__c == 'Invited')) ||
                (!String.isEmpty(String.valueOf(sessionParticipant.Attendance_Date__c)) && sessionParticipant.Status__c == 'Attended') //CCN-2488

            ) {
                updateParticipantMilestoneList.add(sessionParticipant);
            }
        }

        if (updateParticipantMilestoneList.size() > 0) {
            updateParticipantMilestoneMetrics(updateParticipantMilestoneList);
        }
    }

    /******************************************************************************
    * @author       Von Pernicia
    * @date         12-01-2023
    * @description  Created new method to bypass trigger recursive
    * @param        sessionParticipants

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy)    Author               Description
    *           ----  ---------         --------------------  -----------------------------
    * @version   1.0  12-01-2023        Von Pernicia          [CCN-2466] Created new method to bypass trigger recursive .
    ******************************************************************************/
    public static void onAfterUpdateSessionParticipant(List < Session_Participant__c > newSessionParticipantList, Map < Id, Session_Participant__c > oldSessionParticipantMap) {

        List < Session_Participant__c > updateParticipantMilestoneList = new List < Session_Participant__c > ();

        for (Session_Participant__c sessionParticipant: newSessionParticipantList) {

            if (sessionParticipant.Status__c != oldSessionParticipantMap.get(sessionParticipant.Id).Status__c && sessionParticipant.Status__c == 'Attended') {
                updateParticipantMilestoneList.add(sessionParticipant);
            }
        }

        if (updateParticipantMilestoneList.size() > 0) {
            updateParticipantMilestoneMetrics(updateParticipantMilestoneList);
        }
    }

    /******************************************************************************
    * @author       Von Pernicia
    * @date         29-01-2022
    * @description  Update Participant Milestone Metric base on the updated date field in Session Participant
    * @param        sessionParticipants

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy)    Author               Description
    *           ----  ---------         --------------------  -----------------------------
    * @version   1.0  29-01-2022        Von Pernicia          [CCN-496] Initial version.
    ******************************************************************************/
    public static void updateParticipantMilestoneMetrics(List < Session_Participant__c > sessionParticipants) {

        Map < String, List < String >> journeyIdMap = new Map < String, List < String >> ();

        for (Adhoc_Journey_Assignment__c adhoc: [SELECT id, Journey__c
                FROM Adhoc_Journey_Assignment__c
                WHERE Event__c in (SELECT Event__c FROM Session_Participant__c WHERE id in: sessionParticipants AND Event__r.Milestone__c = true AND Event__r.IsActive__c = true)
            ])

        {
            if (!journeyIdMap.containsKey(adhoc.Journey__c)) {
                List < String > contactIdList = new List < String > ();
                for (Session_Participant__c participant: sessionParticipants) {
                    contactIdList.add(participant.Contact__c);
                }
                journeyIdMap.put(adhoc.Journey__c, contactIdList);
            }
        }

        if (!journeyIdMap.isEmpty()) {
            BatchProcessorUtility.insertBatchRecord(journeyIdMap, 'BatchSyncParticipantMilestoneMetric', 'SessionParticipantTriggerUtility');
        }
    }

    /******************************************************************************
    * @author       Von Pernicia
    * @date         29-01-2022
    * @description  Update Participant Milestone Metric base on the updated date field in Participant
    * @param        participants

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy)    Author               Description
    *           ----  ---------         --------------------  -----------------------------
    * @version   1.0  29-01-2022        Von Pernicia          [CCN-496] Initial version.
    ******************************************************************************/
    public static void updateParticipantMilestoneMetrics(List < Participant__c > participants) {

        Map < String, List < String >> journeyIdMap = new Map < String, List < String >> ();

        for (Adhoc_Journey_Assignment__c adhoc: [SELECT id, Journey__c
                FROM Adhoc_Journey_Assignment__c
                WHERE Event__c in (SELECT Event__c FROM Participant__c WHERE id in: participants AND Event__r.Milestone__c = true AND Event__r.IsActive__c = true)
            ])

        {
            if (!journeyIdMap.containsKey(adhoc.Journey__c)) {
                List < String > contactIdList = new List < String > ();
                for (Participant__c participant: participants) {
                    contactIdList.add(participant.Member_Contact__c);
                }
                journeyIdMap.put(adhoc.Journey__c, contactIdList);
            }

            // Create Map of Journey Id and List Contact Ids
        }

        if (!journeyIdMap.isEmpty()) {
            BatchProcessorUtility.insertBatchRecord(journeyIdMap, 'BatchSyncParticipantMilestoneMetric', 'ParticipantTriggerHandler');

            // Insert Contact ID (as record Id) and new field (journey Id)
        }
    }

    without sharing class ElevatedContext {
        public void updateParticipants(List < Participant__c > participantList) {
            update participantList;
        }

        public Map<Id, Participant__c> getParticipantRecords(Set<Id> participantIdSet){
            return new Map<Id, Participant__c>([SELECT Id, Status__c, Event__r.Do_Not_Send_Event_Confirmation_email__c, 
            Event__c, Member_Contact__c, Member_Contact__r.Email, Process_from_Event_Page__c,
            (SELECT Id, Status__c, Participant__c FROM Session_Participants__r)
            FROM Participant__c WHERE Id IN: participantIdSet]); 
        }
    }

    //
    /******************************************************************************
    * @author       n/a
    * @date         n/a
    * @description  Called by SessionTriggerHandler to send updated calendar invite
    * @param        sessionIds

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy)    Author               Description
    *           ----  ---------         --------------------  -----------------------------
    * @version   1.0  29-01-2022        N/A                   ??
    *            2.0  23-06-2022        JC Espino             [CCN-EVE-1191-DV]
    *            3.0  21-11-2022        JC Espino             [CCN-EVE-2326-DV] - updated criteria to use Can_Receive_Updated_Calendar_Invite__c to determine Participant Sessions to receive updated email
    ******************************************************************************/
    @Future
    public static void sendUpdatedCalendarInvite(Set < Id > sessionIds) {
        List < Session_Participant__c > confirmedSessionParticpants = [SELECT Id, Name, Contact__c, Contact__r.Email, Status__c, Session__c, Can_Receive_Updated_Calendar_Invite__c,
            Event__r.Location__r.Name, Event__r.Email_Sender_Id__c, Event__r.Email_Sender_Name__c,
            Session__r.Name, Session__r.Subtitle__c,
            Session__r.Time_Zone__c, Session__r.Description__c, Session__r.Meeting_Info__c, Session__r.Meeting_URL__c,
            Session__r.Start_Date_Time__c, Session__r.End_Date_Time__c, Session__r.Do_Not_Send_Calendar_Invite__c, Session__r.LastModifiedDate
            FROM Session_Participant__c WHERE Can_Receive_Updated_Calendar_Invite__c = true AND Session__c IN: sessionIds
        ];
        Messaging.SendEmailResult[] er = Messaging.sendEmail(createEmails(confirmedSessionParticpants));
    }
    // @Future
    // public static void sendUpdatedCalendarInvite(List<Id> confirmedSessionParticpants) {
    //     Messaging.SendEmailResult[] er = Messaging.sendEmail(createEmails(confirmedSessionParticpants));
    // }

    /******************************************************************************
    * @author       N/a
    * @date         n/a
    * @description  Called by sendUpdatedCalendarInvite, sendCalendarInvite and sendCalendarCancelation to create ics to be send to session participant
    * @param        sessionParticipants

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy)    Author               Description
    *           ----  ---------         --------------------  -----------------------------
    * @version   1.0  29-01-2022        N/A                   ?? Initial version
    *            2.0  23-06-2022        Von Pernicia          [CCN-EVE-1719-DV] create and send canceled email notification.
    ******************************************************************************/
    public static List < Messaging.SingleEmailMessage > createEmails(List < Session_Participant__c > sessionParticipants) {
        List < Messaging.SingleEmailMessage > emailsToSend = new List < Messaging.SingleEmailMessage > ();

        String TimeZoneSidKey = [SELECT Id, TimeZoneSidKey FROM Organization].TimeZoneSidKey;

        //OrgWideEmail
        List < OrgWideEmailAddress > orgwide = [SELECT id, Address, DisplayName FROM OrgWideEmailAddress];
        Map < String, OrgWideEmailAddress > orgwideMap = new Map < String, OrgWideEmailAddress > ();
        for (OrgWideEmailAddress o: orgwide) {
            orgwideMap.put(o.id, o);
        }

        Map < String, String > SFTimezone = new Map < String, String > ();
        for (SFTimezone__mdt s: [SELECT Id, MasterLabel, DeveloperName, Timezone_Name__c FROM SFTimezone__mdt]) {
            SFTimezone.put(s.MasterLabel, s.Timezone_Name__c);
        }

        // UPDATED BY JC ESPINO MAY052023 [CCN-2964] - Fix for Time Zone issue on Calendar Invites
        // Get Custom Metadata for Time Zone offsets
        Map<String, Time_Zone_Offset__mdt> TZOffsets = Time_Zone_Offset__mdt.getAll();

        Timezone tz;
        String timeZoneUpdate = '';

        for (Session_Participant__c sp: sessionParticipants) {
            // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV] - Registered participants are now eligible for calendar invites
            if (!sp.Session__r.Do_Not_Send_Calendar_Invite__c &&
                ((sp.Status__c == 'Confirmed' || sp.Status__c == 'Canceled' || sp.Status__c == 'Registered') && // CCN-EVE-1719-DV added Canceled
                    sp.Contact__c != null &&
                    sp.Contact__r.Email != null
                )
            ) {

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setOrgWideEmailAddressId(sp.Event__r.Email_Sender_Id__c);
                mail.setToAddresses(new List < String > {
                    sp.Contact__r.Email
                });
                // CCN-EVE-1719-DV Start added if condition
                // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV] - updated if else condition to include Registered participants
                if (sp.Status__c == 'Canceled') {
                    mail.setSubject('Canceled: ' + sp.Session__r.Name);
                } else {
                    mail.setSubject(sp.Session__r.Name);
                }
                // CCN-EVE-1719-DV End added if condition

                mail.setHtmlBody((sp.Session__r.Meeting_Info__c != null ? sp.Session__r.Meeting_Info__c : '') + '<br/>' /* (sp.Session__r.Meeting_Info__c != null ? sp.Session__r.Meeting_Info__c : '')*/ );
                mail.setSaveAsActivity(true);
                mail.setTargetObjectId(sp.Contact__c);

                DateTime startDT = sp.Session__r.Start_Date_Time__c;
                DateTime endDT = sp.Session__r.End_Date_Time__c;
                DateTime modifiedDT = System.now(); //sp.Session__r.LastModifiedDate;

                String startDTGMT = startDT.format('MM/dd/yyyy/HH/mm/ss', TimeZoneSidKey);
                String endDTGMT = endDT.format('MM/dd/yyyy/HH/mm/ss', TimeZoneSidKey);
                String modifiedDTGMT = modifiedDT.format('MM/dd/yyyy/HH/mm/ss', TimeZoneSidKey);

                List < String > startDTtz = startDTGMT.split('/');
                List < String > endDTtz = endDTGMT.split('/');
                List < String > modifiedDTtz = modifiedDTGMT.split('/');

                DateTime startDTNew = DateTime.newInstanceGMT(Integer.valueOf(startDTtz[2]), Integer.valueOf(startDTtz[0]), Integer.valueOf(startDTtz[1]), Integer.valueOf(startDTtz[3]),
                    Integer.valueOf(startDTtz[4]), Integer.valueOf(startDTtz[5]));
                DateTime endDTNew = DateTime.newInstanceGMT(Integer.valueOf(endDTtz[2]), Integer.valueOf(endDTtz[0]), Integer.valueOf(endDTtz[1]), Integer.valueOf(endDTtz[3]),
                    Integer.valueOf(endDTtz[4]), Integer.valueOf(endDTtz[5]));

                DateTime modifiedDTNew = DateTime.newInstanceGMT(Integer.valueOf(modifiedDTtz[2]), Integer.valueOf(modifiedDTtz[0]), Integer.valueOf(modifiedDTtz[1]), Integer.valueOf(modifiedDTtz[3]),
                    Integer.valueOf(modifiedDTtz[4]), Integer.valueOf(modifiedDTtz[5]));

                // UPDATED BY JC ESPINO MAY052023 [CCN-2964] - Fix for Time Zone issue on Calendar Invites
                // Apply offset from Custom Metadata
                Integer offset = (Integer) (TZOffsets.get(sp.Session__r.Time_Zone__c).Offset__c * 60);
                startDT = startDTNew.addMinutes(-offset);
                endDT = endDTNew.addMinutes(-offset);
                modifiedDT = modifiedDTNew.addMinutes(-offset);


                String startDTConverted = startDT.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
                String endDTConverted = endDT.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
                String modifiedDTConverted = modifiedDT.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');

                //Create Meeting Body
                String meetingInviteBody = '';
                meetingInviteBody += 'BEGIN:VCALENDAR\n';
                meetingInviteBody += 'PRODID:-//Microsoft Corporation//Outlook 12.0 MIMEDIR//EN\n';
                meetingInviteBody += 'VERSION:2.0\n';

                // CCN-EVE-1719-DV Start added if condition
                // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV] - updated if else condition to include Registered participants
                if (sp.Status__c == 'Canceled') {
                    meetingInviteBody += 'METHOD:CANCEL\n';
                } else {
                    meetingInviteBody += 'METHOD:REQUEST\n';
                    //meetingInviteBody += 'STATUS:CANCELLED\n';
                }
                // CCN-EVE-1719-DV End added if condition

                meetingInviteBody += 'CALSCALE:GREGORIAN\n';
                meetingInviteBody += 'X-MS-OLK-FORCEINSPECTOROPEN:TRUE\n';
                meetingInviteBody += 'BEGIN:VEVENT\n';
                meetingInviteBody += 'CLASS:PUBLIC\n';
                meetingInviteBody += 'CREATED:' + modifiedDTConverted + '\n';
                meetingInviteBody += 'ORGANIZER;CN=' + sp.Event__r.Email_Sender_Name__c + ':MAILTO:' + orgwideMap.get(sp.Event__r.Email_Sender_Id__c).Address + '\n';
                meetingInviteBody += 'DTEND:' + endDTConverted + '\n';
                meetingInviteBody += 'DTSTAMP:' + modifiedDTConverted + '\n';
                meetingInviteBody += 'DTSTART:' + startDTConverted + '\n';
                meetingInviteBody += 'LAST-MODIFIED:' + modifiedDTConverted + '\n';
                meetingInviteBody += 'LOCATION:' + (sp.Session__r.Meeting_URL__c != null ? sp.Session__r.Meeting_URL__c : sp.Event__r.Location__r.Name) + '\n';
                meetingInviteBody += 'PRIORITY:5\n';
                meetingInviteBody += 'SEQUENCE:0\n';
                meetingInviteBody += 'SUMMARY:' + (sp.Session__r.Name != null ? sp.Session__r.Name : '') + '\n';
                meetingInviteBody += 'DESCRIPTION:' + (sp.Session__r.Meeting_Info__c != null ? sp.Session__r.Meeting_Info__c : '') + '\n';
                meetingInviteBody += 'LANGUAGE=en-us:Meeting\n';
                meetingInviteBody += 'TRANSP:OPAQUE\n';
                meetingInviteBody += 'UID:4036587160834EA4AE7848CBD028D1D200000000000000000000000000000000' + sp.Id + '\n';
                meetingInviteBody += 'X-ALT-DESC;FMTTYPE=text/html:<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN"><HTML><HEAD><META NAME="Generator" CONTENT="MS Exchange Server version 08.00.0681.000"><TITLE></TITLE></HEAD><BODY><!-- Converted from text/plain format -->' + sp.Session__r.Meeting_Info__c + '</BODY></HTML>\n';

                meetingInviteBody += 'X-MICROSOFT-CDO-IMPORTANCE:1\n';
                //CCN-EVE-3566-DV START RDAVID 11/29/2023
                meetingInviteBody += 'BEGIN:VALARM\n';
                meetingInviteBody += 'ACTION:DISPLAY\n';
                meetingInviteBody += 'DESCRIPTION:'+ (sp.Session__r.Name != null ? sp.Session__r.Name : '') + '\n';
                meetingInviteBody += 'TRIGGER:-PT15M\n';
                meetingInviteBody += 'END:VALARM\n';
                //CCN-EVE-3566-DV END RDAVID 11/29/2023
                meetingInviteBody += 'END:VEVENT\n';
                meetingInviteBody += 'END:VCALENDAR';

                //Meeting Email Attachment
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.Filename = 'meeting.ics';
                // CCN-EVE-1719-DV Start added if condition
                // UPDATED BY JC ESPINO AUG162022 [CCN-EVE-1726-DV] - updated if else condition to include Registered participants
                if (sp.Status__c == 'Canceled') {
                    attach.ContentType = 'text/calendar; charset=utf-8; method=CANCEL';
                } else {
                    attach.ContentType = 'text/calendar; charset=utf-8; method=REQUEST';
                }
                attach.Inline = true;
                attach.Body = Blob.valueOf(meetingInviteBody);

                //Attach Meeting Attachment
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {
                    attach
                });
                emailsToSend.add(mail);
            }
        }

        return emailsToSend;
    }
    //Gabriel Delvin *08-10-2023* CCN-EVE-3426-DV
    Public static void updateContactTitleRank(List <Session_Participant__c> sessionParticipants){
        List<Contact> conRecList = new List<Contact>();
        Set<Id> conIdSet = new Set<Id>();
        Map<Id,String> TitleRankValueMap = new Map<Id,String>();
        for(Session_Participant__c sessionPartRec: sessionParticipants){
            if(sessionPartRec.Rank__c != null){
                conIdSet.add(sessionPartRec.Contact__c);
                TitleRankValueMap.put(sessionPartRec.Contact__c, sessionPartRec.Rank__c); 
            }
            
        }
        if(conIdSet.Size()>0){
            conRecList = [Select Id, Title from Contact where Id IN: conIdSet];
            
            for(Contact conRec: conRecList){
                conRec.Title = TitleRankValueMap.get(conRec.Id);
            }  
        }
        
        
        database.update(conRecList);
    }

}