/*******************************************************************************
 * @author       Angelo Rivera
 * @date          01.12.2021
 * @description  [CCN-1059, CCN-1060, CCN-1061] Helper class for BatchOutreachNotificationCC
 * @revision      10.12.2021 - APRivera - Created
 *******************************************************************************/

public without sharing class OutreachNotificationSurveyHelper {

    /* ***************************************************************************** */
    public static String processSurveys(){
        Map<Id, Survey__c> mapSurveyById = new Map<Id, Survey__c>();
        mapSurveyById = getSurveys();

        if(!mapSurveyById.isEmpty()){
            // retrieve all Outreach Notification linked to Events
            Map<Id, List<Outreach_Notification_Setting__c>> mapOutreachNotificationSettingsByOutreachNotificationIds = new Map<Id, List<Outreach_Notification_Setting__c>>();
            mapOutreachNotificationSettingsByOutreachNotificationIds = OutreachNotificationHelper.getOutreachNotificationSettings();

            Map<Id, List<Participant__c>> mapParticipantsByEventId = new Map<Id, List<Participant__c>>();
            mapParticipantsByEventId = getEventParticipants(mapSurveyById.keySet());

            List<Outreach_Notification_History__c> lstNewOutreachNotificationHistories = new List<Outreach_Notification_History__c>();
            // iterate on Survey records
            for(Survey__c survey : mapSurveyById.values()){
                if(survey.Outreach_Notification__c != null){
                    System.debug(LoggingLevel.DEBUG, ' !@# Processing Survey: ' + survey.Name);
                    processSurveyOutreachNotifications(survey, mapOutreachNotificationSettingsByOutreachNotificationIds, lstNewOutreachNotificationHistories, mapParticipantsByEventId);
                }
            }

            try{
                System.debug(LoggingLevel.DEBUG, ' !@# lstNewOutreachNotificationHistories:' + lstNewOutreachNotificationHistories.size());
                if(!lstNewOutreachNotificationHistories.isEmpty()){
                    Database.insert(lstNewOutreachNotificationHistories);
                }
            }catch (Exception ex){
                System.debug(LoggingLevel.DEBUG, ' !@# ERROR:' + ex.getTypeName() + ' - ' + ex.getMessage());
            }
        }
        return 'Process Complete!';
    }


    /* ***************************************************************************** */
    public static void processSurveyOutreachNotifications(Survey__c survey,  Map<Id, List<Outreach_Notification_Setting__c>> mapOutreachNotificationSettingsByOutreachNotificationIds,
                                                                            List<Outreach_Notification_History__c> lstNewOutreachNotificationHistories, Map<Id, List<Participant__c>> mapParticipantsByEventId){

        List<Outreach_Notification_Setting__c> lstOutreachNotificationSettings = new List<Outreach_Notification_Setting__c>();
        lstOutreachNotificationSettings = mapOutreachNotificationSettingsByOutreachNotificationIds.get(survey.Outreach_Notification__c);

        if(!lstOutreachNotificationSettings.isEmpty()){
            Outreach_Notification_Setting__c outreachSurveyCatchupSetting = new Outreach_Notification_Setting__c();
            Outreach_Notification_Setting__c outreachSurveyCatchupReminderSetting = new Outreach_Notification_Setting__c();
            Outreach_Notification_Setting__c outreachSurveyThankYouSetting = new Outreach_Notification_Setting__c();
            Outreach_Notification_Setting__c outreachSurveyReminderSetting = new Outreach_Notification_Setting__c();
            Boolean bOutreachSurveyCatchupSettingFound = false, bOutreachSurveyCatchupReminderSettingFound = false, bOutreachSurveyThankYouSettingFound = false,  bOutreachSurveyReminderSettingFound = false;
            // retrieve outreach notification setting to be used
            for(Outreach_Notification_Setting__c ons : lstOutreachNotificationSettings){
                if(ons.Type__c == Label.Outreach_Notification_Survey_Catchup){
                    outreachSurveyCatchupSetting = ons;
                    bOutreachSurveyCatchupSettingFound = true;
                }
                if(ons.Type__c == Label.Outreach_Notification_Survey_Catchup_Reminder){
                    outreachSurveyCatchupReminderSetting = ons;
                    bOutreachSurveyCatchupReminderSettingFound = true;
                }
                if(ons.Type__c == Label.Outreach_Notification_Survey_Thank_you){
                    outreachSurveyThankYouSetting = ons;
                    bOutreachSurveyThankYouSettingFound = true;
                }
                if(ons.Type__c == Label.Outreach_Notification_Survey_Reminder){
                    outreachSurveyReminderSetting = ons;
                    bOutreachSurveyReminderSettingFound = true;
                }
            }

            List<Survey_Response__c> lstSurveyResponsesThankYouNotification = new List<Survey_Response__c>();
            List<SObject> lstParticipantsSurveyReminder  = new List<SObject>();
            List<SObject> lstParticipantsSurveyReminderL2Flag  = new List<SObject>();
            List<SObject> lstParticipantsSurveyCatchup  = new List<SObject>();
            List<SObject> lstParticipantsSurveyCatchupReminder  = new List<SObject>();
            List<SObject> lstParticipantsSurveyCatchupReminderL2Flag  = new List<SObject>();
            Set<Id> setSurveyResponsesContactIds = new Set<Id>();
            List<SObject> lstParticipants  = new List<SObject>();
            Boolean bIsStandaloneSurvey = false;
            // Independent Survey - get the Survey Participants
            if(!survey.Survey_Participants__r.isEmpty() && survey.Event__c == null){
                lstParticipants.addAll(survey.Survey_Participants__r);
                bIsStandaloneSurvey = true;
            }else{ // Event's Survey - get the Event Participants
                lstParticipants = mapParticipantsByEventId.get(survey.Event__c);
            }

            if(!survey.Survey_Responses__r.isEmpty()){
                for(Survey_Response__c sr : survey.Survey_Responses__r) {
                    // thank you notification flow
                    if(bOutreachSurveyThankYouSettingFound) {
                        // check if Survey response is due for Thank You notification
                        if (checkIfTodayIsDueForNotification(sr.CreatedDate, Integer.valueOf(outreachSurveyThankYouSetting.L1_Days__c), Label.Outreach_Notification_Survey_Thank_you)) {
                            lstSurveyResponsesThankYouNotification.add(sr);
                        }
                    }
                    //gather all contacts with survey response
                    setSurveyResponsesContactIds.add(sr.Contact__c);
                }
            }
            System.debug(LoggingLevel.DEBUG, ' !@# setSurveyResponsesContactIds : ' + setSurveyResponsesContactIds.size());


            // Survey reminder notification flow
            if(bOutreachSurveyReminderSettingFound){
                // check if Participants are due for Survey reminder notification
                Datetime dtSurvey = Datetime.newInstance(survey.Journey_Milestone_End_Date__c.year(), survey.Journey_Milestone_End_Date__c.month(), survey.Journey_Milestone_End_Date__c.day());
                if (checkIfTodayIsDueForNotification(dtSurvey, Integer.valueOf(outreachSurveyReminderSetting.L1_Days__c), Label.Outreach_Notification_Survey_Reminder)) {
                    lstParticipantsSurveyReminder.addAll(getListParticipants(lstParticipants, setSurveyResponsesContactIds));
                }else{ // check if Participants will be L2 Flagged
                    if(checkIfTodayIsDueForNotification(dtSurvey, Integer.valueOf(outreachSurveyReminderSetting.L2_Days__c), Label.Outreach_Notification_Survey_Reminder)){
                        lstParticipantsSurveyReminderL2Flag.addAll(getListParticipants(lstParticipants, setSurveyResponsesContactIds));
                    }
                }
            }

            // check if Survey catchup is active
            if(survey.Catchup__c){
                // Survey Catchup notification flow
                if(bOutreachSurveyCatchupSettingFound){
                    if (checkIfTodayIsDueForNotification(survey.Catchup_Start_Date__c, Integer.valueOf(outreachSurveyCatchupSetting.L1_Days__c), Label.Outreach_Notification_Survey_Catchup)) {
                        lstParticipantsSurveyCatchup.addAll(getListParticipants(lstParticipants, setSurveyResponsesContactIds));
                    }
                }
                // Survey Catchup Reminder notification flow
                if(bOutreachSurveyCatchupReminderSettingFound){
                    if (checkIfTodayIsDueForNotification(survey.Catchup_End_Date__c, Integer.valueOf(outreachSurveyCatchupReminderSetting.L1_Days__c), Label.Outreach_Notification_Survey_Catchup_Reminder)) {
                        lstParticipantsSurveyCatchupReminder.addAll(getListParticipants(lstParticipants, setSurveyResponsesContactIds));
                    }else{ // check if Participants will be L2 Flagged
                        if(checkIfTodayIsDueForNotification(survey.Catchup_End_Date__c, Integer.valueOf(outreachSurveyCatchupReminderSetting.L2_Days__c), Label.Outreach_Notification_Survey_Catchup_Reminder)){
                            lstParticipantsSurveyCatchupReminderL2Flag.addAll(getListParticipants(lstParticipants, setSurveyResponsesContactIds));
                        }
                    }
                }
            }

            System.debug(LoggingLevel.DEBUG, ' !@# --------------------------------------------');
            if(!lstSurveyResponsesThankYouNotification.isEmpty()){
                System.debug(LoggingLevel.DEBUG, ' !@# lstSurveyResponsesThankYouNotification:' + lstSurveyResponsesThankYouNotification.size());
                // record history
                lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(false, lstSurveyResponsesThankYouNotification, outreachSurveyThankYouSetting));
            }
            if(!lstParticipantsSurveyReminder.isEmpty()){
                System.debug(LoggingLevel.DEBUG, ' !@# lstParticipantsSurveyReminder:' + lstParticipantsSurveyReminder.size());
                // record history
                lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(false, lstParticipantsSurveyReminder, outreachSurveyReminderSetting));
            }
            if(!lstParticipantsSurveyReminderL2Flag.isEmpty()){
                System.debug(LoggingLevel.DEBUG, ' !@# lstParticipantsSurveyReminderL2Flag:' + lstParticipantsSurveyReminderL2Flag.size());
                // record history
                lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(true, lstParticipantsSurveyReminderL2Flag, outreachSurveyReminderSetting));
            }
            if(!lstParticipantsSurveyCatchup.isEmpty()){
                System.debug(LoggingLevel.DEBUG, ' !@# lstParticipantsSurveyCatchup:' + lstParticipantsSurveyCatchup.size());
                // record history
                lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(false, lstParticipantsSurveyCatchup, outreachSurveyCatchupSetting));
            }
            if(!lstParticipantsSurveyCatchupReminder.isEmpty()){
                System.debug(LoggingLevel.DEBUG, ' !@# lstParticipantsSurveyCatchupReminder:' + lstParticipantsSurveyCatchupReminder.size());
                // record history
                lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(false, lstParticipantsSurveyCatchupReminder, outreachSurveyCatchupReminderSetting));
            }
            if(!lstParticipantsSurveyCatchupReminderL2Flag.isEmpty()){
                System.debug(LoggingLevel.DEBUG, ' !@# lstParticipantsSurveyCatchupReminderL2Flag:' + lstParticipantsSurveyCatchupReminderL2Flag.size());
                // record history
                lstNewOutreachNotificationHistories.addAll(createOutreachNotificationHistory(true, lstParticipantsSurveyCatchupReminderL2Flag, outreachSurveyCatchupReminderSetting));
            }
            System.debug(LoggingLevel.DEBUG, ' !@# --------------------------------------------');
        }
    }

    /* ***************************************************************************** */
    public static List<SObject> getListParticipants(List<SObject> lstParticipants, Set<Id> setContactIds){
        System.debug(LoggingLevel.DEBUG, ' !@# --------------------------------------------');
        System.debug(LoggingLevel.DEBUG, ' !@# getListParticipants ');
        List<SObject> lstFilteredParticipants = new List<SObject>();
        if(!lstParticipants.isEmpty()){
            for(SObject sObj : lstParticipants){
                System.debug(LoggingLevel.DEBUG, ' !@# Object Type: ' + sObj.getSObjectType().getDescribe().getName());
                if(sObj.getSObjectType().getDescribe().getName() ==  Participant__c.SObjectType.getDescribe().getName()){
                    Participant__c p = (Participant__c)sObj;
                    System.debug(LoggingLevel.DEBUG, ' !@# Event Participant Contact : ' + p.Member_Contact__c);
                    if(!setContactIds.contains(p.Member_Contact__c)){
                        lstFilteredParticipants.add(p);
                    }
                }else{
                    Survey_Participant__c sp = (Survey_Participant__c)sObj;
                    System.debug(LoggingLevel.DEBUG, ' !@# Survey Participant Contact : ' + sp.Participant__c);
                    if(!setContactIds.contains(sp.Participant__c)){
                        lstFilteredParticipants.add(sp);
                    }
                }
            }
            System.debug(LoggingLevel.DEBUG, ' !@# lstFilteredParticipants:' + lstFilteredParticipants.size());
        }
        return lstFilteredParticipants;
    }


    /* ***************************************************************************** */
    public static List<Outreach_Notification_History__c> createOutreachNotificationHistory(Boolean L2Flag, List<SObject> lstSObjects, Outreach_Notification_Setting__c outreachNotificationSetting){
        System.debug(LoggingLevel.DEBUG, ' !@# --------------------------------------------');
        System.debug(LoggingLevel.DEBUG, ' !@# createOutreachNotificationHistory ');
        Datetime dtSchedule = Datetime.newInstance(System.today().year(), System.today().month(), System.today().day(),
                outreachNotificationSetting.Time__c.hour(), outreachNotificationSetting.Time__c.minute(), outreachNotificationSetting.Time__c.second());
        List<Outreach_Notification_History__c> lstOutreachNotificationHistories = new List<Outreach_Notification_History__c>();

        for(SObject sObj : lstSObjects){
            Outreach_Notification_History__c onhForSession = new Outreach_Notification_History__c();
            onhForSession.Outreach_Notification__c = outreachNotificationSetting.Outreach_Notification__c;
            if(L2Flag){
                onhForSession.Notes__c = Label.Outreach_Notification_L2_Flagged;
                if(outreachNotificationSetting.Type__c == Label.Outreach_Notification_Survey_Catchup_Reminder){
                    onhForSession.Notes__c = Label.Outreach_Notification_L2_Flagged + ' - ' + Label.Outreach_Notification_Survey_Catchup_Reminder;
                }else{
                    onhForSession.Notes__c = Label.Outreach_Notification_L2_Flagged + ' - ' + Label.Outreach_Notification_Survey_Reminder;
                }
            }else{
                onhForSession.Outreach_Notification_Setting__c = outreachNotificationSetting.Id;
                onhForSession.Schedule__c =  dtSchedule;
            }
            //Survey responses
            if(sObj.getSObjectType().getDescribe().getName() ==  Survey_Response__c.SObjectType.getDescribe().getName()){
                Survey_Response__c sr = (Survey_Response__c)sObj;
                onhForSession.Contact__c = sr.Contact__c;
                onhForSession.Related_To__c = sr.Survey__r.Name;
                onhForSession.Related_To_Id__c = sr.Survey__r.Id;
            }else if(sObj.getSObjectType().getDescribe().getName() ==  Participant__c.SObjectType.getDescribe().getName()){
                //Event Participants
                Participant__c p = (Participant__c)sObj;
                onhForSession.Contact__c = p.Member_Contact__c;
                onhForSession.Related_To__c = p.Event__r.Name;
                onhForSession.Related_To_Id__c = p.Event__c;
            }else if(sObj.getSObjectType().getDescribe().getName() ==  Survey_Participant__c.SObjectType.getDescribe().getName()){
                //Event Participants
                Survey_Participant__c sp = (Survey_Participant__c)sObj;
                onhForSession.Contact__c = sp.Participant__c;
                onhForSession.Related_To__c = sp.Survey__r.Name;
                onhForSession.Related_To_Id__c = sp.Survey__c;
            }
            lstOutreachNotificationHistories.add(onhForSession);
        }
        System.debug(LoggingLevel.DEBUG, ' !@# lstOutreachNotificationHistories:' + lstOutreachNotificationHistories.size());
        System.debug(LoggingLevel.DEBUG, ' !@# --------------------------------------------');
        return lstOutreachNotificationHistories;
    }



    /* ***************************************************************************** */
    public static Boolean checkIfTodayIsDueForNotification(Datetime dtSurveyDate, Integer iDays, String strType){

        System.debug(LoggingLevel.DEBUG, ' !@# --------------------------------------------');
        System.debug(LoggingLevel.DEBUG, ' !@# ' + strType);
        Boolean bReturn = false;
        System.debug(LoggingLevel.DEBUG, ' !@# Outreach Notification Setting Days :  ' +iDays);
        if(strType == Label.Outreach_Notification_Survey_Catchup){
            System.debug(LoggingLevel.DEBUG, ' !@# Days after Survey Catchup StartDate: ' + dtSurveyDate.date().daysBetween(System.now().date()));
            if(dtSurveyDate.date().daysBetween(System.now().date()) == iDays){
                bReturn = true;
            }
        }else if(strType == Label.Outreach_Notification_Survey_Reminder || strType == Label.Outreach_Notification_Survey_Catchup_Reminder){
            String strDate = (strType == Label.Outreach_Notification_Survey_Reminder) ? 'Survey EndDate' : 'Survey Catchup EndDate';
            System.debug(LoggingLevel.DEBUG, ' !@# Days prior to ' + strDate + ' : ' + System.now().date().daysBetween(dtSurveyDate.date()));
            if(System.now().date().daysBetween(dtSurveyDate.date()) == iDays){
                bReturn = true;
            }
        }else if(strType == Label.Outreach_Notification_Survey_Thank_you){
            System.debug(LoggingLevel.DEBUG, ' !@# Days after Survey Response CreatedDate: ' + dtSurveyDate.date().daysBetween(System.now().date()));
            if(dtSurveyDate.date().daysBetween(System.now().date()) == iDays){
                bReturn = true;
            }
        }
        return bReturn;
    }


    /* ***************************************************************************** */
    public static Map<Id, List<Participant__c>> getEventParticipants(Set<Id> setSurveyIds){
        Map<Id, List<Participant__c>> mapParticipantsByEventId = new Map<Id, List<Participant__c>>();
        Set<Id> setEventId = new Set<Id>();

        for(Survey__c survey : [SELECT Id, Event__c FROM Survey__c WHERE Id IN: setSurveyIds LIMIT : Limits.getLimitQueryRows()]){
            setEventId.add(survey.Event__c);
        }

        for(Event__c evt : [SELECT Id, Event_Id__c, Name, Outreach_Notification__c, Start_Date_Time__c, Time_Zone__c,
                                (SELECT Id, Member_Contact__c, Member_Contact__r.Name, Default_Member_Name__c, Event__c, Event__r.Name FROM Participants__r)
                                FROM Event__c WHERE Id IN: setEventId LIMIT : Limits.getLimitQueryRows()]){
            mapParticipantsByEventId.put(evt.Id, new List<Participant__c>(evt.Participants__r));
        }

        return mapParticipantsByEventId;
    }

    /* ***************************************************************************** */
    public static Map<Id, Survey__c> getSurveys(){
        System.debug(LoggingLevel.DEBUG, ' !@# Retrieve Surveys');
        Map<Id, Survey__c> mapSurveyById = new Map<Id, Survey__c>();

        for(Survey__c survey : [SELECT Id, Name, Journey_Milestone_Start_Date__c, Outreach_Notification__c, Journey_Milestone_End_Date__c,
                                    Event__c, Active__c, Catchup__c, Catchup_Start_Date__c, Catchup_End_Date__c,
                                 (SELECT Id,  Contact__c, CreatedDate, Survey__r.Name, Survey__c FROM Survey_Responses__r),
                                (SELECT Id, Survey__c, Survey__r.Name, Participant__c, CreatedDate FROM Survey_Participants__r)
                                    FROM Survey__c WHERE Outreach_Notification__c != NULL
                                     AND Active__c = TRUE LIMIT 2000]){
            mapSurveyById.put(survey.Id, survey);
        }

        return mapSurveyById;
    }

}