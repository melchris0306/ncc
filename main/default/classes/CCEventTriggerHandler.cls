/*******************************************************************************************
 * @name: CCEventTriggerHandler
 * @author: 
 * @created: XX-XX-XXXX
 * @description: Handler for all the logic of the trigger for the Event object
 *
 * Changes (version)
 * -------------------------------------------------------------------------------------------
 *             No.   Date(dd-mm-yyy)   Author                Description
 *             ----  ---------------   --------------------  ---------------------------------
 * @version    1.0   XX-XX-XXXX                              Initial Creation
 *             2.0   23-03-2022		   Paolo Quiambao		 [CCN934] Utilize Domain Name from Compass Setting to set Event Page URL
 *             3.0   25-11-2022        Xen Reyes             [CCN-LOG-2217-DV] Internal logistics, after update
 *             4.0   14-06-2023        Rexie Aaron David     [CCN-2534] [CCN-EVE-3056-DV] Virtual Meeting Integration 
 *********************************************************************************************/
public with sharing class CCEventTriggerHandler {
	
    public static String siteId;
    public static String compURL;
    
    //CCN-2442 : Commented by Gabriel Delavin to fix issue on URL generation 01-06-2023
    /*public Compass_Setting__c compassSetting = [SELECT Id, Domain_Name__c FROM Compass_Setting__c WHERE Name = 'Default Settings'
        LIMIT 1
    ];
	*/
    //End
    
    /*public static JourneyCommunitySettings__c JourneyCommunitySettings {
      get {
        if (JourneyCommunitySettings == null)
          JourneyCommunitySettings = JourneyCommunitySettings__c.getOrgDefaults();
        return JourneyCommunitySettings;
      }
      set;
    }*/
	//Start CCN-2442: Added by Gabriel Delavin to fix issue on URL generation 01-06-2023
    public static string getCompassSiteURL (){
        
        //CCN-EVE-3324-DV Xen Reyes July 25 2023
        if(siteId == null) siteId = [Select Id from Site where Name = 'Compass'].Id;
        if(compURL == null) compURL = [Select SecureURL from SiteDetail where DurableId =: siteId].SecureURL;
        
        return compURL;
    }
    //End CCN-2442: Added by Gabriel Delavin to fix issue on URL generation 01-06-2023
    public void OnBeforeInsert(List < Event__c > eventList) {
        //Start CCN-EVE-3056-DV: Added by adavid@ulapp.co to be able to show different field on Event Creation and Event Edit Page Layout
        Id createNewEventRecTypeId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Create New Event').getRecordTypeId();
        Id eventRecTypeId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Event').getRecordTypeId();
        //End CCN-EVE-3056-DV: Added by adavid@ulapp.co to be able to show different field on Event Creation and Event Edit Page Layout
        for (Event__c eventRec: eventList) {
            generateTokenAndURL(eventRec);
            //CCN-EVE-3056-DV Added by adavid@ulapp.co 
            if(eventRec.RecordTypeId == createNewEventRecTypeId) eventRec.RecordTypeId = eventRecTypeId; 
            
        }

        CCEventTriggerUtility.generateOrdWideEmail(eventList);
		setDefaultRegistrationFields(eventList);
        populateEventDetails(eventList);

        //CCN-EVE-3324-DV Xen Reyes July 25 2023
        setSiteValues(eventList);
    }

    public void OnBeforeUpdate(Map < Id, Event__c > newEvents, Map < Id, Event__c > oldEvents) {
        CCEventTriggerUtility.generateOrdWideEmail(newEvents.values());

        for (Event__c newEvent: newEvents.values()) {
            if (
                (newEvent.Re_Generate_URL__c == true) &&
                (newEvent.Re_Generate_URL__c !=
                    oldEvents.get(newEvent.Id).Re_Generate_URL__c)
            ) {
                generateTokenAndURL(newEvent);
            }
        }

        populateEventDetails(newEvents.values());
    }

    public void OnAfterInsert(List < Event__c > eventList) {

        //[CCN-LOG-2217-DV] Xen Reyes 25Nov2022
        List < Event__c > eventToEvaluateLogistics = new List < Event__c > ();
        for (Event__c newEvent: eventList) {
            if (newEvent.Internal_Logistics_Required__c) {
                eventToEvaluateLogistics.add(newEvent);
            }
        }
        if (!eventToEvaluateLogistics.isEmpty()) CCEventTriggerUtility.eventInternalLogistics(eventToEvaluateLogistics, true);
    }

    public void OnAfterUpdate(Map < Id, Event__c > newEvents, Map < Id, Event__c > oldEvents) {

        //[CCN-LOG-2217-DV] Xen Reyes 25Nov2022
        List < Event__c > eventToEvaluateLogistics = new List < Event__c > ();
        List <Event__c> eventToProcessVirtualMeetingList = new List <Event__c> ();
        for (Event__c newEvent: newEvents.values()) {
            if (newEvent.Internal_Logistics_Required__c && !oldEvents.get(newEvent.Id).Internal_Logistics_Required__c) {
                eventToEvaluateLogistics.add(newEvent);
            }
            if (newEvent.ChangeEventTypeAction__c != oldEvents.get(newEvent.Id).ChangeEventTypeAction__c &&
            newEvent.ChangeEventTypeAction__c != 'VirtualToInPerson-DoNotRemoveVirtualPlatformInfo' && 
            newEvent.ChangeEventTypeAction__c != 'InPersonToVirtual-DoNotAddVirtualPlatformInfo'){
                eventToProcessVirtualMeetingList.add(newEvent);
            }
        }
        if (!eventToEvaluateLogistics.isEmpty()) CCEventTriggerUtility.eventInternalLogistics(eventToEvaluateLogistics, false); //Rex David adavid@ulapp.co CCN-EVE-3056-DV
        //XEN REYES CCN-SUR-3235-DV 14 July 2023
        updateSurveySiteValues(newEvents, oldEvents);

        //Rex David adavid@ulapp.co CCN-EVE-3056-DV
        if(eventToProcessVirtualMeetingList.size() > 0){
            processVirtualMeeting(eventToProcessVirtualMeetingList);
        }
    }

    public void generateTokenAndURL(Event__c eventRec) {
        String token = getToken();
        eventRec.Event_Id__c = token;
        // Updated by Paolo Quiambao [CCN-934] Mar232021
       	//Start CCN-2442: Added by Gabriel Delavin to fix issue on URL generation 01-06-2023
        eventRec.Event_Page_URL__c = getCompassSiteURL() + '/s/events?id=' + token;
        //End CCN-2442: Added by Gabriel Delavin to fix issue on URL generation 01-06-2023
        eventRec.Re_Generate_URL__c = false;
    }

    public String getToken() {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';

        String token = '';
        while (token.length() <= 10) {
            Integer idx = Math.mod(
                Math.abs(Crypto.getRandomInteger()),
                chars.length()
            );
            token += chars.substring(idx, idx + 1);
        }

        return token;
    }

    /*public String getCommunityURL(string communityName) {
      if (!Test.isRunningTest()) {
        Network myNetwork = [SELECT Id FROM Network WHERE Name = :communityName];
        ConnectApi.Community myCommunity = ConnectApi.Communities.getCommunity(
          myNetwork.id
        );
        return myCommunity.siteUrl;
      } else {
        return 'some random url';
      }
    }*/

    public static void populateEventDetails(List < Event__c > newList) {
        String strTZone = String.valueOf(UserInfo.getTimeZone());

        for (Event__c evt: newList) {
            String eventName = '';
            String eventTimeDetails = '';
            if (evt.Start_Date_Time__c != null && evt.End_Date_Time__c != null) {
                Datetime startDT = evt.Start_Date_Time__c;
                Datetime endDT = evt.End_Date_Time__c;
                eventName = startDT.format('EEEE, MMMM dd') + ' to ' + endDt.format('EEEE, MMMM dd, yyyy');
                eventTimeDetails = startDT.format('h:mm aaa', strTZone) + ' - ' + endDT.format('h:mm aaa', strTZone) + ' ' + evt.Time_Zone__c;
            }
            evt.Event_Details__c = eventName;
            evt.Event_Time_Details__c = eventTimeDetails;
        }
    }

    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  14-06-2023   Rex David            [CCN-EVE-3056-DV] Virtual Meeting Integration (POC: Microsoft Teams Link)
    ******************************************************************************/
    public static void processVirtualMeeting(List<Event__c> newList){

        List<Session__c> sessionsVMLList = new List<Session__c>();
        Set<String> allowedActions = new Set<String>{'InPersonToVirtual-AddVirtualPlatformInfo','InPersonToVirtual-RunIntegration','VirtualToInPerson-RemoveVirtualPlatformInfo'};
        Map<String,Set<String>> eventIdToProcessMap = new Map<String,Set<String>>();
        Map<Id,Event__c> eventMap = new Map<Id,Event__c>();
        Set<Id> validEventIds = new Set<Id>();

        for(Event__c event : newList){
            if(event.ChangeEventTypeAction__c != NULL && event.ChangeEventTypeAction__c != 'VirtualToInPerson-DoNotRemoveVirtualPlatformInfo' && event.ChangeEventTypeAction__c != 'InPersonToVirtual-DoNotAddVirtualPlatformInfo'){
                validEventIds.add(event.Id);
                if(eventIdToProcessMap.containsKey(event.ChangeEventTypeAction__c)){
                    Set<String> eventIdSet = eventIdToProcessMap.get(event.ChangeEventTypeAction__c); 
                    eventIdSet.add(event.Id);
                    eventIdToProcessMap.put(event.ChangeEventTypeAction__c,eventIdSet);     
                }
                else{
                    eventIdToProcessMap.put(event.ChangeEventTypeAction__c,new Set<String> {event.Id});   
                }
            }
        }

        if(validEventIds.size() > 0){
            eventMap = new Map<Id,Event__c> ([SELECT Id, (SELECT Id, Meeting_Info__c, Meeting_URL__c FROM CC_Sessions__r) FROM Event__c WHERE Id IN: validEventIds]);
        }

        List<Session__c> sessionRemovePlatformInfoList = new List<Session__c>();

        if(!eventIdToProcessMap.isEmpty() && !eventMap.isEmpty()){
            for(String eventKey : eventIdToProcessMap.keySet()){
                if(eventKey == 'VirtualToInPerson-RemoveVirtualPlatformInfo'){
                    for(String eventId : eventIdToProcessMap.get(eventKey)){
                        if(eventMap.containsKey(eventId)) sessionRemovePlatformInfoList.addAll(eventMap.get(eventId).CC_Sessions__r);
                    }
                }
                if(eventKey == 'InPersonToVirtual-AddVirtualPlatformInfo' || eventKey == 'InPersonToVirtual-RunIntegration'){
                    for(String eventId : eventIdToProcessMap.get(eventKey)){
                        if(eventMap.containsKey(eventId)) sessionsVMLList.addAll(eventMap.get(eventId).CC_Sessions__r);
                    }
                }
            }
            if(sessionRemovePlatformInfoList.size() > 0) {
                List<Session__c> sessionToUpdate = new List<Session__c>();
                sessionToUpdate = ChangeEventTypeController.removeMSMeetingInfo(sessionRemovePlatformInfoList);
                if(sessionToUpdate.size() > 0){
                    update sessionToUpdate;
                } 
            }
            if(sessionsVMLList.size() > 0) Database.executeBatch(new AzureAPIBatch('POST',sessionsVMLList),30);
        }
    }

    //CCN-EVE-3324-DV Xen Reyes July 25 2023
    public static void setSiteValues(List<Event__c> newList) {

        Set<Id> campaignToGet = new Set<Id>();
        for (Event__c event : newList){
            if(String.isNotBlank(event.Campaign__c)) campaignToGet.add(event.Campaign__c);
        }

        Map<Id, Campaign__c> campaignMap = new Map<Id, Campaign__c>([SELECT Id, Site_Picklist_Values__c FROM Campaign__c WHERE Id IN: campaignToGet]);

        for (Event__c event : newList){
            if(String.isNotBlank(event.Campaign__c)){
                event.Site_Picklist_Values__c = campaignMap.containsKey(event.Campaign__c) ? campaignMap.get(event.Campaign__c).Site_Picklist_Values__c : null;
            }
        }
    }

    //XEN REYES CCN-SUR-3235-DV 14 July 2023
    public static void updateSurveySiteValues(Map<Id, Event__c> newEvents, Map<Id, Event__c> oldEvents) {
        
        try{
            Set<Id> eventWithUpdatedSite = new Set<Id>();
            for(Event__c ev : newEvents.values()){
                if(ev.Site_Picklist_Values__c != oldEvents.get(ev.Id).Site_Picklist_Values__c){
                    eventWithUpdatedSite.add(ev.Id);
                }
            }

            List<Survey__c> surveyToUpdate = new List<Survey__c>();
            for(Survey__c sur : [SELECT Id, Event__c, Site_Picklist_Values__c FROM Survey__c WHERE Event__c IN: eventWithUpdatedSite]){
                sur.Site_Picklist_Values__c = newEvents.get(sur.Event__c).Site_Picklist_Values__c;
                surveyToUpdate.add(sur);
            }

            update surveyToUpdate;
            
        } catch(Exception e){
            System.debug(e);
        }
        
    }
	//Gabriel Delavin - Set default values of Registration field when Event is created
    public static void setDefaultRegistrationFields(List<Event__c> newList) {
        for(Event__c eventRec: newList){
            if(eventRec.Registration_Fields_JSON__c == null){
              eventRec.Registration_Fields_JSON__c = '{"RegistrationField_Title-Contact|Title":{"required":false,"active":false},"RegistrationField_TitleRank-Contact|Title":{"required":false,"active":false},"RegistrationField_FirstName-Contact|FirstName":{"required":true,"active":true},"RegistrationField_LastName-Contact|LastName":{"required":true,"active":true},"RegistrationField_Email-Contact|Email":{"required":true,"active":true},"RegistrationField_Department-Contact|Department":{"required":false,"active":false},"RegistrationField_Site-Contact|Site__c":{"required":false,"active":false}}';  
            }
        }
    }
}