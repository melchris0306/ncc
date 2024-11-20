/*******************************************************************************************
* @author: Jasmine Nguyen
* @created: 05-09-2020
* @description: Generates the wrapper that will be displayed in the table for Confirmation Emails
*
* Changes (version)
* -------------------------------------------------------------------------------------------
*             No.   Date(dd-mm-yyy)   Author                Description
*             ----  ---------------   --------------------  ---------------------------------
* @version    1.0   05-09-2020        Jasmine Nguyen        Initial Creation
*			  2.0	??-??-????		  Angelo Rivera			Updated object references
*			  3.0   26-08-2021        Paolo Quiambao        added Confirm/Decline response link and Status in sessionWrapper, added DateTime conversion
* 			  4.0	30-04-2022		  Paolo Quiambao		[CCN-1216] Enhance logic to accept multiple Session Participant Ids
*			  5.0	12-06-2022		  Paolo Quiambao		[CCN-1216] Added filter to consider only Registered, Confirmed, Declined, and Cancelled status
*             6.0   17-06-2022        Von Pernicia          [CCN-EVE-1773-DV] - Updated status value from Cancelled to Canceled
*********************************************************************************************/

public with sharing class EventConfirmationHelper {

    @testVisible
    public static Boolean throwFakeException = false;
    
    // Get sessions details
    public static EventConfirmationWrapper getSessionsDetails(String campaignMemberId) {
        String idStringForUrl = ''; // Updated by PaoloQuiambao [ccneve1216dv] April302022
        //String domainName = [SELECT Id, Domain_Name_Event_Registration__c FROM Compass_Setting__c WHERE Name = 'Default Settings' LIMIT 1].Domain_Name_Event_Registration__c; - Commented out since Domain Name Event Registration is not yet in UAT onwards
        String domainName = [SELECT Id, Domain_Name__c FROM Compass_Setting__c WHERE Name = 'Default Settings' LIMIT 1].Domain_Name__c;
        EventConfirmationWrapper eventConfirmationWrapper = new EventConfirmationWrapper(); // Updated by PaoloQuiambao [ccneve1216dv] April302022
        Set<String> statusToConsider = new Set<String>{'Registered', 'Confirmed', 'Declined', 'Canceled'}; // CCN-EVE-1773-DV // Updated by PaoloQuiambao [ccneve1216dv] June122022
        List<SessionWrapper> sessionsWrappers = new List<SessionWrapper>();
        List<Participant__c> campaignMembers = new List<Participant__c>(); 
        List<Id> sessionParticipantIds = new List<Id>(); // Added by Paolo Quiambao [CCN-EVE-1216-DV] April292022
        Map<Id, Participant__c> mapCampaignMembers; // Added by DinoBrinas [CCN-EVE-1191-QA-BUG-2] April072022
        if(FlsUtils.isAccessible('Participant__c', new List<String>{'Event__c','Member_Contact__c'})&&FlsUtils.isAccessible('Contact', new List<String>{'AccountId'})
           &&FlsUtils.isAccessible('Event__c', new List<String>{'OwnerId','Contact_Us_User__c','Location__c','Time_Zone__c'})){
            campaignMembers = [SELECT Id, Event__c, Member_Contact__c, Member_Contact__r.AccountId, Event__r.OwnerId,
                                Event__r.Contact_Us_User__c, Event__r.Location__c, Event__r.Time_Zone__c
                                FROM Participant__c WHERE Id =: campaignMemberId LIMIT 1];
            mapCampaignMembers = new Map<Id, Participant__c>(campaignMembers); // Added by DinoBrinas [CCN-EVE-1191-QA-BUG-2] April072022
        }

        if (mapCampaignMembers <> null && mapCampaignMembers.size() > 0){ // Updated by DinoBrinas [CCN-EVE-1191-QA-BUG-2] April072022
            String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;
            if(FlsUtils.isAccessible('Session_Participant__c', new List<String>{'Name','Event__c','Contact__c'})&&
               FlsUtils.isAccessible('Session__c', new List<String>{'Start_Date_Time__c','End_Date_Time__c','Time_Zone__c','Name'})){
                   for (Session_Participant__c s : [SELECT Id, Name,Event__c, Contact__c, Session__r.Start_Date_Time__c, Session__r.End_Date_Time__c,
                                                    Event__r.Location__r.Name, Session__r.Time_Zone__c, Session__r.Name, Session__r.Location__c, Confirm_Response_Link__c, 
                                                    Decline_Response_Link__c, Status__c
                                                    FROM Session_Participant__c
                                                    WHERE Contact__c =: mapCampaignMembers.get(campaignMemberId).Member_Contact__c
                                                    AND Status__c IN :statusToConsider // Updated by PaoloQuiambao [ccneve1216dv] June122022
                                                    AND Event__c =: mapCampaignMembers.get(campaignMemberId).Event__c]){ // Updated by DinoBrinas [CCN-EVE-1191-QA-BUG-2] April072022
                                                        // if (s != null && convertDateTimeToOtherTimeZone(convertDateTimeToOtherTimeZone(s.Session__r.Start_Date_Time__c, 'UTC', strTZone), s.Session__r.Time_Zone__c, 'UTC') > System.now()){
                                                        // UPDATED by JC ESPINO [CCN-EVE-1191-QA-BUG-2] - DateTime is saved in UTC, no need to convert. System.now() is in UTC as well.
                                                        // UPDATED by JC ESPINO [CCN-EVE-1360-DV] - Updated location info to the Session Location field if present
                                                        if(s != null && (s.Session__r.Start_Date_Time__c > System.now())) {
                                                            SessionWrapper sw = new SessionWrapper();
                                                            sw.Name = s.Session__r.Name;
                                                            sw.SessionDate = s.Session__r.Start_Date_Time__c.format('MMMM dd, yyyy', strTZone);
                                                            sw.SessionTime = s.Session__r.Start_Date_Time__c.format('h:mm a', strTZone) + ' to '; 
                                                            sw.SessionTime2 = s.Session__r.End_Date_Time__c.format('h:mm a', strTZone) + ' ' + s.Session__r.Time_Zone__c;
                                                            sw.SessionLocation = s.Session__r.Location__c != null ? s.Session__r.Location__c : s.Event__r.Location__r.Name;
                                                            sw.confirmResponseLink = s.Confirm_Response_Link__c;
                                                            sw.declineResponseLink = s.Decline_Response_Link__c;
                                                            sw.status = s.Status__c;
                                                            sessionsWrappers.add(sw);
                                                            
                                                            // Updated by PaoloQuiambao [ccneve1216dv] April302022
                                                            if(s.Status__c == 'Registered') {
                                                                sessionParticipantIds.add(s.Id);   
                                                            }
                                                        }
                                                    }
                   
                   // Updated by PaoloQuiambao [ccneve1216dv] April302022
                   for(Id spId : sessionParticipantIds) {
                       idStringForUrl += String.valueOf(spId) + '+';
                   }
                   
                   eventConfirmationWrapper.showConfirmDeclineAllButton = sessionParticipantIds.size() > 1 ? true : false; // Updated by PaoloQuiambao [ccneve1216dv] April302022
                   eventConfirmationWrapper.confirmAllLink = domainName + '/?id=' + idStringForUrl.removeEnd('+') + '&response=Confirmed'; // Updated by PaoloQuiambao [ccneve1216dv] April302022
                   eventConfirmationWrapper.declineAllLink = domainName + '/?id=' + idStringForUrl.removeEnd('+') + '&response=Declined'; // Updated by PaoloQuiambao [ccneve1216dv] April302022
                   eventConfirmationWrapper.sessionList = sessionsWrappers; // Updated by PaoloQuiambao [ccneve1216dv] April302022
               }
        }

        return eventConfirmationWrapper; // Updated by PaoloQuiambao [ccneve1216dv] April302022
    }
    
    // Updated by PaoloQuiambao [ccneve1216dv] April302022
    public class EventConfirmationWrapper {
        public Boolean showConfirmDeclineAllButton {get;set;}
        public String confirmAllLink {get;set;}
        public String declineAllLink {get;set;}
        public List<SessionWrapper> sessionList {get;set;}
    }
    
    public class SessionWrapper{
        public String Name {get; set;}
        public String SessionDate {get; set;}
        public String SessionTime {get; set;}
        public String SessionTime2 {get;set;}
        public String SessionLocation {get; set;}
        public String confirmResponseLink {get;set;}
        public String declineResponseLink {get;set;}
        public String status {get;set;}
    }
    
    // Get formatted date time
    public static String getFormattedDateTimeHelper(String campaignOwnerId, String campaignId, String startOrEndDate, String defined_format, String timeOrDate){
        String FormattedDatetime;
        if (campaignOwnerId == null || campaignId == null || startOrEndDate == null){
            return '';
        } else {
            String queryString = (startOrEndDate.toLowerCase() == 'start') ? 'SELECT Start_Date_Time__c, End_Date_Time__c, OwnerId, Contact_Us_User__c, Time_Zone__c FROM Event__c WHERE Id =: campaignId LIMIT 1'
                : 'SELECT Start_Date_Time__c, End_Date_Time__c, OwnerId, Contact_Us_User__c, Time_Zone__c FROM Event__c WHERE Id =: campaignId LIMIT 1';
            List<sObject> sobjList = Database.query(queryString);
            if (sobjList.size() > 0){
                Event__c campaign = (Event__c)sobjList[0];
                if (campaign != null ){
                    String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;
                    if (campaign != null && throwFakeException == false){
                        DateTime localDateTime;
                        if (startOrEndDate.toLowerCase() == 'start' && campaign.Start_Date_Time__c != null){
                            localDateTime = campaign.Start_Date_Time__c;
                        } 
                        if (startOrEndDate.toLowerCase() == 'end' && campaign.End_Date_Time__c != null ){
                            localDateTime = campaign.End_Date_Time__c; 
                        }
                        if (localDateTime != null) {
                            if(timeOrdate.toLowerCase() == 'date' || (startOrEndDate.toLowerCase() == 'start' && timeOrdate.toLowerCase() != 'date')) {
                                FormattedDatetime = localDateTime.format(defined_format, strTZone);
                            }
                            else {
                                FormattedDatetime = localDateTime.format(defined_format, strTZone) + ' ' + campaign.Time_Zone__c;
                            }
                        }
                            
                        return FormattedDatetime;
                    }
                }  
            }
          
            return '';
            
        }
    }
    
    // UPDATED by JC ESPINO [CCN-EVE-1191-QA-BUG-2] - DateTime is saved in UTC, no need to convert. System.now() is in UTC as well.
    // public static DateTIme convertDateTimeToOtherTimeZone(DateTime dTime, String sourceTimeZone, String targetTimeZone) {
    //     TimeZone sourceTZ = Timezone.getTimeZone(sourceTimeZone);
    //     Integer offset = sourceTZ.getOffset(dTime);
        
    //     TimeZone targetTZ = Timezone.getTimeZone(targetTimeZone);
    //     Integer offsetTotargetTZ = targetTZ.getOffset(dTime);
    //     Integer correction = offsetTotargetTZ - offset;
        
    //     return dTime.addMinutes(correction / (1000 * 60));
    // }

}