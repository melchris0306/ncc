/*******************************************************************************
 * @author       Angelo Rivera
 * @date          01.10.2021
 * @description  [CCN-842, CCN-1059, CCN-1060, CCN-1061] Helper class for BatchOutreachNotificationCC
 * @revision      01.10.2021 - APRivera - Created
 *******************************************************************************/

public without sharing class OutreachNotificationHelper {

    /* ***************************************************************************** */
    public static String processEvents(){
        Map<Id, Event__c> mapEventsById = new Map<Id,Event__c>();
        mapEventsById = getEvents();
        if(!mapEventsById.isEmpty()){
            // retrieve all Outreach Notification linked to Events
            Map<Id, List<Outreach_Notification_Setting__c>> mapOutreachNotificationSettingsByOutreachNotificationIds = new Map<Id, List<Outreach_Notification_Setting__c>>();
            mapOutreachNotificationSettingsByOutreachNotificationIds = getOutreachNotificationSettings();

            // retrieve all Session Participants
            Map<Id, List<Session_Participant__c>> mapSessionParticipantsByIds = new Map<Id, List<Session_Participant__c>>();
            mapSessionParticipantsByIds = getSessionParticipants(mapEventsById.keySet());

            // retrieve existing Outreach Notification Histories related to Event
            Map<Id, List<Outreach_Notification_History__c>> mapOutreachNotificationHistoriesByIds = new Map<Id, List<Outreach_Notification_History__c>>();
            mapOutreachNotificationHistoriesByIds = getOutreachNotificationHistories();

            List<Outreach_Notification_History__c> lstNewOutreachNotificationHistories = new List<Outreach_Notification_History__c>();

            // iterate on Event records
            for(Event__c evt : mapEventsById.values()){
                processOutreachNotifications(lstNewOutreachNotificationHistories, mapOutreachNotificationSettingsByOutreachNotificationIds, evt, mapSessionParticipantsByIds, mapOutreachNotificationHistoriesByIds);
            }

            try{
                if(!lstNewOutreachNotificationHistories.isEmpty()){
                    Database.insert(lstNewOutreachNotificationHistories);
                }
            }catch (Exception ex){

            }
        }
        return 'Process Complete!';
    }


    /* ***************************************************************************** */
    public static void processOutreachNotifications(List<Outreach_Notification_History__c> lstNewOutreachNotificationHistories,
            Map<Id, List<Outreach_Notification_Setting__c>> mapOutreachNotificationSettingsByOutreachNotificationIds,
            Event__c evt,
            Map<Id, List<Session_Participant__c>> mapSessionParticipantsByIds,
            Map<Id, List<Outreach_Notification_History__c>> mapOutreachNotificationHistoriesByIds){

        if(System.now() < evt.Start_Date_Time__c){
            // retrieve Participants without registered Session
            List<Participant__c> lstParticipantsWithoutRegisteredSession = new List<Participant__c>();
            List<Participant__c> lstParticipantsWithRegisteredSession = new List<Participant__c>();
            getParticipantsRegisteredSessions(evt, mapSessionParticipantsByIds, lstParticipantsWithoutRegisteredSession, lstParticipantsWithRegisteredSession);

            List<Outreach_Notification_Setting__c> lstOutreachNotificationSettings = new List<Outreach_Notification_Setting__c>();
            lstOutreachNotificationSettings = mapOutreachNotificationSettingsByOutreachNotificationIds.get(evt.Outreach_Notification__c);

            // Outreach Event Registration Reminder
            if(!lstParticipantsWithoutRegisteredSession.isEmpty()){
                System.debug(LoggingLevel.DEBUG, ' !@# lstParticipantsWithoutRegisteredSession ' + JSON.serializePretty(lstParticipantsWithoutRegisteredSession));
                System.debug(LoggingLevel.DEBUG, ' !@# Event Registration Reminder for ' + evt.Name);
                Outreach_Notification_Setting__c outreachRegistrationNotificationSetting = new Outreach_Notification_Setting__c();
                if(!lstOutreachNotificationSettings.isEmpty()){
                    Boolean bOutreachNotificationFound = false;
                    // retrieve outreach notification setting to be used
                    for(Outreach_Notification_Setting__c ons : lstOutreachNotificationSettings){
                        if(ons.Type__c == Label.Outreach_Notification_Registration_Reminder){
                            outreachRegistrationNotificationSetting = ons;
                            bOutreachNotificationFound = true;
                        }
                    }
                    if(bOutreachNotificationFound){
                        System.debug(LoggingLevel.DEBUG, ' !@# Outreach Registration Notification Setting ' + outreachRegistrationNotificationSetting);
                        // record Outreach Notification History
                        Map<Id, List<Session_Participant__c>> mapSessionParticipantsByParticipantsIds = new Map<Id, List<Session_Participant__c>>();
                        lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(lstParticipantsWithoutRegisteredSession,
                                mapSessionParticipantsByParticipantsIds,
                                outreachRegistrationNotificationSetting,
                                mapOutreachNotificationHistoriesByIds,
                                evt));
                    }
                }
            }

            // Outreach Event Confirmation Reminder
            if(!lstParticipantsWithRegisteredSession.isEmpty()){
                List<Participant__c> lstParticipantsWithUnconfirmedSession = new List<Participant__c>();
                List<Participant__c> lstParticipantsWithDeclinedSession = new List<Participant__c>();
                System.debug(LoggingLevel.DEBUG, ' !@# Event Confirmation Reminder for ' + evt.Name);
                Outreach_Notification_Setting__c outreachConfirmationNotificationSetting = new Outreach_Notification_Setting__c();
                if(!lstOutreachNotificationSettings.isEmpty()){
                    Boolean bOutreachNotificationFound = false;
                    // retrieve outreach notification setting to be used
                    for(Outreach_Notification_Setting__c ons : lstOutreachNotificationSettings){
                        if(ons.Type__c == Label.Outreach_Notification_Confirmation_Reminder){
                            outreachConfirmationNotificationSetting = ons;
                            bOutreachNotificationFound = true;
                        }
                    }
                    if(bOutreachNotificationFound){
                        System.debug(LoggingLevel.DEBUG, ' !@# Outreach Confirmation Notification Setting ' + outreachConfirmationNotificationSetting);
                        // iterates on the list of participants
                        Map<Id, List<Session_Participant__c>> mapUnconfirmedSessionParticipantsByParticipantsIds = new Map<Id, List<Session_Participant__c>>();
                        Map<Id, List<Session_Participant__c>> mapDeclinedSessionParticipantsByParticipantsIds = new Map<Id, List<Session_Participant__c>>();
                        System.debug(LoggingLevel.DEBUG, ' !@# lstParticipantsWithRegisteredSession ' + JSON.serializePretty(lstParticipantsWithRegisteredSession));
                        for(Participant__c p : lstParticipantsWithRegisteredSession){
                            System.debug(LoggingLevel.DEBUG, ' !@# Checking sessions of Participant ' + p.Member_Contact__r.Name);
                            // check if participant has related Session participants
                            if(!mapSessionParticipantsByIds.get(p.Id).isEmpty()){
                                System.debug(LoggingLevel.DEBUG, ' !@# mapSessionParticipantsByIds ' + JSON.serializePretty(mapSessionParticipantsByIds.get(p.Id)));
                                // Iterate on the list session participants of the participant of the current iteration
                                Set<Id> setParticipantsIdWithDeclinedSession = new Set<Id>();
                                Set<Id> setParticipantsIdWithUnconfirmedSession = new Set<Id>();
                                for(Session_Participant__c sp : mapSessionParticipantsByIds.get(p.Id)){
                                    Boolean bSessionUnConfirmed = false;
                                    Boolean bSessionDeclined = false;
                                    List<Session_Participant__c> lstRegisteredSessionParticipants = new List<Session_Participant__c>();
                                    List<Session_Participant__c> lstDeclinedSessionParticipants = new List<Session_Participant__c>();
                                    System.debug(LoggingLevel.DEBUG, ' !@# Session Name ' + sp.Name);
                                    System.debug(LoggingLevel.DEBUG, ' !@# Session Participant Status ' + sp.Status__c);
                                    // Status = Registered
                                    if(sp.Status__c == Label.Outreach_Notification_Registered_Status){
                                        lstRegisteredSessionParticipants.add(sp);
                                        bSessionUnConfirmed = true;
                                        if(!setParticipantsIdWithUnconfirmedSession.contains(p.Id)) lstParticipantsWithUnconfirmedSession.add(p);
                                        setParticipantsIdWithUnconfirmedSession.add(p.Id);
                                    }
                                    if(sp.Status__c == Label.Outreach_Notification_Confirmation_Declined_Status){
                                        lstDeclinedSessionParticipants.add(sp);
                                        bSessionDeclined = true;
                                        if(!setParticipantsIdWithDeclinedSession.contains(p.Id)) lstParticipantsWithDeclinedSession.add(p);
                                        setParticipantsIdWithDeclinedSession.add(p.Id);
                                    }

                                    if(bSessionUnConfirmed){
                                        if(!mapUnconfirmedSessionParticipantsByParticipantsIds.containsKey(p.Id)){
                                            mapUnconfirmedSessionParticipantsByParticipantsIds.put(p.Id, lstRegisteredSessionParticipants);
                                        }else{
                                            mapUnconfirmedSessionParticipantsByParticipantsIds.get(p.Id).addAll(lstRegisteredSessionParticipants);
                                        }
                                    }
                                    if(bSessionDeclined){
                                        if(!mapDeclinedSessionParticipantsByParticipantsIds.containsKey(p.Id)){
                                            mapDeclinedSessionParticipantsByParticipantsIds.put(p.Id, lstDeclinedSessionParticipants);
                                        }else{
                                            mapDeclinedSessionParticipantsByParticipantsIds.get(p.Id).addAll(lstDeclinedSessionParticipants);
                                        }
                                    }
                                }
                            }
                        }
                        if(!lstParticipantsWithUnconfirmedSession.isEmpty()){
                            // record Outreach Notification History
                            System.debug(LoggingLevel.DEBUG, ' !@# lstParticipantsWithUnconfirmedSession ' + JSON.serializePretty(lstParticipantsWithUnconfirmedSession));
                            lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(lstParticipantsWithUnconfirmedSession,
                                    mapUnconfirmedSessionParticipantsByParticipantsIds,
                                    outreachConfirmationNotificationSetting,
                                    mapOutreachNotificationHistoriesByIds,
                                    evt));
                        }

                        System.debug(LoggingLevel.DEBUG, ' !@# lstParticipantsWithDeclinedSession ' + JSON.serializePretty(lstParticipantsWithDeclinedSession));
                        if(!lstParticipantsWithDeclinedSession.isEmpty()){
                            // record Outreach Notification History
                            lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(lstParticipantsWithDeclinedSession,
                                    mapDeclinedSessionParticipantsByParticipantsIds,
                                    outreachConfirmationNotificationSetting,
                                    mapOutreachNotificationHistoriesByIds,
                                    evt));
                        }
                    }
                }
            }
        }
    }




    /* ***************************************************************************** */
    public static List<Outreach_Notification_History__c> createOutreachNotificationHistory( List<Participant__c> lstParticipants,
            Map<Id, List<Session_Participant__c>> mapSessionParticipantsByParticipantsIds,
            Outreach_Notification_Setting__c outreachNotificationSetting,
            Map<Id, List<Outreach_Notification_History__c>> mapOutreachNotificationHistoriesByIds,
            Event__c evt){
        System.debug(LoggingLevel.DEBUG, ' !@# Create Outreach Notification Settings Histories');
        List<Outreach_Notification_History__c> lstOutreachNotificationHistories = new List<Outreach_Notification_History__c>();
        Datetime dtSchedule = Datetime.newInstance(System.today().year(), System.today().month(), System.today().day(),
                outreachNotificationSetting.Time__c.hour(), outreachNotificationSetting.Time__c.minute(), outreachNotificationSetting.Time__c.second());

        // iterates on the list of participants
        for(Participant__c p : lstParticipants){
            Boolean bParticipantNoHistory = true;
            // check if Contact does not have any history and Participant does not have sessions
            if(!mapOutreachNotificationHistoriesByIds.containsKey(p.Member_Contact__c) && mapSessionParticipantsByParticipantsIds.isEmpty()){
                System.debug(LoggingLevel.DEBUG, ' !@# No Sessions for: ' + p.Default_Member_Name__c);
                bParticipantNoHistory = true;
            }else{
                System.debug(LoggingLevel.DEBUG, ' !@# Checking History of: ' + p.Default_Member_Name__c);
                if(mapOutreachNotificationHistoriesByIds.containsKey(p.Member_Contact__c)){
                    List<Outreach_Notification_History__c> lstHistory = new List<Outreach_Notification_History__c>();
                    lstHistory = mapOutreachNotificationHistoriesByIds.get(p.Member_Contact__c);
                    if(!lstHistory.isEmpty()){
                        System.debug(LoggingLevel.DEBUG, ' !@# History of : ' + p.Default_Member_Name__c + ' - ' + lstHistory.size());
                        for(Outreach_Notification_History__c onh : lstHistory){
                            // avoid duplicate entries for same Related record on Outreach_Notification_History__c object
                            if(mapSessionParticipantsByParticipantsIds.get(p.Id) != null){
                                System.debug(LoggingLevel.DEBUG, ' !@# mapSessionParticipantsByParticipantsIds ' + JSON.serializePretty(mapSessionParticipantsByParticipantsIds.get(p.Id)));
                                Boolean bAllSessionHasHistory = false;
                                Integer iCtr = 0;
                                for(Session_Participant__c sp: mapSessionParticipantsByParticipantsIds.get(p.Id)){
                                    System.debug(LoggingLevel.DEBUG, ' !@# Session ' + sp.Session__r.Id + ' - ' + sp.Session__r.Name);
                                    System.debug(LoggingLevel.DEBUG, ' !@# ON History ' +  JSON.serializePretty(onh));
                                    System.debug(LoggingLevel.DEBUG, ' !@# ON History Notes ' +  onh.Notes__c);
                                    if(onh.Notes__c != null){
                                        if((Id)onh.Related_To_Id__c == sp.Session__r.Id && onh.Outreach_Notification_Setting__c == outreachNotificationSetting.Id && onh.Notes__c == Label.Outreach_Notification_Confirmation_L2_Flagged_Declined_Status){
                                            System.debug(LoggingLevel.DEBUG, ' !@# Found history of Session ' + sp.Session__r.Name);
                                            iCtr++;
                                        }
                                    }else{
                                        if((Id)onh.Related_To_Id__c == sp.Session__r.Id && onh.Outreach_Notification_Setting__c == outreachNotificationSetting.Id && onh.Notes__c == null){
                                            System.debug(LoggingLevel.DEBUG, ' !@# Found history of Session ' + sp.Session__r.Name);
                                            iCtr++;
                                        }
                                    }
                                }
                                if(mapSessionParticipantsByParticipantsIds.get(p.Id).size() == iCtr) bAllSessionHasHistory = true;
                                if(bAllSessionHasHistory){
                                    bParticipantNoHistory = false;
                                }
                            }
                            else{
                                if((Id)onh.Related_To_Id__c == evt.Id && onh.Outreach_Notification_Setting__c == outreachNotificationSetting.Id){
                                    bParticipantNoHistory = false;
                                }
                            }
                        }
                    }
                }
            }

            Outreach_Notification_History__c onh = new Outreach_Notification_History__c();
            onh.Contact__c = p.Member_Contact__c;
            onh.Outreach_Notification_Setting__c = outreachNotificationSetting.Id;
            onh.Outreach_Notification__c = outreachNotificationSetting.Outreach_Notification__c;
            onh.Related_To__c = evt.Name;
            onh.Related_To_Id__c = evt.Id;

            if(bParticipantNoHistory){ // participant does not have History on Outreach Notification history
                System.debug(LoggingLevel.DEBUG, ' !@# No History for: ' + p.Default_Member_Name__c);
                Datetime dtStartDateTime = evt.Start_Date_Time__c;
                if(!mapSessionParticipantsByParticipantsIds.isEmpty()  && mapSessionParticipantsByParticipantsIds.get(p.Id) != null){  // Participant has session participant records
                    for(Session_Participant__c sp : mapSessionParticipantsByParticipantsIds.get(p.Id)){
                        Session_Participant__c spTemp = new Session_Participant__c();
                        Boolean bSessionReminderDue = false;
                        Boolean bDeclinedSession = false;
                        System.debug(LoggingLevel.DEBUG, ' !@# mapSessionParticipantsByParticipantsIds ' + JSON.serializePretty(mapSessionParticipantsByParticipantsIds.get(p.Id)));
                        if(checkIfTodayIsDueForNotification(sp.Session_Start_Date__c, Integer.valueOf(outreachNotificationSetting.L1_Days__c))) {
                            spTemp = sp;
                            dtStartDateTime = sp.Session_Start_Date__c;
                            if(sp.Status__c == Label.Outreach_Notification_Confirmation_Declined_Status) bDeclinedSession = true;
                            bSessionReminderDue = true;
                            System.debug(LoggingLevel.DEBUG, ' !@# Session Name ' + sp.Name);
                            System.debug(LoggingLevel.DEBUG, ' !@# Session Participant Status ' + sp.Status__c);
                        }
                        if(bSessionReminderDue){
                            Outreach_Notification_History__c onhForSession = new Outreach_Notification_History__c();
                            onhForSession.Contact__c = p.Member_Contact__c;
                            onhForSession.Outreach_Notification_Setting__c = outreachNotificationSetting.Id;
                            onhForSession.Outreach_Notification__c = outreachNotificationSetting.Outreach_Notification__c;

                            System.debug(LoggingLevel.DEBUG, ' !@# Session Due for Reminder. ');
                            System.debug(LoggingLevel.DEBUG, ' !@# Recording L1 history for Participant ' + p.Default_Member_Name__c);
                            // insert L1 History
                            System.debug(LoggingLevel.DEBUG, ' !@# bDeclinedSession ' + bDeclinedSession);
                            if(bDeclinedSession){
                                onhForSession.Notes__c = Label.Outreach_Notification_L2_Flagged + ' - ' + Label.Outreach_Notification_Session_Declined_Status;
                            }else{
                                onhForSession.Schedule__c =  dtSchedule;
                                onhForSession.TimeZone__c = evt.Time_Zone__c;
                            }
                            onhForSession.Related_To__c = spTemp.Session__r.Name;
                            onhForSession.Related_To_Id__c = spTemp.Session__r.Id;
                            lstOutreachNotificationHistories.add(onhForSession);
                        }
                    }
                }else{ // Participant does not have session participant records
                    if(checkIfTodayIsDueForNotification(dtStartDateTime, Integer.valueOf(outreachNotificationSetting.L1_Days__c))) {
                        System.debug(LoggingLevel.DEBUG, ' !@# Recording L1 history for Participant ' + p.Default_Member_Name__c);
                        // insert L1 History
                        onh.Schedule__c =  dtSchedule;
                        onh.TimeZone__c = evt.Time_Zone__c;
                        lstOutreachNotificationHistories.add(onh);
                    }
                }
            } else{ // participant has existing history
                System.debug(LoggingLevel.DEBUG, ' !@# Found History for: ' + p.Default_Member_Name__c);
                if(outreachNotificationSetting.L2_Days__c != null){
                    Datetime dtStartDateTime = evt.Start_Date_Time__c;
                    // check if there is session participant records
                    if(!mapSessionParticipantsByParticipantsIds.isEmpty() && mapSessionParticipantsByParticipantsIds.get(p.Id) != null){
                        for(Session_Participant__c sp : mapSessionParticipantsByParticipantsIds.get(p.Id)){
                            Boolean bDeclinedSession = false;
                            Boolean bSessionReminderDue = false;
                            Session_Participant__c spTemp = new Session_Participant__c();
                            if(checkIfTodayIsDueForNotification(sp.Session_Start_Date__c, Integer.valueOf(outreachNotificationSetting.L2_Days__c))) {
                                dtStartDateTime = sp.Session_Start_Date__c;
                                spTemp = sp;
                                bDeclinedSession = (sp.Status__c == Label.Outreach_Notification_Confirmation_Declined_Status) ? true : false;
                                bSessionReminderDue = true;
                            }
                            if(bSessionReminderDue){
                                Outreach_Notification_History__c onhForSession = new Outreach_Notification_History__c();
                                onhForSession.Contact__c = p.Member_Contact__c;
                                onhForSession.Outreach_Notification_Setting__c = outreachNotificationSetting.Id;
                                onhForSession.Outreach_Notification__c = outreachNotificationSetting.Outreach_Notification__c;
                                Boolean bL2Flagged = false;
                                for(Outreach_Notification_History__c onHistory : mapOutreachNotificationHistoriesByIds.get(p.Member_Contact__c)){
                                    // avoid duplicate entries on Outreach_Notification_History__c object
                                    if((Id)onHistory.Related_To_Id__c == sp.Session__r.Id && onHistory.Outreach_Notification_Setting__c == outreachNotificationSetting.Id
                                            && (onHistory.Notes__c == Label.Outreach_Notification_L2_Flagged || onHistory.Notes__c == Label.Outreach_Notification_Confirmation_L2_Flagged_Declined_Status) ){
                                        bL2Flagged = true;
                                    }
                                }
                                if(!bL2Flagged){
                                    System.debug(LoggingLevel.DEBUG, ' !@# Recording L2 Flag for Participant ' + p.Default_Member_Name__c);
                                    // insert L1 history but with L2 Flagging
                                    onhForSession.Related_To__c = spTemp.Session__r.Name;
                                    onhForSession.Related_To_Id__c = spTemp.Session__r.Id;
                                    onhForSession.Notes__c = Label.Outreach_Notification_L2_Flagged;
                                    lstOutreachNotificationHistories.add(onhForSession);
                                }
                            }
                        }
                    } else{
                        if(checkIfTodayIsDueForNotification(dtStartDateTime, Integer.valueOf(outreachNotificationSetting.L2_Days__c))){
                            Boolean bL2Flagged = false;
                            for(Outreach_Notification_History__c onHistory : mapOutreachNotificationHistoriesByIds.get(p.Member_Contact__c)){
                                // avoid duplicate entries on Outreach_Notification_History__c object
                                if((Id)onHistory.Related_To_Id__c == evt.Id && onHistory.Outreach_Notification_Setting__c == outreachNotificationSetting.Id
                                        && (onh.Notes__c == (Label.Outreach_Notification_L2_Flagged + ' - ' + Label.Outreach_Notification_Session_Declined_Status)
                                        || onh.Notes__c == Label.Outreach_Notification_L2_Flagged )){
                                    bL2Flagged = true;
                                }
                            }
                            if(!bL2Flagged){
                                System.debug(LoggingLevel.DEBUG, ' !@# Recording L2 Flag for Participant ' + p.Default_Member_Name__c);
                                // insert L1 history but with L2 Flagging
                                onh.Notes__c = Label.Outreach_Notification_L2_Flagged;
                                lstOutreachNotificationHistories.add(onh);
                            }
                        }
                    }
                }
            }
        }
        return lstOutreachNotificationHistories;
    }


    /* ***************************************************************************** */
    public static Boolean checkIfTodayIsDueForNotification(Datetime dtStartDate, Integer iDays){
        Boolean bReturn = false;
        // check if (Event's Start Date - Today's Date) is equal to L1 or L2 days from Outreach Notification Setting)
        System.debug(LoggingLevel.DEBUG, ' !@# Days prior to Event StartDate: ' + System.now().date().daysBetween(dtStartDate.date()));
        System.debug(LoggingLevel.DEBUG, ' !@# Outreach Notification Setting Days :  ' +iDays);
        if(System.now().date().daysBetween(dtStartDate.date()) == iDays){
            bReturn = true;
        }
        return bReturn;
    }


    /* ***************************************************************************** */
    public static Map<Id, List<Outreach_Notification_History__c>> getOutreachNotificationHistories(){
        System.debug(LoggingLevel.DEBUG, ' !@# Retrieve Outreach Notification Settings Histories');
        Map<Id, List<Outreach_Notification_History__c>> mapOutreachNotificationHistoriesByIds = new Map<Id, List<Outreach_Notification_History__c>>();
        for(Outreach_Notification_History__c onh : [SELECT Id, Contact__c, Related_To_Id__c, Related_To__c,
                                                                    Outreach_Notification_Setting__c, Notes__c, Outreach_Notification__c
                                                                    FROM Outreach_Notification_History__c ORDER BY CreatedDate DESC LIMIT 5000]){
            if(mapOutreachNotificationHistoriesByIds.containsKey(onh.Contact__c)){
                mapOutreachNotificationHistoriesByIds.get(onh.Contact__c).add(onh);
            } else{
                mapOutreachNotificationHistoriesByIds.put(onh.Contact__c, new List<Outreach_Notification_History__c>{onh});
            }
        }
        return mapOutreachNotificationHistoriesByIds;
    }


    /* ***************************************************************************** */
    public static Map<Id, List<Outreach_Notification_Setting__c>> getOutreachNotificationSettings(){
        System.debug(LoggingLevel.DEBUG, ' !@# Retrieve Outreach Notification Settings');
        Map<Id, List<Outreach_Notification_Setting__c>> mapOutreachNotificationSettingsByOutreachNotificationIds = new Map<Id, List<Outreach_Notification_Setting__c>>();
        for(Outreach_Notification__c outreachNotification : [SELECT Id,  Name,
                                                                            (SELECT Id, Name, L1_Days__c, L2_Days__c, Email_Template_Name__c, Time__c,
                                                                                    Timezone_Specific__c, Type__c, Outreach_Notification__c
                                                                            FROM Outreach_Notification_Settings__r)
                                                                            FROM Outreach_Notification__c WHERE Active__c = TRUE]){
            List<Outreach_Notification_Setting__c> lstOutreachSettings = new List<Outreach_Notification_Setting__c>();
            lstOutreachSettings.addAll(outreachNotification.Outreach_Notification_Settings__r);
            mapOutreachNotificationSettingsByOutreachNotificationIds.put(outreachNotification.Id, lstOutreachSettings);
        }
        return mapOutreachNotificationSettingsByOutreachNotificationIds;
    }


    /* ***************************************************************************** */
    public static void getParticipantsRegisteredSessions(Event__c evt, Map<Id, List<Session_Participant__c>> mapSessionParticipantsByIds,
            List<Participant__c> lstParticipantsWithoutRegisteredSession, List<Participant__c> lstParticipantsWithRegisteredSession){
        System.debug(LoggingLevel.DEBUG, ' !@# Retrieve Participants Sessions');
        if(!evt.Participants__r.isEmpty() && !evt.CC_Sessions__r.isEmpty()){
            List<Participant__c> lstParticipants = new List<Participant__c>();
            lstParticipants.addAll(evt.Participants__r);
            Set<Id> setParticipantsIds = new Set<Id>();
            // iterate over the list of Participants
            for(Participant__c p: evt.Participants__r){
                // avoid duplicate participants of the same event
                if(!setParticipantsIds.contains(p.Id)){
                    // check if Participant has any Session participant records
                    System.debug(LoggingLevel.DEBUG, ' !@# Checking Sessions of: ' + p.Member_Contact__r.Name);
                    if(!mapSessionParticipantsByIds.containsKey(p.Id)){
                        System.debug(LoggingLevel.DEBUG, ' !@# No Session for: ' + p.Member_Contact__r.Name);
                        // Participant does not have registered session
                        lstParticipantsWithoutRegisteredSession.add(p);
                    }else{
                        System.debug(LoggingLevel.DEBUG, ' !@# Session Found for: ' + p.Member_Contact__r.Name);
                        // Participant have registered session
                        lstParticipantsWithRegisteredSession.add(p);
                    }
                    setParticipantsIds.add(p.Id);
                }
            }
        }
    }


    /* ***************************************************************************** */
    public static Map<Id, List<Session_Participant__c>> getSessionParticipants(Set<Id> setEventIds){
        System.debug(LoggingLevel.DEBUG, ' !@# Retrieve Session Participants');
        Map<Id, List<Session_Participant__c>> mapSessionParticipantsByIds = new Map<Id, List<Session_Participant__c>>();
        for(Session_Participant__c sp : [SELECT Id, Name,Session__r.Id, Session__r.Name, Session__r.Event__r.Id, Session__r.Event__r.Name, Status__c, Contact__c, Participant__c, Session_Start_Date__c
                                                    FROM Session_Participant__c
                                                    WHERE Session__r.Event__r.Id IN: setEventIds AND Participant__c != NULL
                                                    AND Contact__c != NULL ORDER BY  CreatedDate DESC  LIMIT 5000]){

            if(mapSessionParticipantsByIds.containsKey(sp.Participant__c)){
                mapSessionParticipantsByIds.get(sp.Participant__c).add(sp);
            }else{
                mapSessionParticipantsByIds.put(sp.Participant__c, new List<Session_Participant__c>{sp});
            }
        }

        //System.debug(LoggingLevel.DEBUG, ' !@# mapSessionParticipantsByIds: ' + JSON.serializePretty(mapSessionParticipantsByIds));
        return  mapSessionParticipantsByIds;
    }


    /* ***************************************************************************** */
    public static Map<Id, Event__c> getEvents(){
        System.debug(LoggingLevel.DEBUG, ' !@# Retrieve Events');
        Map<Id, Event__c> mapEventsById = new Map<Id,Event__c>();
        for(Event__c evt : [SELECT Id, Event_Id__c, Name, Outreach_Notification__c, Start_Date_Time__c, Time_Zone__c,
                                    (SELECT Id, Member_Contact__c, Member_Contact__r.Name, Default_Member_Name__c FROM Participants__r),
                                    (SELECT Id, Name,Session__r.Name, IsActive__c, Outreach_Notification__c, Start_Date_Time__c FROM CC_Sessions__r)
                                    FROM Event__c
                                    WHERE Outreach_Notification__c != NULL ]){
            mapEventsById.put(evt.Id, evt);
        }
        return mapEventsById;
    }

}