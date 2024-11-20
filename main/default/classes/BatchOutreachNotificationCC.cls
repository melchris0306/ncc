/*******************************************************************************
 * @author       Angelo Rivera
 * @date         18.08.2021
 * @description  [CCN-842, CCN-1059, CCN-1060, CCN-1061] Controller class for BatchOutreachNotification
 * @revision     18.08.2021 - APRivera - Created
 *******************************************************************************/
public without sharing class BatchOutreachNotificationCC {

    public static void sendOutreachNotifications(List<String> lstSObject){
        Boolean bEvents = false, bJourney = false, bSession = false, bSurvey = false;
        for(String strObject : lstSObject){
            // Event
            if(strObject == Event__c.SObjectType.getDescribe().getName()){
                bEvents = true;
            	System.debug(LoggingLevel.DEBUG, ' !@# EVENTS ' + bEvents);
            }
            // Session
            if(strObject == Session__c.SObjectType.getDescribe().getName()){
                bSession = true;
            	System.debug(LoggingLevel.DEBUG, ' !@# SESSION ' + bSession);
            }
            // Journey
            if(strObject == Journey__c.SObjectType.getDescribe().getName()){
                bJourney = true;
            	System.debug(LoggingLevel.DEBUG, ' !@# JOURNEY ' + bJourney);
            }
            // Survey
            if(strObject == Survey__c.SObjectType.getDescribe().getName()){
                bSurvey = true;
            	System.debug(LoggingLevel.DEBUG, ' !@# SURVEY ' + bSurvey);
            }
        }

        // Events
        if(bEvents){
            String strEventOutreachNotifications = '';
            strEventOutreachNotifications = OutreachNotificationHelper.processEvents();
            System.debug(LoggingLevel.DEBUG, ' !@# ' + strEventOutreachNotifications);
        }

        // Session
        if(bSession){
            String strSessionOutreachNotifications = '';
            strSessionOutreachNotifications = OutreachNotificationSessionHelper.processSessions();
            System.debug(LoggingLevel.DEBUG, ' !@# ' + strSessionOutreachNotifications);
        }


        // Survey
        if(bSurvey){
            String strSurveyOutreachNotifications = '';
            strSurveyOutreachNotifications = OutreachNotificationSurveyHelper.processSurveys();
            System.debug(LoggingLevel.DEBUG, ' !@# ' + strSurveyOutreachNotifications);
        }


    }



}