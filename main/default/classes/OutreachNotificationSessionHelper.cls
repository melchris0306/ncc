/*******************************************************************************
 * @author       Angelo Rivera
 * @date          01.10.2021
 * @description  [CCN-842, CCN-1059, CCN-1060, CCN-1061] Helper class for BatchOutreachNotificationCC
 * @revision      10.10.2021 - APRivera - Created
 *******************************************************************************/

public without sharing class OutreachNotificationSessionHelper {

    /* ***************************************************************************** */
    public static String processSessions(){
        Map<Id, Session__c> mapSessionById = new Map<Id,Session__c>();
        mapSessionById = getSessions();
        if(!mapSessionById.isEmpty()){
            // retrieve all Outreach Notification linked to Events
            Map<Id, List<Outreach_Notification_Setting__c>> mapOutreachNotificationSettingsByOutreachNotificationIds = new Map<Id, List<Outreach_Notification_Setting__c>>();
            mapOutreachNotificationSettingsByOutreachNotificationIds = OutreachNotificationHelper.getOutreachNotificationSettings();

            // retrieve all Session Participants
            Map<Id, List<Session_Participant__c>> mapSessionParticipantsBySessionIds = new Map<Id, List<Session_Participant__c>>();
            mapSessionParticipantsBySessionIds = getSessionParticipants(mapSessionById.keySet());

            List<Outreach_Notification_History__c> lstOutreachNotificationHistories = new List<Outreach_Notification_History__c>();
            // iterate on Session records
            for(Session__c session : mapSessionById.values()){
                if(session.Outreach_Notification__c != null){
                    System.debug(LoggingLevel.DEBUG, '!@# Processing Session:' + session.Name + ' - Catchup: ' + session.Catch_up__c);
                    processSessionOutreachNotifications(session, mapSessionParticipantsBySessionIds,mapOutreachNotificationSettingsByOutreachNotificationIds,lstOutreachNotificationHistories);
                    System.debug(LoggingLevel.DEBUG, ' !@# lstOutreachNotificationHistories:' + lstOutreachNotificationHistories.size());
                }
            }

            //try{
                if(!lstOutreachNotificationHistories.isEmpty()){
                    Database.insert(lstOutreachNotificationHistories);
                }
            //}catch (Exception ex){
                //System.debug(LoggingLevel.DEBUG, ' !@# ERROR:' + ex.getTypeName() + ' - ' + ex.getMessage());
            //}
        }
        return 'Process Complete!';
    }

    /* ***************************************************************************** */
    public static void processSessionOutreachNotifications(Session__c session, Map<Id, List<Session_Participant__c>> mapSessionParticipantsBySessionIds,
            Map<Id, List<Outreach_Notification_Setting__c>> mapOutreachNotificationSettingsByOutreachNotificationIds,
            List<Outreach_Notification_History__c> lstNewOutreachNotificationHistories){

        List<Outreach_Notification_Setting__c> lstOutreachNotificationSettings = new List<Outreach_Notification_Setting__c>();
        lstOutreachNotificationSettings = mapOutreachNotificationSettingsByOutreachNotificationIds.get(session.Outreach_Notification__c);
        if(!lstOutreachNotificationSettings.isEmpty()){
            Outreach_Notification_Setting__c outreachSessionCatchupSetting = new Outreach_Notification_Setting__c();
            Outreach_Notification_Setting__c outreachSessionCatchupReminderSetting = new Outreach_Notification_Setting__c();
            Outreach_Notification_Setting__c outreachSessionAttendanceThankYouSetting = new Outreach_Notification_Setting__c();
            Outreach_Notification_Setting__c outreachSessionCatchThankYouSetting = new Outreach_Notification_Setting__c();
            Boolean bOutreachSessionCatchupSettingFound = false, bOutreachSessionCatchupReminderSettingFound = false, bOutreachAttendanceThankYouSettingFound = false,  bOutreachCatchupThankYouSettingFound = false;
            // retrieve outreach notification setting to be used
            for(Outreach_Notification_Setting__c ons : lstOutreachNotificationSettings){
                if(ons.Type__c == Label.Outreach_Notification_Session_Catchup){
                    outreachSessionCatchupSetting = ons;
                    bOutreachSessionCatchupSettingFound = true;
                }
                if(ons.Type__c == Label.Outreach_Notification_Session_Catchup_Reminder){
                    outreachSessionCatchupReminderSetting = ons;
                    bOutreachSessionCatchupReminderSettingFound = true;
                }
                if(ons.Type__c == Label.Outreach_Notification_Session_Attendance_Thank_you){
                    outreachSessionAttendanceThankYouSetting = ons;
                    bOutreachAttendanceThankYouSettingFound = true;
                }
                if(ons.Type__c == Label.Outreach_Notification_Session_Catchup_Thank_you){
                    outreachSessionCatchThankYouSetting = ons;
                    bOutreachCatchupThankYouSettingFound = true;
                }
            }

            // retrieve all session participants
            List<Session_Participant__c> lstNotAttendedSessionParticipants = new List<Session_Participant__c>();
            lstNotAttendedSessionParticipants = getSessionParticipantsPerStatus(mapSessionParticipantsBySessionIds.get(session.Id), 'Attended', false);
            List<Session_Participant__c> lstIncompleteCatchupSessionParticipants = new List<Session_Participant__c>();
            lstIncompleteCatchupSessionParticipants = getSessionParticipantsPerStatus(mapSessionParticipantsBySessionIds.get(session.Id), 'Catchup', false);
            List<Session_Participant__c> lstAttendAndCatchupSessionParticipants = new List<Session_Participant__c>();
            lstAttendAndCatchupSessionParticipants = getSessionParticipantsPerStatus(mapSessionParticipantsBySessionIds.get(session.Id), Label.Outreach_Notification_Session_Attended, true);

            // thank you notification flow
            if(System.now() > session.End_Date_Time__c || System.now() > session.Catchup_Start_Date__c){
                // Session Attendance Thank you Setting
                if(bOutreachAttendanceThankYouSettingFound || bOutreachCatchupThankYouSettingFound) {
                    System.debug(LoggingLevel.DEBUG, '!@# outreachSessionAttendanceThankYouSetting: ' + outreachSessionAttendanceThankYouSetting);
                    System.debug(LoggingLevel.DEBUG, '!@# outreachSessionCatchThankYouSetting: ' + outreachSessionCatchThankYouSetting);

                    if (!lstAttendAndCatchupSessionParticipants.isEmpty()) {
                        System.debug(LoggingLevel.DEBUG, '!@# lstAttendAndCatchupSessionParticipants:' + lstAttendAndCatchupSessionParticipants.size());
                        List<Session_Participant__c> lstSessionParticipantsForAttendanceThankYouNotification = new List<Session_Participant__c>();
                        List<Session_Participant__c> lstSessionParticipantsForCatchupThankYouNotification = new List<Session_Participant__c>();
                        // iterate on each session participant to check the Attendance Date
                        for(Session_Participant__c sp : lstAttendAndCatchupSessionParticipants){
                            if(sp.Status__c == Label.Outreach_Notification_Session_Attended){
                                // check if Session participant is due for Session Attendance Thank You L1 notification
                                if(checkIfTodayIsDueForNotification(sp.Attendance_Date__c, Integer.valueOf(outreachSessionAttendanceThankYouSetting.L1_Days__c), Label.Outreach_Notification_Session_Attendance_Thank_you)) {
                                    lstSessionParticipantsForAttendanceThankYouNotification.add(sp);
                                }
                            }else{
                                // check if Session participant is due for Session Catchup Thank You L1 notification
                                if(checkIfTodayIsDueForNotification(sp.Catchup_Date__c, Integer.valueOf(outreachSessionCatchThankYouSetting.L1_Days__c), Label.Outreach_Notification_Session_Catchup_Thank_you)) {
                                    lstSessionParticipantsForCatchupThankYouNotification.add(sp);
                                }
                            }
                        }
                        if(!lstSessionParticipantsForAttendanceThankYouNotification.isEmpty()){
                            System.debug(LoggingLevel.DEBUG, '!@# lstSessionParticipantsForAttendanceThankYouNotification:' + lstSessionParticipantsForAttendanceThankYouNotification.size());
                            // record history
                            lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(false, true, lstSessionParticipantsForAttendanceThankYouNotification, outreachSessionAttendanceThankYouSetting));
                        }
                        if(!lstSessionParticipantsForCatchupThankYouNotification.isEmpty()){
                            System.debug(LoggingLevel.DEBUG, '!@# lstSessionParticipantsForCatchupThankYouNotification:' + lstSessionParticipantsForCatchupThankYouNotification.size());
                            // record history
                            lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(false, true, lstSessionParticipantsForCatchupThankYouNotification, outreachSessionCatchThankYouSetting));
                        }

                    } else{
                        System.debug(LoggingLevel.DEBUG, '!@# No Session Participant due for Thank You Notification.');
                    }
                }
            }

            // Session catchup flow
            if(session.Catch_up__c){
                if(System.now() > session.Catchup_Start_Date__c){
                    // Session Catchup Setting
                    if(bOutreachSessionCatchupSettingFound){
                        System.debug(LoggingLevel.DEBUG, '!@# outreachSessionCatchupSetting:' + outreachSessionCatchupSetting);
                        // check if Session is due for Session Catchup L1 notification
                        if(checkIfTodayIsDueForNotification(session.Catchup_Start_Date__c, Integer.valueOf(outreachSessionCatchupSetting.L1_Days__c), Label.Outreach_Notification_Session_Catchup)) {
                            System.debug(LoggingLevel.DEBUG, '!@# lstNotAttendedSessionParticipants:' + lstNotAttendedSessionParticipants.size());
                            // check if there are participants where status != Attended
                            if(!lstNotAttendedSessionParticipants.isEmpty()){
                                // record history
                                lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(false, true, lstNotAttendedSessionParticipants, outreachSessionCatchupSetting));
                            }
                        }else{
                            System.debug(LoggingLevel.DEBUG, '!@# Session - ' + session.Name + ' not due for Session Catchup L1 notification.');
                            // Session Catchup Reminder Setting
                            if(bOutreachSessionCatchupReminderSettingFound){
                                System.debug(LoggingLevel.DEBUG, '!@# outreachSessionCatchupReminderSetting:' + outreachSessionCatchupReminderSetting);

                                // check if Session is due for Session Catchup Reminder L1 notification
                                if(checkIfTodayIsDueForNotification(session.Catchup_End_Date__c, Integer.valueOf(outreachSessionCatchupReminderSetting.L1_Days__c), Label.Outreach_Notification_Session_Catchup_Reminder)) {
                                    System.debug(LoggingLevel.DEBUG, '!@# lstIncompleteCatchupSessionParticipants:' + lstIncompleteCatchupSessionParticipants.size());
                                    // check if there are participants where status != Attended and != Catchup
                                    if(!lstIncompleteCatchupSessionParticipants.isEmpty()){
                                        // record history
                                        lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(false, true, lstIncompleteCatchupSessionParticipants, outreachSessionCatchupReminderSetting));
                                    }
                                }else{
                                    System.debug(LoggingLevel.DEBUG, '!@# Session - ' + session.Name + ' not due for Session Catchup Reminder L1 notification.');

                                    // check if Session is due for Session Catchup Reminder L2 notification
                                    if(checkIfTodayIsDueForNotification(session.Catchup_End_Date__c, Integer.valueOf(outreachSessionCatchupReminderSetting.L2_Days__c), Label.Outreach_Notification_Session_Catchup_Reminder_L2)) {
                                        System.debug(LoggingLevel.DEBUG, '!@# lstIncompleteCatchupSessionParticipants:' + lstIncompleteCatchupSessionParticipants.size());
                                        // check if there are participants where status != Attended and != Catchup
                                        if(!lstIncompleteCatchupSessionParticipants.isEmpty()){
                                            // record history
                                            lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(true, true, lstIncompleteCatchupSessionParticipants, outreachSessionCatchupReminderSetting));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }else{
                if(System.now() > session.End_Date_Time__c && !lstNotAttendedSessionParticipants.isEmpty()){
                    System.debug(LoggingLevel.DEBUG, '!@# lstNotAttendedSessionParticipants:' + lstNotAttendedSessionParticipants.size());
                    // record Outreach History for L2 Outreach report
                    lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(false, false, lstNotAttendedSessionParticipants, outreachSessionCatchupSetting));
                }
            }
        }
    }

    /* ***************************************************************************** */
    public static Boolean checkIfTodayIsDueForNotification(Datetime dtSessionDate, Integer iDays, String strType){
        Boolean bReturn = false;
        System.debug(LoggingLevel.DEBUG, ' !@# Outreach Notification Setting Days :  ' +iDays);
        if(strType == Label.Outreach_Notification_Session_Catchup){
            System.debug(LoggingLevel.DEBUG, ' !@# Days after Session Catchup StartDate: ' + dtSessionDate.date().daysBetween(System.now().date()));
            if(dtSessionDate.date().daysBetween(System.now().date()) == iDays){
                bReturn = true;
            }
        }else if(strType == Label.Outreach_Notification_Session_Catchup_Reminder || strType == Label.Outreach_Notification_Session_Catchup_Reminder_L2){
            System.debug(LoggingLevel.DEBUG, ' !@# Days prior to Session Catchup EndDate: ' + System.now().date().daysBetween(dtSessionDate.date()));
            if(System.now().date().daysBetween(dtSessionDate.date()) == iDays){
                bReturn = true;
            }
        }else if(strType == Label.Outreach_Notification_Session_Catchup_Thank_you || strType == Label.Outreach_Notification_Session_Attendance_Thank_you){
            System.debug(LoggingLevel.DEBUG, ' !@# Days after Session Participant Attendance Date: ' + dtSessionDate.date().daysBetween(System.now().date()));
            if(dtSessionDate.date().daysBetween(System.now().date()) == iDays){
                bReturn = true;
            }
        }
        return bReturn;
    }

    /* ***************************************************************************** */
    public static List<Outreach_Notification_History__c> createOutreachNotificationHistory(Boolean L2Flag, Boolean bCatchup, List<Session_Participant__c> lstSessionParticipants, Outreach_Notification_Setting__c outreachNotificationSetting){
        Datetime dtSchedule = Datetime.newInstance(System.today().year(), System.today().month(), System.today().day(),outreachNotificationSetting.Time__c.hour(), outreachNotificationSetting.Time__c.minute(), outreachNotificationSetting.Time__c.second());
        List<Outreach_Notification_History__c> lstOutreachNotificationHistories = new List<Outreach_Notification_History__c>();

        System.debug(LoggingLevel.DEBUG, ' !@# lstSessionParticipants: ' + lstSessionParticipants.size());
        for(Session_Participant__c sp : lstSessionParticipants){
            Outreach_Notification_History__c onhForSession = new Outreach_Notification_History__c();
            onhForSession.Contact__c = sp.Contact__c;
            onhForSession.Outreach_Notification__c = outreachNotificationSetting.Outreach_Notification__c;
            onhForSession.Related_To__c = sp.Session__r.Name;
            onhForSession.Related_To_Id__c = sp.Session__r.Id;
            if(!bCatchup || L2Flag){
                if(!bCatchup){
                    onhForSession.Notes__c = Label.Outreach_Notification_L2_Flagged + ' - ' + Label.Outreach_Notification_Missed_Attendance;
                }else{
                    onhForSession.Notes__c = Label.Outreach_Notification_L2_Flagged + ' - ' + Label.Outreach_Notification_Session_Catchup;
                }
            }else{
                onhForSession.Outreach_Notification_Setting__c = outreachNotificationSetting.Id;
                onhForSession.Schedule__c =  dtSchedule;
            }
            System.debug(LoggingLevel.DEBUG, ' !@# onhForSession: ' + onhForSession);
            lstOutreachNotificationHistories.add(onhForSession);
        }
        System.debug(LoggingLevel.DEBUG, ' !@# lstOutreachNotificationHistories: ' + lstOutreachNotificationHistories.size());
        return lstOutreachNotificationHistories;
    }


    /* ***************************************************************************** */
    public static List<Session_Participant__c> getSessionParticipantsPerStatus(List<Session_Participant__c> lstSesParticipants, String strStatus, Boolean bCondition){
        List<Session_Participant__c> lstSessionParticipants = new List<Session_Participant__c>();
        for(Session_Participant__c sp : lstSesParticipants){
            if(!bCondition){
                // get participants where status != Attended
                if(strStatus == 'Attended'){
                    if(sp.Status__c != strStatus) lstSessionParticipants.add(sp);
                }
                // get participants where status != Attended and != Catchup
                if(strStatus == 'Catchup'){
                    if(sp.Status__c != strStatus && sp.Status__c != 'Attended') lstSessionParticipants.add(sp);
                }
            }else{
                // get participants where status != Attended and != Catchup
                if((sp.Status__c == 'Catchup' && sp.Catchup_Date__c != null) || (sp.Status__c == 'Attended' && sp.Attendance_Date__c != null)) lstSessionParticipants.add(sp);
            }
        }
        return lstSessionParticipants;
    }


    /* ***************************************************************************** */
    public static Map<Id, Session__c> getSessions(){
        System.debug(LoggingLevel.DEBUG, ' !@# Retrieve Sessions');
        Map<Id, Session__c> mapSessionById = new Map<Id,Session__c>();

        for(Session__c session : [SELECT Id, Name, Event_Id__c, Event__c , IsActive__c, Outreach_Notification__c, Start_Date_Time__c, End_Date_Time__c,
                Catch_up__c, Catchup_Start_Date__c, Catchup_End_Date__c,
        (SELECT Id FROM Session_Participants__r)
        FROM Session__c WHERE Outreach_Notification__c != NULL
        AND IsActive__c = TRUE LIMIT 2000]){
            mapSessionById.put(session.Id, session);
        }

        return mapSessionById;
    }

    /* ***************************************************************************** */
    public static Map<Id, List<Session_Participant__c>> getSessionParticipants(Set<Id> setSessionIds){
        System.debug(LoggingLevel.DEBUG, ' !@# Retrieve Session Participants');
        Map<Id, List<Session_Participant__c>> mapSessionParticipantsByIds = new Map<Id, List<Session_Participant__c>>();
        for(Session_Participant__c sp : [SELECT Id, Name,Session__r.Id, Session__r.Name, Session__r.Event__r.Id, Session__r.Event__r.Name, Session__r.Time_Zone__c,
                Status__c, Contact__c, Participant__c, Session_Start_Date__c, Attendance_Date__c, Catchup_Date__c
        FROM Session_Participant__c
        WHERE Session__r.Id IN: setSessionIds AND Participant__c != NULL
        AND Contact__c != NULL ORDER BY  CreatedDate DESC  LIMIT 5000]){
            if(mapSessionParticipantsByIds.containsKey(sp.Session__r.Id)){
                mapSessionParticipantsByIds.get(sp.Session__r.Id).add(sp);
            }else{
                mapSessionParticipantsByIds.put(sp.Session__r.Id, new List<Session_Participant__c>{sp});
            }
        }
        //System.debug(LoggingLevel.DEBUG, ' !@# mapSessionParticipantsByIds: ' + JSON.serializePretty(mapSessionParticipantsByIds));
        return  mapSessionParticipantsByIds;
    }

}